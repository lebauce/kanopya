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
use AnyEvent::Subprocess;
use Data::Dumper;

use Log::Log4perl "get_logger";
my $log = get_logger("");


use constant DURATION => {
    FOREVER   => undef,
    SECOND    => 1,
    MINUTE    => 60,
    IMMEDIATE => 0.5
};


# The condition variable shared between the main thread that awaiting
# messages and the callback executed at message receipt.
my $condvar;

# Timer ref to interut the wait of messages one a timeout exceed.
my $timeout = undef;


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

    # Register the method to call back at message recepetion
    $self->_consumers->{$args{type}}->{$args{channel}} = {
        callback  => $args{callback},
        duration  => DURATION->{$args{duration}},
        instances => $args{instances},
        # the consumer tag stored when callback registred
        consumer  => undef,
    };

    # Declare the queues if connected
    if ($self->connected) {
        $self->createConsumer(channel => $args{channel}, type => $args{type});
    }
}


=pod
=begin classdoc

Wait for message in an event loop, interupt the bloking call
if the duration exceed.

@optional duration the maximum time to wait messages.

=end classdoc
=cut

sub fetch {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'condvar' ],
                         optional => { 'duration' => undef });

    if (defined $args{duration}) {
        $log->debug("Fetch message for <$args{duration}> second(s).");
        $timeout = AnyEvent->timer(after => $args{duration}, cb => sub {
                       # Interupt the infinite loop
                       $args{condvar}->croak("No message recevied for $args{duration} second(s)");
                   });
    }
    else {
        $log->debug("Fetch messages indefinitely...");
    }

    # Wait for the first send from callback
    eval {
        $args{condvar}->recv;
    };
    if ($@) {
        my $err = $@;
        throw Kanopya::Exception::MessageQueuing::NoMessage(error => $err);
    }
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
                         optional => { 'force'   => 0 });

    # If the consumer exists, skip creation
    my $receiver = $self->_consumers->{$args{type}}->{$args{channel}};
    if (defined $receiver->{consumer}) {
        # If force defined, remove the existing consumer
        if ($args{force}) {
            $self->cancelConsumer(%args);
        }
        else {
            return;
        }
    }

    # Declare queues or exchanges
    if ($args{type} eq 'queue') {
        $receiver->{queue} = $self->declareQueue(channel => $args{channel})->{method_frame}->{queue};
    }
    elsif ($args{type} eq 'topic') {
        $log->debug("Declaring exchange <$args{channel}> of type <fanout>");
        $self->declareExchange(channel => $args{channel});

        $log->debug("Declaring exclusive queue in way to bind on exchange <$args{channel}>");
        $receiver->{queue} = $self->_channel->declare_queue(exclusive => 1)->{method_frame}->{queue};
        $log->debug("Binding queue $receiver->{queue} on exchange <$args{channel}>");
        $self->_channel->bind_queue(exchange => $args{channel},
                                    queue    => $receiver->{queue});
    }

    # Create the consumer on the channel for the queue
    my $consumer = $self->consume(queue    => $receiver->{queue},
                                  callback => $receiver->{callback});

    # Keep the consumer tag to know that the callback is already registred
    $receiver->{consumer} = $consumer->{method_frame}->{consumer_tag};
}


=pod
=begin classdoc

Unregister the consumer callback from the channel.

=end classdoc
=cut

sub cancelConsumer {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'type', 'channel' ]);

    my $receiver = $self->_consumers->{$args{type}}->{$args{channel}};

    $log->debug("Unregistering (cancel) callback with tag <$receiver->{consumer}>");
    $self->_channel->cancel(consumer_tag => $receiver->{consumer});

    # Arg, the cancel do not revmove the callback for the channel hash. It seems
    # to be done at channel closing, but we can't do that for instance.
    # TODO: Explore the AnyEvent::RabbitMQ internals.
    delete $self->_channel->{arc}->{_consumer_cbs}->{$receiver->{consumer}};

    # If the queue is bound to an exchange, unbind it.
    if ($args{type} eq 'topic') {
        $log->debug("Unbinding queue <$receiver->{queue}> from exchange <$args{channel}>");
        $self->_channel->unbind_queue(queue    => $receiver->{queue},
                                      exchange => $args{channel});
    }

    $receiver->{queue}    = undef;
    $receiver->{consumer} = undef;
}


=pod
=begin classdoc

Register the callbck method for a specific channel and type.

@param queue the queue on which register hte calback
@param callback the callback method

=end classdoc
=cut

sub consume {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'queue', 'callback' ]);

    # Define the callback called at message consumption, it simply call
    # the callback method given at registration on the queue.
    my $callback = sub {
        my $var = shift;

        # Disarm the timeout timer as the message is received
        $timeout = undef;

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
        if (defined $condvar) {
            $condvar->send;
        }
    };

    # Register the method to call back at message consumption
    $log->debug("Registering (consume) callback on queue <$args{queue}>");
    my $cons = $self->_channel->consume(on_consume => \&$callback,
                                    queue      => $args{queue},
                                    no_ack     => 0);
    $log->debug("Registered (consume) callback on queue <$args{queue}>");
    return $cons;
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

    $log->debug("Receiving messages on <$args{type}>, channel <$args{channel}>");
    my $duration = $self->_consumers->{$args{type}}->{$args{channel}}->{duration};

    if (not $self->connected) {
        $self->connect(%{$self->{_config}});
    }

    # Register the consumer on the channel
    $self->createConsumer(channel => $args{channel}, type => $args{type});

    # Defined the condition variable of this fetch
    $condvar = AnyEvent->condvar;

    # Blocking call
    my $err;
    eval {
        $self->fetch(duration => $duration, condvar => $condvar);
    };
    if ($@) { $err = $@; }

    $condvar = undef;

    # If got an exception while fetching, rethrow.
    if (defined $err) { throw $err; }
}


=pod
=begin classdoc

Receive messages from all channels, spawn a child for each channel,
then wait on the $$running pointer to kill childs when the service is stopped.

=end classdoc
=cut

sub receiveAll {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'stopcondvar' ]);

    # Ensure to connect within child processes
    if ($self->connected) {
        $self->disconnect();
    }

    # Run through all registred receviers
    my @childs;
    for my $type ('queue', 'topic') {
        for my $channel (keys %{ $self->_consumers->{$type} }) {
            my $receiver = $self->_consumers->{$type}->{$channel};

            # Define a common job for instances of this receiver
            my $job = AnyEvent::Subprocess->new(code => sub {
                $log->info("Spawn child process <$$> for waiting on <$type>, channel <$channel>.");

                # Connect to the broker within the child
                $self->connect(%{$self->{_config}});

                # Create the consumer
                $self->createConsumer(channel => $channel, type => $type);

                # Infinite loop on fetch. The event loop should never stop itself,
                # but looping here in a while, to re-trigger the event loop if anormaly fail.
                my $running = 1;
                while ($running) {
                    my $stopcondvar = AnyEvent->condvar;

                    # Define an handler on sig TERM to stop the event loop
                    my $sigterm = sub {
                        my $sig = shift;
                        $log->info("Child process <$$> received $sig: awaiting running job to exit...");

                        # Stop looping on the event loop
                        $running = 0;

                        # Interupt the event loop
                        $stopcondvar->send;
                    };
                    my $watcher = AnyEvent->signal(signal => "TERM", cb => \&$sigterm);

                    # Indefinitly fetch until sigterm handler send on the condvar
                    eval {
                        $self->fetch(condvar => $stopcondvar);
                    };
                    if ($@) {
                        my $err = $@;
                        # Excpetion should be Kanopya::Exception::MessageQueuing::NoMessage
                        if (not $err->isa('Kanopya::Exception::MessageQueuing::NoMessage')) {
                            $err->rethow();
                        }
                    }
                }
                $log->info("Child process <$$> stop waiting on <$type>, channel <$channel>, exiting.");

                # Disconnect the child from the broker
                $self->disconnect();
                exit 0;
            });

            # Create the specified number of instance of the worker/subscriber
            for (1 .. $receiver->{instances}) {
                push @childs, $job->run;
            }
        }
    }

    # Wait for daemon termination
    $args{stopcondvar}->recv;

    # Register a callback on the child termination, then send the TERM signal
    # to ask it to stop fetching after a possible current job.
    my @watchers;
    my $waitchild = AnyEvent->condvar;
    for my $child (@childs) {
        # Increase the condvar for each child
        $waitchild->begin;

        # Define a callback that decrease the condvar at child exit
        my $exitcb = sub {
            my ($pid, $status) = @_;
            $log->info("Child process <$pid> exiting with status $status.");
            $waitchild->end;
        };
        push @watchers, AnyEvent->child(pid => $child->child_pid, cb => \&$exitcb);

        # Sending TERM signal to the child
        $child->kill(15);
    }

    # Wait for childs
    $waitchild->recv;
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
    $self->_channel->ack(delivery_tag => $args{tag}, multiple => 0);
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
