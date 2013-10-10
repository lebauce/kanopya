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

package MessageQueuing::RabbitFoot;

use strict;
use warnings;

use General;

use Net::RabbitFoot;
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

    if (! (defined $self->_connection && $self->_connection->{_ar}->{_is_open})) {
        eval {
            $log->debug("Connecting <$self> to broker <$args{ip}:$args{port}> as <$args{user}>");
            $connection = Net::RabbitFoot->new()->load_xml_spec()->connect(
                              host      => $args{ip},
                              port      => $args{port},
                              user      => $args{user},
                              pass      => $args{password},
                              vhost     => '/',
                              on_return => sub {
                                  my $frame = shift;
                                  $log->error("Unable to deliver: " . Dumper($frame));
                              },
                          );
        };
        if ($@) {
            my $err = $@;
            throw Kanopya::Exception::MessageQueuing::ConnectionFailed(error => $err);
        }
        $log->debug("Connected <$self> to broker.");
    }

    if (! (defined $self->_channel && $self->_channel->{arc}->{_is_open})) {
        $log->debug("Openning channel for <$self>");
        eval {
            $channels->{$class} = $self->_connection->open_channel();
        };
        if ($@) {
            my $err = $@;
            $log->debug("Open channel failed, raise exception ChannelError: $err");
            throw Kanopya::Exception::MessageQueuing::ChannelError(error => $err);
        }
        $log->debug("Channel open <" . $self->_channel . "> for <$self>");

        #$log->debug("Setting the QOS <prefetch_count => 1> on the channel");
        #$self->_channel->qos(prefetch_count => 1);
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

    $self->closeChannel();

    if (defined $self->_connection) {
        $log->debug("Disconnecting <$self> from broker");
        eval {
            my $res = $self->_connection->close();
            $log->debug("Disconnected <$self> from broker");
        };
        if ($@) {
            $log->warn("Unable to disconnect <$self> from the broker: $@");
        }
    }
}


=pod
=begin classdoc

Close the channel.

=end classdoc
=cut

sub closeChannel {
    my ($self, %args) = @_;
    my $class = ref($self) || $self;

    # If properly close the channel, the diconnect seems to not really close the connection,
    # thank to AnyEvent::RabbitMQ...
#    if (defined $self->_channel) {
#        $log->debug("Closing channel");
#        eval {
#            $self->_channel->close();
#        };
#        if ($@) {
#            $log->warn("Unbale to close the channel: $@");
#        }
#    }

    $channels->{$class} = undef;
}


=pod
=begin classdoc

Return the connection status.

=end classdoc
=cut

sub connected {
    my ($self, %args) = @_;

    return ((defined $self->_connection && $self->_connection->{_ar}->{_is_open}) &&
            (defined $self->_channel && $self->_channel->{arc}->{_is_open}));
}


=pod
=begin classdoc

Declare a queue identified by the channel name.

=end classdoc
=cut

sub declareQueue {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'channel' ]);

    $log->debug("Declaring queue <$args{channel}>");
    my $queue;
    eval {
        $queue = $self->_channel->declare_queue(queue => $args{channel}, durable => 1);
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
        $exchange = $self->_channel->declare_exchange(exchange => $args{channel}, type => 'fanout');
    };
    if ($@) {
        my $err = $@;
        throw Kanopya::Exception::MessageQueuing::ChannelError(error => $err);
    }
    return $exchange;
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
