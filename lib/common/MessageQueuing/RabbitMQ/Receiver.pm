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
        $self->connect();
    }

    # Register the consumer on the channel
    $self->createConsumer(channel => $args{channel}, type => $args{type});

    # Blocking call
    my $err;
    eval {
        $self->fetch(duration => $duration);
    };
    if ($@) { $err = $@; }

    # TODO: Cancel the consumer.

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
                $log->info("Spawn process <$$> for waiting on <$type>, channel <$channel>. ");
                eval {
                    # Infinite loop on fetch. The event loop should never stop itself,
                    # but looping here in a while, to re-trigger the event loop if anormaly fail.
                    my $running = 1;
                    my $retrigger_cb = undef;
                    while ($running) {
                        # Connect to the broker within the child
                        $self->connect();

                        # Create the consumer
                        $self->createConsumer(channel   => $channel,
                                              type      => $type);

                        # Define an handler on sig TERM to stop the event loop
                        my $sigterm = sub {
                            my $sig = shift;
                            $log->info("Child process <$$> received $sig: awaiting running job to exit...");

                            # Stop looping on the event loop
                            $running = 0;

                            # TODO: Interupt the event loop
                            alarm 1;
                        };
                        my $watcher = AnyEvent->signal(signal => "TERM", cb => \&$sigterm);

                        # Retrrgier undelivred message if defined
#                        if (defined $retrigger_cb) {
#                            $retrigger_cb->();
#                            $retrigger_cb = undef;
#                        }

                        # Continue to fetch while duration not expired
                        my $start = time;
                        while ((time - $start) < $receiver->{duration}) {
                            eval {
                                $self->fetch(duration => $receiver->{duration});
                            };
                            if ($@) {
                                my $err = $@;
                                if (! $err->isa('Kanopya::Exception::MessageQueuing::NoMessage')) {
                                    # Only log the error for instace, and exist the loop to try to reconnect
                                    $log->error("Fetch on <$type>, channel <$channel> failed: $err");
                                    last;
                                }
                            }
                        }

                        # Disconnect the child from the broker
                        $self->disconnect();
                    }
                };
                if ($@) {
                    my $err = $@;
                    $log->info("Child process <$$> failed: $err");
                }

                $log->info("Child process <$$> stop waiting on <$type>, channel <$channel>, exiting.");
                exit 0;
            });

            # Create the specified number of instance of the worker/subscriber
            for (1 .. $receiver->{instances}) {
                push @childs, $job->run;
            }
        }
    }

    # Register a callback on the child termination
    my @watchers;
    for my $child (@childs) {
        # Increase the condvar for each child
        $args{stopcondvar}->begin;

        # Define a callback that decrease the condvar at child exit
        my $exitcb = sub {
            my ($pid, $status) = @_;
            $log->info("Child process <$pid> exiting with status $status.");
            $args{stopcondvar}->end;
        };
        push @watchers, AnyEvent->child(pid => $child->child_pid, cb => \&$exitcb);
    }

    # Wait for childs or daemon termination
    eval {
        $args{stopcondvar}->recv;
    };
    if ($@) {
        # Send the TERM signal to ask it to stop fetching after a possible current job.
        for my $child (@childs) {
            # Increase the condvar for each child
            $args{stopcondvar}->begin;
            # Sending TERM signal to the child
            $child->kill(15);
        }
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
                         optional => { 'duration' => 30 });

    if (defined $args{duration}) {
        $log->debug("Fetch message for <$args{duration}> second(s).");
    }
    else {
        $log->debug("Fetch messages indefinitely...");
    }

    # Wait for messages
    my $rv;
    eval {
        local $SIG{ALRM} = sub {
            throw Kanopya::Exception::MessageQueuing::NoMessage(
                      error => "No message received for $args{duration} (s)"
                  );
        };

        alarm $args{duration};

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
        # Build a callback method to raise the reconnection at channel error
        my $err_cb = sub {
            my %args = @_;
        };

        # Call the corresponding method
        $args->{ack_cb} = $ack_cb;
        $args->{err_cb} = $err_cb;
        if ($callback->(%$args)) {
            # Acknowledge the message if specified by the callback
            $args->{ack_cb}->();
        }
    };
    if ($@) {
        my $err = $@;
        $err->rethrow();
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
