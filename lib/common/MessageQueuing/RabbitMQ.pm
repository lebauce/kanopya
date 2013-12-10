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

use TryCatch;
my $err;

use Log::Log4perl "get_logger";
my $log = get_logger("amqp");


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

@optional ip the message queuing server ip
@optional port the message queuing server port
@optional user the user name to use at connect
@optional password the password to use at connect
@optional vhost the virtual host to use at connect

=end classdoc
=cut

sub connect {
    my ($self, %args) = @_;
    my $class = ref($self) || $self;

    General::checkParams(args     => \%args,
                         optional => { 'ip'       => '127.0.0.1',
                                       'port'     => 5672,
                                       'user'     => 'guest',
                                       'password' => 'guest',
                                       'vhost'    => '/' });

    if (! (defined $self->_connection)) {
        try {
            $log->debug("Connecting <$self> to broker <$args{ip}:$args{port}>, " .
                        "vhost <$args{vhost}> as <$args{user}>");
            $self->_connection(Net::RabbitMQ->new());
            $self->_connection->connect($args{ip}, {
                user      => $args{user},
                password  => $args{password},
                port      => $args{port},
                vhost     => $args{vhost},
                heartbeat => 0
            });
        }
        catch ($err) {
            throw Kanopya::Exception::MessageQueuing::ConnectionFailed(error => $err);
        }
        $log->debug("Connected <$self> to broker.");
    }

    if (! (defined $self->_channel)) {
        my $channel_number = scalar(keys %{ $self->{_channels} }) + 1;
        $log->debug("Openning channel for <$self>, number <$channel_number>");

        try {
            $self->_connection->channel_open($channel_number);
        }
        catch ($err) {
            $log->debug("Open channel failed, raise exception ChannelError: $err");
            throw Kanopya::Exception::MessageQueuing::ChannelError(error => $err);
        }
        $self->_channel($channel_number);

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

    $self->{_channels} = {};

    if (defined $self->_connection) {
        $log->debug("Disconnecting <$self> from broker");
        try {
            my $res = $self->_connection->disconnect();
            $log->debug("Disconnected <$self> from broker");
        }
        catch ($err) {
            $log->warn("Unable to disconnect <$self> from the broker: $@");
        }
        $self->_connection(undef);
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

Declare a queue identified by the queue name.
If empty queue name specified, declare an exclusive queue.

@optional queue the queue name to declare, if undefined, an exclusive queue
                name will be generated

=end classdoc
=cut

sub declareQueue {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         optional => { 'queue' => undef });

    if (defined $args{queue}) {
        $log->debug("Declaring queue <$args{queue}>");
    }
    else {
        $log->debug("Declaring exclusive queue");
    }

    my $queue = $args{queue} ? $args{queue} : '';
    try {
       $queue = $self->_connection->queue_declare($self->_channel, $args{queue} ? $args{queue} : '', {
                    passive     => 0,
                    durable     => 1,
                    exclusive   => ! $args{queue} ? 1 : 0,
                    auto_delete => 0
                });
    }
    catch ($err) {
        throw Kanopya::Exception::MessageQueuing::ChannelError(error => $err);
    }

    $log->debug("Queue <$queue> declared");
    return $queue;
}


=pod
=begin classdoc

Declare an exchange identified by the exchange name, of specified type.

@optional exchange the exchange name to declare
@optional type the type of the exchange to declare (fanout|topic)

=end classdoc
=cut

sub declareExchange {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'exchange', 'type' ]);

    $log->debug("Declaring exchange <$args{exchange}> of type <$args{type}>");
    my $exchange;
    try {
        $exchange = $self->_connection->exchange_declare($self->_channel, $args{exchange}, {
                        exchange_type => $args{type},
                        passive       => 0,
                        durable       => 1,
                        auto_delete   => 0
                    });
    }
    catch ($err) {
        if ("$err" !~ m/cannot redeclare exchange/) {
            throw Kanopya::Exception::MessageQueuing::ChannelError(error => $err);
        }
        else {
            $log->warn($err);
        }
    }
    return $exchange;
}


=pod
=begin classdoc

Bind the queue on the exchange.

@optional queue the queue to bind an the exchange
@optional exchange the exchange on which bind the queue

=end classdoc
=cut

sub bindQueue {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'queue', 'exchange' ]);

    $log->debug("Binding queue <$args{queue}> on exchange <$args{exchange}>");
    try {
        $self->_connection->queue_bind($self->_channel, $args{queue}, $args{exchange}, $args{exchange});
    }
    catch ($err) {
        throw Kanopya::Exception::MessageQueuing::ChannelError(error => $err);
    }
}


=pod
=begin classdoc

Register the callback method for a specific channel and type.

@param queue the queue on which register the consumer

=end classdoc
=cut

sub consume {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'queue' ]);

    # Register the method to call back at message consumption
    $log->debug("Registering (consume) callback on queue <$args{queue}>");
    try {
        my $tag = $self->_connection->consume($self->_channel, $args{queue}, { no_ack => 0 });

        $log->debug("Registered (consume) callback, consumer tag <$tag>");
        return $tag;
    }
    catch ($err) {
        throw Kanopya::Exception::MessageQueuing::ChannelError(error => $err);
    }
}


=pod
=begin classdoc

Blokcing call that wait for messages.

=end classdoc
=cut

sub recv {
    my ($self, %args) = @_;

    my $msg;
    try {
        $msg = $self->_connection->recv();
    }
    catch ($err) {
        throw Kanopya::Exception::MessageQueuing::ChannelError(error => $err);
    }
    return $msg;
}


=pod
=begin classdoc

Acknowledge a message secified by tag.

@param tag the delivery tag of the message to ack

=end classdoc
=cut

sub acknowledge {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'tag' ]);

    $log->debug("Acknowledging message with tag <$args{tag}>");
    try {
        $self->_connection->ack($self->_channel, $args{tag});
    }
    catch ($err) {
        throw Kanopya::Exception::MessageQueuing::ChannelError(error => $err);
    }
}


=pod
=begin classdoc

Return the channel private attribute.

=end classdoc
=cut

sub _channel {
    my ($self, @args) = @_;
    my $class = ref($self) || $self;

    if (scalar(@args)) {
        $self->{_channels}->{$class} = shift @args;
    }
    else {
        return $self->{_channels}->{$class};
    }
}


=pod
=begin classdoc

Return the connection private attribute.

=end classdoc
=cut

sub _connection {
    my ($self, @args) = @_;

    if (scalar(@args)) {
        $self->{_connection} = shift @args;
    }
    else {
        return $self->{_connection};
    }
}

1;
