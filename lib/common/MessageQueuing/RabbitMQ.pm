#    Copyright © 2013 Hedera Technology SAS
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

=pod

=begin classdoc

Base class to mannage connection to a RabbitMQ broker.

@since    2013-Avr-19
@instance hash
@self     $self

=end classdoc

=cut

package MessageQueuing::RabbitMQ;

use strict;
use warnings;

use General;

use Net::RabbitMQ;
use JSON;

use Data::Dumper;
use Log::Log4perl "get_logger";
my $log = get_logger("");


# The connection singleton
my $connection;

# Keep the channel as singleton for each entities of a same process.
my $channels = {};


=pod
=begin classdoc

@constructor

Usefull to use the lib stand alone, without inheritance.

=end classdoc
=cut

sub new {
    my ($class, %args) = @_;

    my $self = {};
    bless $self, $class;
}


=pod
=begin classdoc

Connect to the message queuing server.

@param ip the message queuing server ip
@param port the message queuing server port

=end classdoc
=cut

sub connect {
    my ($self, %args) = @_;
    my $class = ref($self) || $self;

    General::checkParams(args     => \%args,
                         optional => { 'ip'       => '127.0.0.1',
                                       'port'     => 5672,
                                       'user'     => 'guest',
                                       'password' => 'guest' });

    if (! (defined $self->_connection)) {
        eval {
            $log->debug("Connecting <$self> to broker <$args{ip}:$args{port}> as <$args{user}>");
            $connection = Net::RabbitMQ->new();
            $self->_connection->connect($args{ip}, {
                user      => $args{user},
                password  => $args{password},
                port      => $args{port},
                vhost     => '/',
                heartbeat => 0
            });
        };
        if ($@) {
            my $err = $@;
            throw Kanopya::Exception::MessageQueuing::ConnectionFailed(error => $err);
        }
        $log->debug("Connected <$self> to broker.");
    }

    if (! (defined $self->_channel)) {
        my $channel_number = scalar(keys %{ $channels }) + 1;
        $log->debug("Openning channel for <$self>, number <$channel_number>");

        eval {
            $self->_connection->channel_open($channel_number);
        };
        if ($@) {
            my $err = $@;
            $log->debug("Open channel failed, raise exception ChannelError: $err");
            throw Kanopya::Exception::MessageQueuing::ChannelError(error => $err);
        }
        $channels->{$class} = $channel_number;

        $log->debug("Channel open <" . $self->_channel . "> for <$self>, number <$channel_number>");
    }

    $self->{_config} = \%args;
}


=pod
=begin classdoc

Disconnect from the message queuing server.

=end classdoc
=cut

sub disconnect {
    my ($self, %args) = @_;

    $channels = {};

    if (defined $self->_connection) {
        $log->debug("Disconnecting <$self> from broker");
        eval {
            my $res = $self->_connection->disconnect();
            $log->debug("Disconnected <$self> from broker");
        };
        if ($@) {
            $log->warn("Unable to disconnect <$self> from the broker: $@");
        }
        $connection = undef;
    }
}


=pod
=begin classdoc

Return the connection status.

=end classdoc
=cut

sub connected {
    my ($self, %args) = @_;

    return ((defined $self->_connection) && (defined $self->_channel));
}


=pod
=begin classdoc

Declare a queue identified by the channel name.

=end classdoc
=cut

sub declareQueue {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'channel' ],
                         optional => { 'exclusive' => 0 });

    my $name = ($args{exclusive} == 0) ? $args{channel} : '';

    $log->debug("Declaring queue <$args{channel}>");
    my $queue;
    eval {
        $queue = $self->_connection->queue_declare($self->_channel, $name, {
                     passive     => 0,
                     durable     => 1,
                     exclusive   => $args{exclusive},
                     auto_delete => 0
                 });
    };
    if ($@) {
        my $err = $@;
        throw Kanopya::Exception::MessageQueuing::ChannelError(error => $err);
    }
    return $queue;
}


=pod
=begin classdoc

Declare a queue identified by the channel name.

=end classdoc
=cut

sub declareExchange {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'channel' ]);

    $log->debug("Declaring exchange <$args{channel}> of type <fanout>");
    my $exchange;
    eval {
        $exchange = $self->_connection->exchange_declare($self->_channel, $args{channel}, {
                        exchange_type => "fanout",
                        passive       => 0,
                        durable       => 1,
                        auto_delete   => 0
                    });
    };
    if ($@) {
        my $err = $@;
        throw Kanopya::Exception::MessageQueuing::ChannelError(error => $err);
    }
    return $exchange;
}


=pod
=begin classdoc

Register the callbck method for a specific channel and type.

@param queue the queue on which register the callback
@param callback the callback method

=end classdoc
=cut

sub consume {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'queue' ]);

    # Register the method to call back at message consumption
    $log->debug("Registering (consume) callback on queue <$args{queue}>");
    my $tag = $self->_connection->consume($self->_channel, $args{queue}, { no_ack => 0 });

    $log->debug("Registered (consume) callback <$tag>");
    return $tag;
}


=pod
=begin classdoc

Blokcing call that wait for messages.

=end classdoc
=cut

sub recv {
    my ($self, %args) = @_;

    my $msg;
    eval {
        $msg = $self->_connection->recv();
    };
    if ($@) {
        my $err = $@;
        throw Kanopya::Exception::MessageQueuing::ChannelError(error => $err);
    }
    return $msg;
}


=pod
=begin classdoc

Acknowledge a message secified by tag.

@param tag the delivery tag of the essage to ack

=end classdoc
=cut

sub acknowledge {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'tag' ]);

    $log->debug("Acknowledging message with tag <$args{tag}>");
    $self->_connection->ack($self->_channel, $args{tag});
}


=pod
=begin classdoc

Return the session private attribute.

=end classdoc
=cut

sub _channel {
    my ($self, %args) = @_;
    my $class = ref($self) || $self;

    return $channels->{$class};
}


=pod
=begin classdoc

Return the connection private attribute.

=end classdoc
=cut

sub _connection {
    my ($self, %args) = @_;

    return $connection;
}

1;
