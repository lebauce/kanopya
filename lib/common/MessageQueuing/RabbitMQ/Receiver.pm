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

Base class to becomme a message queuing receiver.
Provide methods to register callback on queues or topics.

@since    2013-Avr-19
@instance hash
@self     $self

=end classdoc

=cut

package MessageQueuing::RabbitMQ::Receiver;
use base MessageQueuing::RabbitMQ;

use strict;
use warnings;

use Data::Dumper;

use Log::Log4perl "get_logger";
my $log = get_logger("");


=pod
=begin classdoc

Register a callback on a specific channel.

@param channel the channel on which the callback is resistred
@param type the type of the queue (queue or topic)
@param callback the classback method to call when data is produced on the channel

@optional the maximum duration of awaiting messages

=end classdoc
=cut

sub register {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'type', 'channel' ],
                         optional => { 'duration'  => undef,
                                       'instances' => 1 });

    if ($args{type} !~ m/^(queue|topic)$/) {
        throw Kanopya::Exception::Internal::IncorrectParam(
                  error => "Wrong value <$args{type}> for argument <type>, must be <queue|topic>"
              );
    }

    # Register the method to call back at message recepetion
    $self->_consumers->{$args{type}}->{$args{channel}} = {
        callback  => $args{callback},
        duration  => $args{duration},
        instances => $args{instances},
    };
}


=pod
=begin classdoc

Declare queues and exchanges.

@param channel the channel on which the callback is resistred
@param type the type of the queue (queue or topic)

=end classdoc
=cut

sub createConsumer {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'type', 'channel' ],
                         optional => { 'force' => 0 });

    # Declare queues or exchanges
    my $queue;
    if ($args{type} eq 'queue') {
        $queue = $self->declareQueue(channel => $args{channel});
    }
    elsif ($args{type} eq 'topic') {
        $log->debug("Declaring exchange <$args{channel}> of type <fanout>");
        $self->declareExchange(channel => $args{channel});

        $log->debug("Declaring exclusive queue in way to bind on exchange <$args{channel}>");
        $queue = $self->declareQueue(channel => $args{channel}, exclusive => 1);
        $log->debug("Binding queue $queue on exchange <$args{channel}>");
        # TODO: Move the job for queue binding in the parent package.
        $self->_connection->queue_bind($self->_channel, $queue, $args{channel}, $args{channel})
    }

    # Create the consumer on the channel for the queue
    $self->consume(queue => $queue);
}


=pod
=begin classdoc

Wait for message in an event loop, interupt the bloking call
if the duration exceed.

@optional timeout the maximum time to wait messages.

=end classdoc
=cut

sub fetch {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         optional => { 'timeout' => 30 });

    $log->debug("Fetch message for <$args{timeout}> second(s).");

    # Wait for messages
    my $rv;
    eval {
        local $SIG{ALRM} = sub {
            throw Kanopya::Exception::MessageQueuing::NoMessage(
                      error => "No message received for $args{timeout} (s)"
                  );
        };

        alarm $args{timeout};

        # Receive the message
        $rv = $self->recv();

        # Reset the alarm
        # TODO: The alarm should occurs between the previous line
        #       and the following one, need semaphore stuff.
        alarm 0;

        my ($type, $channel);
        if ($rv->{exchange} ne '') {
            # Seems to be a topic message
            $type = 'topic';
            $channel = $rv->{exchange};
        }
        elsif ($rv->{routing_key} ne '') {
            # Seems to be a queue message
            $type = 'queue';
            $channel = $rv->{routing_key};
        }
        else {
            throw Kanopya::Exception::Internal::IncorrectParam(
                      error => "Unreconized message type:\n" . Dumper($rv)
                  );
        }
        # Retreive the method to call form type and channel
        my $callback = $self->_consumers->{$type}->{$channel}->{callback};

        if (! (ref($callback) eq 'CODE')) {
            throw Kanopya::Exception::Internal::IncorrectParam(
                      error => "Defined callback <$callback> is not valid."
                  );
        }

        # Decode the message content in way to use it as callback params
        my $args;
        eval {
            $args = JSON->new->utf8->decode($rv->{body});
        };
        if ($@) {
            my $err = $@;
            if ($err =~ m/malformed JSON string/) {
                $args = { data => $rv->{body} };
            }
            else { $err->rethrow(); }
        }

        # Build a callback method to ack the message
        my $ack_cb = sub {
            $self->acknowledge(tag => $rv->{delivery_tag});
        };

        # Call the corresponding method
        $args->{ack_cb} = $ack_cb;
        if ($callback->(%$args)) {
            # Acknowledge the message if specified by the callback
            $args->{ack_cb}->();
        }
    };
    if ($@) {
        my $err = $@;
        if (ref($err)) {
            $err->rethrow();
        }
        else {
            throw Kanopya::Exception::Execution(error => "$err");
        }
    }
}


=pod
=begin classdoc

Return the consumers infos.

=end classdoc
=cut

sub _consumers {
    my ($self, %args) = @_;

    if (not defined $self->{_consumers}) {
        $self->{_consumers} = {}
    }
    return $self->{_consumers};
}

1;
