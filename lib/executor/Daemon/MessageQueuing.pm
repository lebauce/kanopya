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

Base class to manage internal daemons that communicate between them.

@since    2013-Mar-28
@instance hash
@self     $self

=end classdoc

=cut

package Daemon::MessageQueuing;
use base Daemon;
use base MessageQueuing::RabbitMQ::Receiver;

use strict;
use warnings;

use Data::Dumper;

use Log::Log4perl "get_logger";
my $log = get_logger("");

use vars qw($AUTOLOAD);

use constant CALLBACKS => {};

sub getCallbacks { return CALLBACKS; }


=pod
=begin classdoc

@constructor

Base method to configure the daemon to use the message queuing middleware,
bind callback methods to the corresponing queues.

=end classdoc
=cut

sub new {
    my ($class, %args) = @_;

    my $self = $class->SUPER::new(%args);

    # Get the callback related amqp conf
    my $cbconf = $self->{config}->{amqp}->{callbacks};

    # Register the callback for used channels
    CALLBACK:
    for my $cbname (keys %{ $self->getCallbacks }) {
        my $callback = $self->getCallbacks->{$cbname};

        # Handle the callbacks conf if defined
        if (defined $cbconf) {
            # If callbacks specified in the conf, skip not defined ones
            if (not defined $cbconf->{$cbname}) {
                $log->info("Skiping callback <$cbname> on channel <$callback->{channel}>");
                next CALLBACK;
            }
            # If the number of instance is specified in conf,
            # override the callback definition
            if (defined $cbconf->{$cbname}->{instances}) {
                $callback->{instances} = $cbconf->{$cbname}->{instances};
            }
        }

        # Define a closure that call the specified callaback within eval
        my $cbmethod = sub {
            my %cbargs = @_;
            my $ack = 0;
            eval {
                $ack = $callback->{callback}->($self, %cbargs);
            };
            if ($@) {
                $log->error("$@");
                $ack = 1;
            }
            return $ack;
        };

        # Register worker/subscriber in function of the type
        my $instances = defined $callback->{instances} ? $callback->{instances} : 1;

        $log->info("Registering $instances callback(s) <$cbname> on channel <$callback->{channel}>");

        if ($callback->{type} eq 'queue') {
            $self->registerWorker(callback  => \&$cbmethod,
                                  channel   => $callback->{channel},
                                  instances => $instances,
                                  # Force the duration if defined
                                  duration  => $args{duration}
                                                   ? $args{duration} : $callback->{duration});
        }
        else {
            $self->registerSubscriber(callback  => \&$cbmethod,
                                      channel   => $callback->{channel},
                                      instances => $instances,
                                      # Force the duration if defined
                                      duration  => $args{duration}
                                                       ? $args{duration} : $callback->{duration});
        }
    }
    if (not defined $self->_consumers) {
        throw Kanopya::Exception(
            error => "Could not start daemon $self->{name}, no callback defined..."
        );
    }

    # Private member usefull to stop receving until the specified duration
    # when the deamon stop.
    $self->{_running} = 1;

    return $self;
}


=pod
=begin classdoc

Override the connect method to connect the component by giving it the already openned
connection of the deamon.

=end classdoc
=cut

sub connect {
    my ($self, %args) = @_;

    $self->SUPER::connect(%{ $self->{config}->{amqp} });

    # Connect the component as the connection can not be done
    # within a message callback.
    eval {
        $self->_component->connect(%{$self->{config}->{amqp}});

        # Set the in_eventloop mode on the sender as we want to avoid the sender to connect
        # or declare queues as it cannot be done in an event loop.
        $self->_component->setCallBackMode;
    };
    if ($@) {
        my $err = $@;
        if (ref($err) and $err->isa('Kanopya::Exception::Internal::NotFound')) {
            $log->warn("Can not connect the sender component <Kanopya" . $self->{name} .
                       "> as it can not be found.");
        }
        elsif (ref($err)) { $err->rethrow(); }
        else {
            throw Kanopya::Exception(
                      error => "Unable to connect the component to the broker: $err \n"
                  );
        }
    }
}


=pod
=begin classdoc

Close the channel of the component before disconnecting.

=end classdoc
=cut

sub disconnect {
    my ($self, %args) = @_;

    $self->SUPER::disconnect(%args);
}


=pod
=begin classdoc

Register the daemon as a worker on a specific channel.
Produced data is distributed among workers, each data is delivered to exactly one worker.

@param channel the channel on which the callback is resistred
@param callback the classback method to call when data is produced on the channel

=end classdoc
=cut

sub registerWorker {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'channel', 'callback' ]);

    # Set up the daemon as receiver worker on the queue corresponding to the
    # specified channel name.
    $self->register(type => 'queue', %args);
}


=pod
=begin classdoc

Register the daemon as a subscriber on a specific channel.
Produced data is delivred to each subscribers.

@param channel the channel on which the callback is resistred
@param callback the classback method to call when data is produced on the channel

=end classdoc
=cut

sub registerSubscriber {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'channel', 'callback' ]);

    # Set up the daemon as receiver subscriber on the topic corresponding to the
    # specified channel name.
    $self->register(type => 'topic', %args);
}


=pod
=begin classdoc

Base method to run the daemon.
Override the parent method, create a child process for each registration on channels.

@param condvar the condition variable on which the daemon wait for termination

=end classdoc
=cut

sub run {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         optional => { 'condvar' => AnyEvent->condvar });

    Message->send(
        from    => $self->{name},
        level   => 'info',
        content => "Kanopya $self->{name} started."
    );

    # Disconnect possibly connected session, as we must do
    # the connection inside the childs created for each channel.
    if ($self->connected) {
        $self->disconnect();
    }

    # Wait on all channel of all types
    $self->receiveAll(stopcondvar => $args{condvar});

    # Never should aprear as the parent process loop on the running
    # pointer only, to properly stop the childs jobs at daemon stopping.
    if ($self->connected) {
        $self->disconnect();
    }

    Message->send(
        from    => $self->{name},
        level   => 'warning',
        content => "Kanopya $self->{name} stopped"
    );
}


=pod
=begin classdoc

Receive messages from the channels on which the daemon is registred,
and call the corresponding callbacks.

=end classdoc
=cut

sub oneRun {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'channel', 'type' ]);

    # Blocking call
    eval {
        $self->receive(type => $args{type}, channel => $args{channel});
    };
    if ($@) {
        my $err = $@;
        $self->disconnect();
        $err->rethrow();
    }
    $self->disconnect();
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

    General::checkParams(args     => \%args,
                         required => [ 'type', 'channel' ],
                         optional => {});

    my $duration = $self->_consumers->{$args{type}}->{$args{channel}}->{duration};
    $log->debug("Receiving messages on <$args{type}>, channel <$args{channel}>, for <$duration> s.");

    if (not $self->connected) {
        $self->connect();
    }

    # Register the consumer on the channel
    $self->createConsumer(channel => $args{channel}, type => $args{type});

    # Continue to fetch while duration not expired
    my $start = time;
    while ((time - $start) < $duration && $self->isRunning) {
        # Blocking call
        $self->fetch(timeout => $duration - (time - $start));
    }
}


=pod
=begin classdoc

Receive messages from all channels, spawn a child for each channel,
then wait on the stop condition variable to kill childs when the service is stopped.

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
                eval {
                    $log->info("Spawn process <$$> for waiting on <$type>, channel <$channel>. ");

                    # Infinite loop on fetch. The event loop should never stop itself,
                    # but looping here in a while, to re-trigger the event loop if anormaly fail.
                    my $publish_error = undef;
                    while ($self->isRunning) {
                        # Connect to the broker within the child
                        $self->connect();

                        # Define an handler on sig TERM to stop the event loop
                        local $SIG{TERM} = sub {
                            $log->info("Child process <$$> received TERM: awaiting running job to exit...");

                            # Stop looping on the event loop
                            $self->setRunning(running => 0);
                        };

                        # Retrigger a message defined
                        if (defined $publish_error) {
                            # TODO: retrriger the message
                            $publish_error = undef;
                        }

                        # Continue to fetch while duration not expired
                        eval {
                            $self->receive(type => $type, channel => $channel);
                        };
                        if ($@) {
                            my $err = $@;
                            if (! $err->isa('Kanopya::Exception::MessageQueuing::NoMessage')) {
                                # If a publish error occurs, keep the undelivred message body
                                # to retrigger it at reconnection.
                                if ($err->isa('Kanopya::Exception::MessageQueuing::PublishFailed')) {
                                    $publish_error = $err;
                                }
                                # Log the error...
                                if ($self->isRunning) {
                                    $log->error("Fetch on <$type>, channel <$channel> failed: $err");
                                }
                                # ...and exist the loop to try to reconnect
                                last;
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
        $args{stopcondvar} = AnyEvent->condvar;
        # Send the TERM signal to ask it to stop fetching after a possible current job.
        for my $child (@childs) {
            # Increase the condvar for each child
            $args{stopcondvar}->begin;
            # Sending TERM signal to the child
            $child->kill(15);
        }
        $log->info("Daemon $self->{name} stopped, waiting for childs...");
        $args{stopcondvar}->recv;
    }
}

=pod
=begin classdoc

Set the running prviate member.

=end classdoc
=cut

sub setRunning {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'running' ]);

    $self->{_running} = $args{running};
}


=pod
=begin classdoc

@return the running private member.

=end classdoc
=cut

sub isRunning {
    my ($self, %args) = @_;

    return ($self->{_running} == 1);
}

1;
