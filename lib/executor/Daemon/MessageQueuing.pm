#    Copyright © 2014 Hedera Technology SAS
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

use Switch;
use TryCatch;

use Log::Log4perl "get_logger";
my $log = get_logger("amqp");

use vars qw($AUTOLOAD);

use constant CALLBACKS => {
    control_queue => {
        callback  => \&controlDaemon,
        type      => 'queue',
        # The queue name will be defined at runtime
        queue     => undef,
        declare   => 1,
        internal  => 1,
    },
};

sub getCallbacks { return CALLBACKS; }


my $merge = Hash::Merge->new('RIGHT_PRECEDENT');

# Conditional variable used to waiting for all childs at termination
my $condvar;

# Conditional variable used at instance kill in controlDaemon,
# because we need to  execute the AnyEvent event loop, to implicitly
# execute the callback set on the child termination.
my $killcondvar;

# List to keep Anyevent->child watchers refs
my @watchers;


=pod
=begin classdoc

@constructor

Set the control queue name from the hostname of the node
where the daemon is running.

=end classdoc
=cut

sub new {
    my ($class, %args) = @_;

    my $self = $class->SUPER::new(%args);

    # Build the control queue name from the hostname
    $self->_callbacks->{control_queue}->{queue}
        = "kanopya." . lc($self->{name}) . '.control.' . lc($self->_host->node->node_hostname);

    # Set the control queue name to the corresponding component configuration
    $self->_component->setConf(conf => { control_queue => $self->_callbacks->{control_queue}->{queue} });

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

    # Remove the consumer tag for all callback definition as we are disconnecting,
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
                         optional => { 'queue' => undef, 'exchange' => undef, 'config' => undef,
                                       'declare' => 1, 'instances' => 1, 'duration' => 30 });

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

    # Get the callback related amqp conf,
    # if the number of instances is specified in conf, override the callback definition
    my $cbconf = $self->{config}->{amqp}->{callbacks};
    if (defined $cbconf->{$args{cbname}}->{instances}) {
        $callbackdef->{instances} = $cbconf->{$args{cbname}}->{instances};
    }

    # Check the callback definition consistency.
    if ($callbackdef->{type} ne "queue" && ! defined $callbackdef->{exchange}) {
        throw Kanopya::Exception::Internal::IncorrectParam(
                  error => "You must provide an exchange for consumers of type <$callbackdef->{type}>"
              );
    }

    # Connect to broker to delcare queues/exchanges and consumer
    if (not $self->connected) {
        $self->connect();
    }

    # Declare queues or exchanges if required
    if ($callbackdef->{declare} || ! defined $callbackdef->{queue}) {
        # Delcare the queue, If queue undefined, generate an exclusique queue.
        $callbackdef->{queue} = $self->declareQueue(queue => $callbackdef->{queue});

        # Delcare the exchange
        if ($callbackdef->{type} ne "queue") {
            if ($callbackdef->{declare}) {
                $self->declareExchange(exchange => $callbackdef->{exchange}, type => $callbackdef->{type});
            }

            $self->bindQueue(queue => $callbackdef->{queue}, exchange => $callbackdef->{exchange});
        }
    }

    # Define a closure that call the specified callaback within eval
    my $cbmethod = sub {
        my %cbargs = @_;
        return $callbackdef->{callback}->($self, %cbargs);
    };

    $log->debug("Create consumer callback <$args{cbname}> of type <$callbackdef->{type}>.");
    $callbackdef->{consumer} = $self->SUPER::createConsumer(queue    => $callbackdef->{queue},
                                                            callback => \&$cbmethod);
}


=pod
=begin classdoc

Create consumers for internal callback definitions.

@optional purge purge the queue after consumer creation. 

=end classdoc
=cut

sub createInternalConsumers {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, optional => { 'purge' => 0 });

    for my $cbname (grep { $self->_callbacks->{$_}->{internal} } keys %{$self->_callbacks}) {
        $self->createConsumer(cbname => $cbname);

        # Purge the queue
        if ($args{purge}) {
            $self->purgeQueue(queue => $self->_callbacks->{$cbname}->{queue});
        }
    }
}


=pod
=begin classdoc

Base method to run the daemon.
Override the parent method, create a child process for each registration on callbacks.

=end classdoc
=cut

sub runLoop {
    my ($self, %args) = @_;

    # Disconnect possibly connected session, as we must do
    # the connection inside the childs created for each callback.
    if ($self->connected) {
        $self->disconnect();
    }

    $self->setRunning(running => 1);

    # Wait on all queues
    $self->receiveAll();

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
    $self->setRunning(running => 1);
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
                  error => "Unable to connect the component to the broker: $err\n"
              );
    }

    if (! $args{keep_connection}) {
        $self->disconnect();
    }
}


=pod
=begin classdoc

Receive messages during the specified duration.

@optional duration the duration while awaiting messages, 0 is infinity
@optional count the maximum number of message to receive

=end classdoc
=cut

sub receive {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         optional => { 'count' => undef, 'duration' => 0 });

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

=end classdoc
=cut

sub receiveAll {
    my ($self, %args) = @_;

    # Ensure to connect within child processes
    if ($self->connected) {
        $self->disconnect();
    }

    # Create consumers on the for the parent process from internal callbacks.
    $self->createInternalConsumers(purge => 1);

    # Send messages on the control queue to spawn childs for callback definitions
    for my $cbname (grep { ! $self->_callbacks->{$_}->{internal} } keys %{$self->_callbacks}) {
        $self->_component->controlDaemon(
            cbname    => $cbname,
            control   => 'spawn',
            instances => $self->_callbacks->{$cbname}->{instances} || 1
        );
    }

    # Instanciate a conditional variable to wait childs termination
    $condvar = AnyEvent->condvar;

    # Wait for message on the control queue
    while ($self->isRunning) {
        try {
            # Receive messages one by one as we are disconnecting while handling the callback
            # to fork without oponned connections.
            # So receive a message, disconnect, fork, reconnect, receive messages again...
            $self->receive(count => 1);
        }
        catch (Kanopya::Exception::MessageQueuing::NoMessage $err) {
            # Pass, the receiver has probably been woken up by a signal to stop the daemon. 
        }
        catch (Kanopya::Exception::MessageQueuing::ChannelError $err) {
            if ($self->isRunning) {
                $log->error($err);
                # Channel error, exiting...
                $self->setRunning(running => 0);
            }
        }
        catch ($err) {
            $log->error($err);
        }

        # Create the internal consumers again as the connection could be closed
        $self->createInternalConsumers();
    }

    # Send the TERM signal to ask it to stop fetching after a possible current job.
    for my $instance (@{ $self->_instances }) {
        # Sending TERM signal to the child
        $instance->kill(15);
    }

    # Wait for childs termination
    $log->info("Daemon $self->{name} stopped, waiting for childs...");
    if (scalar(@watchers)) {
        $condvar->recv;
    }
    $log->debug("Daemon $self->{name} stopped, all childs finished...");
}


=pod
=begin classdoc

Spawn a child instance for a given callback definition

@param cbname the name of the callback definition to control

=end classdoc
=cut

sub spawnInstance {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'cbname' ]);

    my $callbackdef = $self->_callbacks->{$args{cbname}};

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
        try {
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

                # Create the consumer for the current callback
                $self->createConsumer(cbname => $args{cbname});

                # Retrigger a message defined
                if (defined $publish_error) {
                    $log->info("Retriggering undelivred message on <" . $publish_error->queue . ">");
                    $self->_component->send(queue => $publish_error->queue, %{ $publish_error->body });
                    $publish_error = undef;
                }

                # Continue to fetch while duration not expired
                try {
                    $self->receive(duration => $callbackdef->{duration});
                }
                catch (Kanopya::Exception::MessageQueuing::NoMessage $err) {
                    # Pass, no message received for duration
                }
                catch (Kanopya::Exception::MessageQueuing::PublishFailed $err) {
                    # If a publish error occurs, keep the undelivred message body
                    # to retrigger it at reconnection.
                    $publish_error = $err;
                    if ($self->isRunning) {
                        $log->error("Fetch on $message failed: $err");
                    }
                }
                catch ($err) {
                    if ($self->isRunning) {
                        $log->error("Fetch on $message failed: $err");
                    }
                }
                # Disconnect the child from the broker
                $self->disconnect();
            }
        }
        catch ($err) {
            $log->info("Child process <$$> failed: $err");
        }

        $log->info("Child process <$$> stop waiting $message, exiting.");
        exit 0;
    });

    # Spwan the job in a child and return the instance.
    return $job->run;
}


=pod
=begin classdoc

Callback to controle the daemon remotly. Allow to spawn/terminate child instances.

@param cbname the name of the callback definition to control
@param control the control type (spawn|kill)

@optional instances the number of instance to control

=end classdoc
=cut

sub controlDaemon {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'cbname', 'control', 'ack_cb' ],
                         optional => { 'instances' => 1 });

    $log->info("Control received of type <$args{control}> for callback <$args{cbname}>");

    # Execute the job corresponding to the control code
    switch ($args{control}) {
        case "spawn" {
            # Acknowledge the message now as we will disconnect 
            $args{ack_cb}->();

            # Disconnect from broker as we want to fork without openned connections
            $self->disconnect();

            # Create the specified number of instance of the worker/subscriber
            for (1 .. $args{instances}) {
                # Spwan the job
                my $job = $self->spawnInstance(cbname => $args{cbname});

                # Keep the job ref to be able to kill it further
                push @{ $self->_instances(cbname => $args{cbname}) }, $job;

                # Increase the condvar for each child
                $condvar->begin;

                # Define a callback that decrease the condvar at child exit
                my $exitcb = sub {
                    my ($pid, $status) = @_;
                    $log->info("Child process <$pid> exiting with status $status.");

                    # Decrease the condvar for to ensure the daemon tarmination
                    $condvar->end;

                    # If set by the controlDaemon method at instance kill,
                    # unset the condition variable as the parent process will
                    # send SIGTERM to the child instance to kill, then wait on
                    # the $killcondvar condition variable to wait the complete
                    # child termination and then execute the callback set on the child
                    # termination within the event loop when calling $killcondvar->recv.
                    if (defined $killcondvar && ! $killcondvar->ready) {
                        $killcondvar->send;
                    }
                };
                push @watchers, AnyEvent->child(pid => $job->child_pid, cb => \&$exitcb);
            }

            # Reconnect to the broker
            $self->connect();

            # Do not ack the message has it has been done before disconnecting.
            return 0;
        }
        case "kill" {
            # Kill the specified number of instance of the worker/subscriber
            for (1 .. $args{instances}) {
                my $instance = pop @{ $self->_instances(cbname => $args{cbname}) };
                if (! defined $instance) {
                    throw Kanopya::Exception::Internal::NotFound(
                        error => "No more running instance for callback $args{cbname}"
                    );
                }
                # Set a condition variable to wait the complete child termination
                $killcondvar = AnyEvent->condvar;

                # Sending TERM signal to the child
                $instance->kill(15);

                # Blonking call, allow to trigger the executon of the child termination
                # callback in the event loop. This condition variable is unset by the
                # child termination callback it self, that unlock the parent process.
                $killcondvar->recv;
            }

            # Ack the message
            return 1;
        }
        else {
            throw Kanopya::Exception::Internal::IncorrectParam(
                error => "Param <control> must be (spawn|kill), not <$args{control}>"
            );
        }
    }
}


=pod
=begin classdoc

Purge the queue. Override the parent method to connect if not donne.

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

Return the registred callbacks infos.

=end classdoc
=cut

sub _callbacks {
    my ($self, %args) = @_;
    my $class = ref($self) || $self;

    if (not defined $self->{_callbacks}) {
        $self->{_callbacks} = {};

        my @supers = Class::ISA::self_and_super_path($class);
        for my $super (@supers) {
            if ($super->can('getCallbacks')) {
                $self->{_callbacks} = $merge->merge(clone($super->getCallbacks()), $self->{_callbacks});
            }
        }
    }
    return $self->{_callbacks};
}


=pod
=begin classdoc

Return/instanciate the instances private member

=end classdoc
=cut

sub _instances {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, optional => { 'cbname' => undef });

    # If no callback definition name specified, return all instances. 
    if (! defined $args{cbname}) {
        my @allinstances;
        for my $instances (values %{($self->{_instances} || {})}) {
            @allinstances = (@allinstances, @{ $instances });
        }
        return \@allinstances;
    }

    # Return the callback definition instances instead.
    return $self->{_instances}->{$args{cbname}} if defined $self->{_instances}->{$args{cbname}};

    $self->{_instances}->{$args{cbname}} = [];
    return $self->{_instances}->{$args{cbname}};
}

1;
