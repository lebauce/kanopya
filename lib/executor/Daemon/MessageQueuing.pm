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
The MessageQueueing daemon is designed to wait on ampq queues, and trigger
a callback method at message receipt. One daemon could awaiting message on many queues
by defining many callback definition, a child will be spawned for each.

the callbacks can be defined in the CALLBACK constant when inherit from this class,
or dynamically by calling the registerCallback method.

A callback definition has the following structure:

# The callback definition name is a unique name that identity the definition.
callback_definition_name => {
    # The callback method to execute at message receipt.
    callback  => \&methodName,
    # The type of the callaback, could be 'queue', 'topic' or 'fanout'.
    type      => 'queue',
    # The queue name on which awaiting messages, if not defined an exclusive
    # queue name will be generated (for type 'topic' and 'fanout' only).
    queue     => 'queuename',
    # The exchange name to declare, mandatory if 'queue' not specified.
    exchange  => 'echangename',
    # The number of child to spawn that will awaiting message on the queue.
    instances => 2,
    # The maximum duration while awaiting message before reconnecting, 0 is infinite.
    duration  => 30,
    # A flag that could be turned off to disable the queue/exchange declaration,
    # usefull for awainting messages on existing/external amqp queues/exchanges.
    declare  => 1,
    # The amqp connection informations that could be overriden by callback.
    config    => {
        ip       => '127.0.0.1',
        port     => 5672,
        user     => 'guest',
        password => 'guest',
        vhost    => '/',
    },
}

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

use AnyEvent;
use AnyEvent::Subprocess;
use Data::Dumper;
use String::Random;
use Clone qw(clone);

use TryCatch;
my $err;

use Log::Log4perl "get_logger";
my $log = get_logger("");

use vars qw($AUTOLOAD);

use constant CALLBACKS => {};

sub getCallbacks { return CALLBACKS; }


my $merge = Hash::Merge->new('RIGHT_PRECEDENT');


=pod
=begin classdoc

@constructor

Instanciate a message queueing daemon.

@return the daemon instance

=end classdoc
=cut

sub new {
    my ($class, %args) = @_;

    my $self = $class->SUPER::new(%args);

    # Private member usefull to stop receving until the specified duration
    # when the deamon stop.
    $self->setRunning(running => 1);

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
    try {
        $self->_component->connect(%{ $self->{config}->{amqp} });

        # Set the in_eventloop mode on the sender as we want to avoid the sender to connect
        # or declare queues as it cannot be done in an event loop.
        $self->_component->setCallBackMode;
    }
    catch (Kanopya::Exception::Internal::NotFound $err) {
        $log->warn("Can not connect the sender component <Kanopya" . $self->{name} .
                   "> as it can not be found.");
    }
    catch (Kanopya::Exception $err) {
        $err->rethrow();
    }
    catch ($err) {
        throw Kanopya::Exception(
                  error => "Unable to connect the component to the broker: $err\n"
              );
    }
}


=pod
=begin classdoc

Close the connection of the component before disconnecting.

=end classdoc
=cut

sub disconnect {
    my ($self, %args) = @_;

    try {
        $self->_component->disconnect();
    }
    catch (Kanopya::Exception::Internal::NotFound $err) {
        $log->warn("Can not disconnect the sender component <Kanopya" . $self->{name} .
                   "> as it can not be found.");
    }
    catch (Kanopya::Exception $err) {
        $err->rethrow();
    }
    catch ($err) {
        throw Kanopya::Exception(
                  error => "Unable to disconnect the component to the broker: $err \n"
              );
    }

    # Remove the consumer tag ofr all callback definition as we are disconnecting,
    # and the consumer must to be re-created at next use.
    for my $callbackdef (values %{ $self->_callbacks }) {
        delete $callbackdef->{consumer};
    }

    $self->SUPER::disconnect(%args);
}


=pod
=begin classdoc

Register the daemon as a worker on a specific queue.
Produced data is distributed among workers, each data is delivered to exactly one worker.

@param queue the queue on which the callback is resistred
@param callback the callback method to call when data is produced on the queue

=end classdoc
=cut

sub registerWorker {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'queue', 'callback' ]);

    # Set up the daemon as receiver worker on the queue
    $self->registerCallback(type => 'queue', %args);
}


=pod
=begin classdoc

Register the daemon as a subscriber on a specific queue binded on the given exchange.
Produced data is delivred to each subscribers.

@param exchange the exchange to declare
@param type the type of the exchange to declare (topic|fanout)
@param callback the callback method to call when data is produced on the exchange

@optional queue a named queue that skip the exclusive queue generation

=end classdoc
=cut

sub registerSubscriber {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'exchange', 'type', 'callback' ],
                         optional => { 'queue' => undef });

    # Set up the daemon as receiver subscriber on the topic/fanout corresponding to the
    # specified exchange name.
    $self->registerCallback(%args);
}


=pod
=begin classdoc

Register a callback on a specific queue or exchange.

@param cbname the callback name to register, it is a unique nameused to identify the callback definition
@param type the type of the callback registration (queue|fanout|topic)
@param callback the classback method to call when data is produced on the queue/exchange

@optional queue the queue to use, required for type <queue>, optional for type <fanout|topic>
@optional exchange the exchange on which is binded the queue, required for type <fanout|topic>

=end classdoc
=cut

sub registerCallback {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'cbname', 'type', 'callback' ],
                         optional => { 'queue' => undef, 'exchange' => undef, config => undef,
                                       'declare' => 1, instances => 1, duration => 30 });

    # Initialize the new callback definiton
    my $callbackdef = {
        type      => $args{type},
        callback  => $args{callback},
        declare   => $args{declare},
        instances => $args{instances},
        duration  => $args{duration},
    };

    if ($args{type} !~ m/^(queue|topic|fanout)$/) {
        throw Kanopya::Exception::Internal::IncorrectParam(
                  error => "Wrong value <$args{type}> for argument <type>, must be <queue|topic|fanout>"
              );
    }
    elsif ($args{type} eq "queue") {
        if (! defined $args{queue}) {
            throw Kanopya::Exception::Internal::IncorrectParam(
                      error => "You must specify a queue for callbacks fo type <queue>"
                  );
        }

        # Fill the callback definition with the queue name
        $callbackdef->{queue} = $args{queue};
    }
    elsif (! defined $args{exchange}) {
        throw Kanopya::Exception::Internal::IncorrectParam(
                error => "You must specify an exchange for callbacks fo type <$args{type}>"
              );
    }
    else {
        # Fill the callback definition with the echange name and possibly fixed queue name
        $callbackdef->{exchange} = $args{exchange};
        if (defined $args{queue}) {
            $callbackdef->{queue} = $args{queue};
        }
    }

    # Handle the overriden connection config if defined
    if (defined $args{config}) {
        $callbackdef->{config} = $args{config};
    }

    # Add the callback definition
    $self->_callbacks->{$args{cbname}} = $callbackdef;
}


=pod
=begin classdoc

Register the consumer for the specified callback definition. Override some callback definition
possible forced configuration from configuration file.

@param cbname the callback name that identity the callback definition to use
              for create the consumer

=end classdoc
=cut

sub createConsumer {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'cbname' ]);

    my $callbackdef = $self->_callbacks->{$args{cbname}};
    if (! defined $callbackdef) {
        throw Kanopya::Exception::Internal::NotFound(
                  error => "No callback registred with name <$args{cbname}>"
              );
    }

    # If a consumer already created for this callback, skipping.
    if (defined $callbackdef->{consumer}) {
        $log->warn("Consumer already exists for callback <$args{cbname}>, skipping...");
        return;
    }

    # Check if the connection configuration has been overriden by the callback definition.
    if (defined $callbackdef->{config}) {
        $self->{config}->{amqp} = $merge->merge($self->{config}->{amqp}, $callbackdef->{config});
        # Force the re-connection as the config should changed
        $self->disconnect();
    }

    if (not $self->connected) {
        $self->connect();
    }

    # Get the callback related amqp conf
    my $cbconf = $self->{config}->{amqp}->{callbacks};

    # If the number of instance is specified in conf, override the callback definition
    if (defined $cbconf->{$args{cbname}}->{instances}) {
        $callbackdef->{instances} = $cbconf->{$args{cbname}}->{instances};
    }

    # Define a closure that call the specified callaback within eval
    my $cbmethod = sub {
        my %cbargs = @_;
        return $callbackdef->{callback}->($self, %cbargs);
    };

    $log->debug("Create consumer callback <$args{cbname}> of type <$callbackdef->{type}>.");
    $callbackdef->{consumer} = $self->SUPER::createConsumer(%$callbackdef, callback => \&$cbmethod);
}


=pod
=begin classdoc

Base method to run the daemon.
Override the parent method, create a child process for each registration on callbacks.

@param condvar the condition variable on which the daemon wait for termination

=end classdoc
=cut

sub runLoop {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         optional => { 'condvar' => AnyEvent->condvar });

    # Disconnect possibly connected session, as we must do
    # the connection inside the childs created for each callback.
    if ($self->connected) {
        $self->disconnect();
    }

    # Wait on all queues
    $self->receiveAll(stopcondvar => $args{condvar});

    # Never should aprear as the parent process loop on the running
    # pointer only, to properly stop the childs jobs at daemon stopping.
    if ($self->connected) {
        $self->disconnect();
    }
}


=pod
=begin classdoc

Receive one messages from the queues on which the daemon is registred,
and call the corresponding callback.

@param cbname the callback name that identity the callback definition
              to use for create the consumer
@param duration the duration while awaiting messages

@optional keep_connection flag to keep connection after receving the message,
                          usefull for test purpose.

=end classdoc
=cut

sub oneRun {
    my ($self, %args) = @_;

    General::checkParams(args => \%args,
                         required => [ 'cbname', 'duration'],
                         optional => { 'keep_connection' => 0 });

    # Create the consumer for the specified callback
    $self->createConsumer(cbname => $args{cbname});

    # Blocking call
    try {
        $self->receive(duration => $args{duration}, count => 1);
    }
    catch (Kanopya::Exception $err) {
        $self->disconnect();
        $err->rethrow();
    }
    catch ($err) {
        $self->disconnect();
        throw Kanopya::Exception(
                  error => "Unable to connect the component to the broker: $err \n"
              );
    }

    if (! $args{keep_connection}) {
        $self->disconnect();
    }
}


=pod
=begin classdoc

Receive messages during the specified duration.

@param duration the duration while awaiting messages

@optional count the maximum number of message to receive

=end classdoc
=cut

sub receive {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'duration' ],
                         optional => { 'count' => undef });

    $log->debug("Receiving messages for <$args{duration}> s.");

    if (not $self->connected) {
        $self->connect();
    }

    # Continue to fetch while duration not expired
    my $count = 0;
    my $start = time;
    while (($args{duration} == 0 || (time - $start) < $args{duration}) && $self->isRunning) {
        # Blocking call
        $self->fetch(timeout => ($args{duration} == 0) ? 0 : $args{duration} - (time - $start));

        $count++;
        if (defined $args{count} && $count >= $args{count}) {
            last;
        }
    }
}


=pod
=begin classdoc

Receive messages from all queues, spawn a child for each queues,
then wait on the stop condition variable to kill childs when the service is stopped.

@param stopcondvar the conditional variable on which the parent process will block
                   after spawning all childs. The conditional variable could be unlocked
                   when all child has terminated or when the caller process (usually the
                   service script) want to stop receiving messages.
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
    for my $cbname (keys %{ $self->_callbacks }) {
        my $callbackdef = $self->_callbacks->{$cbname};

        # Build the common message substring according to the callback definition
        my $message = "on ";
        if ($callbackdef->{type} eq "queue") {
            $message .= "queue <$callbackdef->{queue}>";
        }
        else {
            $message .= "exchange <$callbackdef->{exchange}> of type <$callbackdef->{type}>";
            if (defined $callbackdef->{queue}) {
                $message .= " (queue <$callbackdef->{queue}>)";
            }
        }

        # Define a common job for instances of this consumer
        my $job = AnyEvent::Subprocess->new(code => sub {
            eval {
                $log->info("Spawn process <$$> for waiting $message.");

                # Infinite loop on fetch. The event loop should never stop itself,
                # but looping here in a while, to re-trigger the event loop if anormaly fail.
                my $publish_error = undef;
                while ($self->isRunning) {
                    # Define an handler on sig TERM to stop the event loop
                    local $SIG{TERM} = sub {
                        $log->info("Child process <$$> received TERM: awaiting running job to exit...");

                        # Stop looping on the event loop
                        $self->setRunning(running => 0);
                    };

                    # Connect to the broker within the child
                    $self->connect();

                    # Create the consumer for the current callback
                    if ($self->connected) {
                        $self->createConsumer(cbname => $cbname);
                    }

                    # Retrigger a message defined
                    if (defined $publish_error) {
                        my $queue = $publish_error->queue;
                        $log->info("Retriggering undelivred message on <" . $queue . ">");
                        $self->_component->send(queue => $publish_error->queue, %{ $publish_error->body });
                        $publish_error = undef;
                    }

                    # Continue to fetch while duration not expired
                    eval {
                        $self->receive(duration => $callbackdef->{duration});
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
                                $log->error("Fetch on $message failed: $err");
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

            $log->info("Child process <$$> stop waiting $message, exiting.");
            exit 0;
        });

        # Create the specified number of instance of the worker/subscriber
        for (1 .. (defined $callbackdef->{instances} ? $callbackdef->{instances} : 1)) {
            push @childs, $job->run;
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

Purge the queue. Override the parent mathod to connect if not donne.

@param queue the queue to purge

=end classdoc
=cut

sub purgeQueue {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'queue' ]);

    if (not $self->connected) {
        $self->connect();
    }
    return $self->SUPER::purgeQueue(%args);
}


=pod
=begin classdoc

Set the running prviate member.

@param running the running flag to set

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


=pod
=begin classdoc

Return the registred callbacks infos.

=end classdoc
=cut

sub _callbacks {
    my ($self, %args) = @_;

    if (not defined $self->{_callbacks}) {
        $self->{_callbacks} = clone($self->getCallbacks());
    }
    return $self->{_callbacks};
}

1;
