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

use AnyEvent;
use Data::Dumper;

use Log::Log4perl "get_logger";
my $log = get_logger("");


use constant DURATION => {
    FOREVER   => undef,
    SECOND    => 1,
    MINUTE    => 60,
    IMMEDIATE => 0.5
};


=pod
=begin classdoc

Disconnect from the message queuing server.

=end classdoc
=cut

sub disconnect {
    my ($self, %args) = @_;

    for my $type ('queue', 'topic') {
        for my $receiver (values %{ $self->_receivers->{$type} }) {
            delete $receiver->{receiver};
        }
    }
    return $self->SUPER::disconnect(%args);
}


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
                         required => [ 'type', 'channel', 'callback' ],
                         optional => { 'duration'  => 'FOREVER',
                                       'instances' => 1 });

    if ($args{type} !~ m/^(queue|topic)$/) {
        throw Kanopya::Exception::Internal::IncorrectParam(
                  error => "Wrong value <$args{type}> for argument <type>, must be <queue|topic>"
              );
    }

    if ($args{duration} !~ m/^(FOREVER|SECOND|MINUTE|IMMEDIATE)$/) {
        throw Kanopya::Exception::Internal::IncorrectParam(
                  error => "Wrong value <$args{duration}> for argument <duration>, " .
                           "must be <FOREVER|SECOND|MINUTE|IMMEDIATE>"
              );
    }

    if (not defined $self->_receivers) {
        $self->{_receivers} = {};
    }

    # Register the method to call back at message recepetion
    $self->_receivers->{$args{type}}->{$args{channel}} = {
        callback  => $args{callback},
        duration  => DURATION->{$args{duration}},
        instances => $args{instances},
    };

    # Declare the queues if connected
    if ($self->connected) {
        $self->_receivers->{$args{type}}->{$args{channel}}->{receiver}
            = $self->createReceiver(channel => $args{channel}, type => $args{type})
    }
}


=pod
=begin classdoc

Wait for message in an event loop, interupt the bloking call
if the duration exceed.

@param condvar the condition variable for the event loop

@optional duration the maximum time to wait messages.

=end classdoc
=cut

sub fetch {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'condvar' ],
                         optional => { 'duration' => undef });

    # Set a timer to wait messages for the specified duration only
    my $timeout = undef;
    if (defined $args{duration}) {
        $timeout = AnyEvent->timer(after => $args{duration}, cb => sub {
                       # Interupt the infinite loop
                       $args{condvar}->croak("No message recevied for $args{duration} second(s)");
                   });
    }

    # Wait for the first send from callback
    eval {
        $args{condvar}->recv;
    };
    if ($@) {
        my $err = $@;
        throw Kanopya::Exception::MessageQueuing::NoMessage(error => $err);
    }

    # Disarm the timer
    # TODO: We probably need to disarm the timer within the callback
    $timeout = undef;
}


=pod
=begin classdoc

Declare queues and exchanges.

@param channel the channel on which the callback is resistred
@param type the type of the queue (queue or topic)

=end classdoc
=cut

sub createReceiver {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'type', 'channel' ]);

    my $queue;
    if ($args{type} eq 'queue') {
        $queue = $self->_session->declare_queue(queue => $args{channel}, durable => 1);
    }
    elsif ($args{type} eq 'topic') {
        $self->_session->declare_exchange(
            exchange => $args{channel},
            type     => 'fanout',
        );

        $queue = $self->_session->declare_queue(exclusive => 1);
        $self->_session->bind_queue(
            exchange => $args{channel},
            queue    => $queue->{method_frame}->{queue},
        );
    }
    return $queue;
}


=pod
=begin classdoc

Register the callbck method for a specific channel and type.

@param queue the queue on which register hte calback
@param callback the callback method

@optional condvar the condition variable to interupt the event loop

=end classdoc
=cut

sub consume {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'queue', 'callback' ],
                         optional => { 'condvar' => undef });

    # Define the callback called at message consumption, it simply call
    # the callback method given at registration on the queue.
    my $callback = sub {
        my $var = shift;

        # TODO: Probably disarm the timer here...

        my ($type, $channel);
        if ($var->{deliver}->{method_frame}->{exchange} ne '') {
            # Seems to be a topic message
            $type = 'topic';
            $channel = $var->{deliver}->{method_frame}->{exchange};
        }
        elsif ($var->{deliver}->{method_frame}->{routing_key} ne '') {
            # Seems to be a queue message
            $type = 'queue';
            $channel = $var->{deliver}->{method_frame}->{routing_key};
        }
        else {
            throw Kanopya::Exception::Internal::IncorrectParam(
                      error => "Unreconized message type:\n" . Dumper($var)
                  );
        }

        # Decode the message content in way to use it as callback params
        my $args;
        eval {
            $args = JSON->new->utf8->decode($var->{body}->{payload});
        };
        if ($@) {
            my $err = $@;
            if ($err =~ m/malformed JSON string/) {
                $args = { data => $var->{body}->{payload} };
            }
            else { $err->rethrow(); }
        }

        # Build a callback method to ack the message
        my $ack_cb = sub {
            $self->acknowledge(tag => $var->{deliver}->{method_frame}->{delivery_tag});
        };

        # Call the corresponding method
        $args->{acknowledge_cb} = $ack_cb;
        if ($args{callback}->(%$args)) {
            # Acknowledge the message if specified by the callback
            $args->{acknowledge_cb}->();
        }

        # Interupt the second infinite loop
        if (defined $args{condvar}) {
            $args{condvar}->send;
        }
    };

    # Register the method to call back at message consumption
    return $self->_session->consume(on_consume => \&$callback,
                                    queue      => $args{queue},
                                    no_ack     => 0);
}


=pod
=begin classdoc

Receive messages from the specific channel, and call the corresponding callbacks.

@param channel the channel on which the callback is resistred
@param type the type of the queue (queue or topic)

=end classdoc
=cut

sub receive {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'type', 'channel' ]);

    if (not $self->connected) {
        $self->connect(%{$self->{_config}});
    }

    my $receiver = $self->_receivers->{$args{type}}->{$args{channel}};

    # Register the consumer on the channel
    if (not defined $receiver->{receiver}) {
        $receiver->{receiver} = $self->createReceiver(channel => $args{channel}, type => $args{type});
    }

    # Share the AnyEvent condvar with the callback
    my $condvar = AnyEvent->condvar;

    # Register the callback for the channel
    if (defined $receiver->{consumer}) {
        $self->cancel(receiver => $receiver);
    }
    $receiver->{consumer} = $self->consume(queue    => $receiver->{receiver}->{method_frame}->{queue},
                                           callback => $receiver->{callback},
                                           condvar  => $condvar);

    # Blocking call
    $self->fetch(condvar => $condvar, duration => $receiver->{duration});

    # Unregister the callback as we are in one by one fetch mode
    $self->cancel(receiver => $receiver);
}


=pod
=begin classdoc

Receive messages from all channels, spawn a child for each channel,
then wait on the $$running pointer to kill childs when the service is stopped.

=end classdoc
=cut

sub receiveAll {
    my ($self, $running) = @_;

    # Run through all registred receviers
    my $pid;
    for my $type ('queue', 'topic') {
        for my $channel (keys %{ $self->_receivers->{$type} }) {
            my $receiver = $self->_receivers->{$type}->{$channel};

            # Create specified number of instance of the worker/subscriber
            for (1 .. $receiver->{instances}) {
                # Fork for each channels
                $pid = fork();
                if ($pid == 0) {
                    $log->info("Spawn child process <$$> for waiting on <$type>, channel <$channel>");

                    # Connect to the broker within the child
                    if (not $self->connected) {
                        $self->connect(%{$self->{_config}});
                    }

                    # Create the receivers
                    if (not defined $receiver->{receiver}) {
                        $receiver->{receiver} = $self->createReceiver(channel => $channel, type => $type);
                    }
                    # Register the callback for this channel
                    if (defined $receiver->{consumer}) {
                        $self->cancel(receiver => $receiver);
                    }
                    $self->consume(
                        queue    => $receiver->{receiver}->{method_frame}->{queue},
                        callback => $receiver->{callback}
                    );

                    # Infinite loop on fetch
                    while (1) {
                        my $condvar = AnyEvent->condvar;
                        eval {
                            $self->fetch(condvar => $condvar, duration => $receiver->{duration});
                        };
                        if ($@) {
                            my $err = $@;
                            # Excpetion should be Kanopya::Exception::MessageQueuing::NoMessage
                            if (not $err->isa('Kanopya::Exception::MessageQueuing::NoMessage')) {
                                $err->rethow();
                            }
                        }
                    }
                    die;
                }
            }
        }
    }
    if ($pid != 0) {
        # Wait on the running pointer, and kill childs when the daemon is stopping
        while ($$running) {
            sleep(5);
        }
        kill -1, getpgrp($pid);
    }
}


=pod
=begin classdoc

Register the callbck method for a specific channel and type.

@param receiver the receiver data hash

=end classdoc
=cut

sub cancel {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'receiver' ]);

    my $consumer = delete $args{receiver}->{consumer};
    if ($consumer) {
        $self->_session->cancel(consumer_tag => $consumer->{method_frame}->{consumer_tag});
    }
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

    $self->_session->ack(delivery_tag => $args{tag}, multiple => 0);
}


=pod
=begin classdoc

Return the receivers instances.

=end classdoc
=cut

sub _receivers {
    my ($self, %args) = @_;

    return $self->{_receivers};
}

1;
