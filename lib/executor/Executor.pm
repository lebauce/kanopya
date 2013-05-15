#    Copyright © 2011-2013 Hedera Technology SAS
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

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

=pod
=begin classdoc

The execution daemon, fetch actions from the following messages queues:
 - 'operation'        : Execute a single operation and push the result on the queue 'operation_result',
 - 'operation_result' : Handle an operation result, continue, finish or cancel workflows according to
                        the last operation result and the state of the workflow,
 - 'workflow'         : Run a specified workflow., push the first operation.

@since    2013-May-14
@instance hash
@self     $self

=end classdoc
=cut

package Executor;
use base Daemon::MessageQueuing;

use strict;
use warnings;

use General;
use Message;

use Entity::Workflow;
use Entity::Operation;
use EEntity::EOperation;

use AnyEvent;
use XML::Simple;
use Data::Dumper;


use Log::Log4perl "get_logger";
use Log::Log4perl::Layout;
use Log::Log4perl::Appender;

my $log = get_logger("");


=pod
=begin classdoc

@constructor

Instanciate an execution daemon, bind callback methods to the corresponing queues.

@optional duration force the duration while awaiting messages.

@return the executor instance

=end classdoc
=cut

sub new {
    my ($class, %args) = @_;

    General::checkParams(args => \%args, optional => { "duration" => undef });

    my $self = $class->SUPER::new(confkey => 'executor');

    # Keep the ref of the timers triggered for reported operations
    $self->{timerrefs} = {};

    # Force the duration if defined
    my $duration = {};
    if (defined $args{duration}) {
        $duration->{duration} = $args{duration};
    }

    # Bind channels on callbacks
    my $callbacks = { 'operation'        => \&executeOperation,
                      'operation_result' => \&handleResult,
                      'workflow'         => \&runWorkflow };

    # Register the callback for used channels
    for my $channel (keys %$callbacks) {
        my $callback = sub {
            my %cbargs = @_;
            my $ack = 0;
            eval {
                $ack = $callbacks->{$channel}->($self, %cbargs);
            };
            if ($@) { $self->log(level => 'error', msg => "$@"); }
            return $ack;
        };
        $self->registerWorker(channel => $channel, callback => \&$callback, %$duration);
    }

    return $self;
}


=pod
=begin classdoc

Wait messages on the channel 'workflow', set the workflow as running
and push the first operation on the channel 'operation'.

@param workflow_id the id of the workflow to run.

=end classdoc
=cut

sub runWorkflow {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'workflow_id' ]);

    my $workflow = EEntity->new(entity => Entity::Workflow->get(id => $args{workflow_id}));

    # Log in the proper file
    $self->setLogAppender(workflow => $workflow);

    # Set the workflow as running
    $workflow->setState(state => 'running');

    # Pop the first operation
    my $first;
    eval {
        $first = $workflow->getNextOperation();
    };
    if ($@) {
        $self->log(level => 'warn', msg => "$@");
        $workflow->finish();
    }
    else {
        $self->log(
            level => 'info',
            msg   => "Running " . $workflow->workflow_name . " workflow <" . $workflow->id . "> "
        );
        $self->log(
            level => 'info',
            msg   => "Executing " . $workflow->workflow_name . " first operation <" . $first->id . ">"
        );

        # Push the first operation on the execution channel
        $self->_component->execute(operation_id => $first->id);
    }

    # Acknowledge the message
    return 1;
}


=pod
=begin classdoc

Wait messages on the channel 'operation', execute the operation
and push the result on the queue 'operation_result'.

@param operation_id the id of the operation to execute.

=end classdoc
=cut

sub executeOperation {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ "operation_id" ]);

    my $operation;
    eval {
        $operation = EEntity::EOperation->new(
                         operation => Entity::Operation->get(id => $args{operation_id})
                     );
    };
    if ($@) {
        # The operation does not exists, probably due to a workflow cancel
        $self->log(
            level => 'warn',
            msg   => "Operation <$args{operation_id}> does not exists, skipping."
        );
    }

    # Log in the proper file
    $self->setLogAppender(workflow => $operation->workflow);

    $self->logWorkflowState(operation => $operation);
    Message->send(from    => 'Executor',
                  level   => 'info',
                  content => "Operation Processing [$operation]...");

    # Check parameters
    eval {
        $self->log(level => 'info', msg => "Step <check>");
        $operation->check();
    };
    if ($@) {
        my $err = $@;
        return $self->terminateOperation(operation => $operation,
                                         status    => 'cancelled',
                                         exception => $err);
    }

    # Validate the operation
    my $valid;
    eval {
        $self->log(level => 'info', msg => "Step <validation>");
        $valid = ($operation->state eq 'validated') ? 1 : $operation->validation();
    };
    if ($@) {
        my $err = $@;
        return $self->terminateOperation(operation => $operation,
                                         status    => 'cancelled',
                                         exception => $err);
    }
    # Terminate if the operation require validation
    if (not $valid) {
        return $self->terminateOperation(operation => $operation,
                                         status    => 'waiting_validation');
    }

    # Skip the proccessing steps if postreported
    my $delay;
    if ($operation->state ne 'postreported') {
        # Check preconditions for processing
        eval {
            $self->log(level => 'info', msg => "Step <prerequisites>");
            $delay = $operation->prerequisites();
        };
        if ($@) {
            my $err = $@;
            return $self->terminateOperation(operation => $operation,
                                             status    => 'cancelled',
                                             exception => $err);
        }
        # Report the operation if delay is set
        if ($delay) {
            return $self->terminateOperation(operation => $operation,
                                             status    => 'prereported',
                                             time      => time + $delay);
        }

        # Set the operation as proccessing
        $operation->setState(state => 'processing');

        # Process the operation
        eval {
            $operation->beginTransaction;

            $self->log(level => 'info', msg => "Step <prepare>");
            $operation->prepare();

            $self->log(level => 'info', msg => "Step <process>");
            $operation->process();

            $operation->commitTransaction;
        };
        if ($@) {
            my $err = $@;
            # If some rollback defined, undo them
            if (defined $operation->{erollback}) {
                $operation->{erollback}->undo();
            }
            # Rollback transaction
            $operation->rollbackTransaction;

            return $self->terminateOperation(operation => $operation,
                                             status    => 'cancelled',
                                             exception => $err);
        }
    }

    $self->log(level => 'info', msg => "Step <postrequisites>");
    eval {
         $delay = $operation->postrequisites();
    };
    if ($@) {
        my $err = $@;
        return $self->terminateOperation(operation => $operation,
                                         status    => 'cancelled',
                                         exception => $err);
    }
    # Report the operation if delay is set
    if ($delay) {
        return $self->terminateOperation(operation => $operation,
                                         status    => 'postreported',
                                         time      => time + $delay);
    }

    # Finishing the operation.
    eval {
        $self->log(level => 'info', msg => "Step <finish>");
        $operation->finish();
    };
    if ($@) {
        my $err = $@;
        return $self->terminateOperation(operation => $operation,
                                         status    => 'cancelled',
                                         exception => $err);
    }

    # Terminate the operation with success
    return $self->terminateOperation(operation => $operation,
                                     status    => 'succeeded');
}


=pod
=begin classdoc

Wait messages on the channel 'operation_result', and trigger the correponding job:
 - operation succeeded : continue or finish the workflow,
 - operation reported  : trigger a timer that will re-push the operation at the proper time,
 - operation cancelled : cancel the workflow.

@param operation_id the id of the terminated operation.
@param status the state of the execution of the operation.

=end classdoc
=cut

sub handleResult {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'operation_id', 'status' ]);

    my $operation;
    eval {
        $operation = EEntity::EOperation->new(
                         operation      => Entity::Operation->get(id => $args{operation_id}),
                         skip_not_found => 1
                     );
    };
    if ($@) {
        # The operation does not exists, probably due to a workflow cancel
        $self->log(
            level => 'warn',
            msg   => "Operation <$args{operation_id}> does not exists, skipping."
        );
        return 1;
    }

    my $workflow = EEntity->new(entity => $operation->workflow);

    # Log in the proper file
    $self->setLogAppender(workflow => $workflow);

    # Set the operation state
    $operation->setState(state => $args{status});

    # Operation succeeded
    if ($args{status} eq 'succeeded') {
        $self->logWorkflowState(operation => $operation, state => 'SUCCEED');

        Message->send(from    => 'Executor',
                      level   => 'info',
                      content => "[$operation] Execution Success");

        # Continue the workflow
    }
    # Operation reported
    elsif ($args{status} eq 'prereported' or $args{status} eq 'postreported'){

        General::checkParams(args => \%args, optional => { 'time' => undef });

        # The operation execution is reported at $args{time}
        if (defined $args{time}) {
            $self->logWorkflowState(operation => $operation, state => 'REPORTED');

            # Compute the delay
            my $delay = $args{time} - time;

            # If the hoped execution time is in the future, report the operation 
            if ($delay > 0) {
                # Update the hoped excution time of the operation
                $operation->report(duration => $delay);

                # Re-trigger the operation at proper time
                my $report_cb = sub {
                    # Re-execute the operation
                    $self->_component->execute(operation_id => $operation->id);

                    # Acknowledge the message as the operation result is finally handled
                    $args{acknowledge_cb}->();
                };
                # Keep the timer ref
                $self->{timerrefs}->{$operation->id} = AnyEvent->timer(after => $delay, cb => $report_cb);

                # Do not acknowledge the message as it will be done by the timer.
                # If the current proccess die while some timers still active,
                # the operation result will be automatically re-enqueued.
                return 0;
            }
            else {
                # Re-trigger the operation now
                $self->_component->execute(operation_id => $operation->id);

                # Stop the workflow for now
                return 1;
            }
        }
        # The operation is indefinitely reported, execution is delegated to the workflow
        else {
            $operation->setState(state => 'pending');

            # Continue the workflow
        }
    }
    # Operation required validation
    elsif ($args{status} eq 'waiting_validation') {
        $self->logWorkflowState(operation => $operation, state => 'WAITING VALIDATION');

        # TODO: Probably better to send notification for validation here,
        #       instead of at validation time (cf. executeOperation)

        # Stop the workflow
        return 1;
    }
    # Operation is validated
    elsif ($args{status} eq 'validated') {
        $self->logWorkflowState(operation => $operation, state => 'VALIDATED');

        # Re-trigger the operation now
        $self->_component->execute(operation_id => $operation->id);

        # Stop the workflow
        return 1;
    }
    # Operation failed
    elsif ($args{status} eq 'cancelled') {

        General::checkParams(args => \%args, optional => { 'exception' => undef });

        $self->logWorkflowState(operation => $operation, state => 'FAILED');
        $self->log(level => 'error', msg => $args{exception});

        Message->send(from    => 'Executor',
                      level   => 'error',
                      content => "[$operation] Execution Aborted : $args{exception}");

        # Try to cancel all workflow operations, and delete them.
        $self->log(
            level => 'info',
            msg   => "Cancelling " . $workflow->workflow_name . " workflow <" . $workflow->id . ">"
        );
        $workflow->cancel();

        # Stop the workflow
        return 1;
    }

    # Compute the workflow status, push the next op if there is remaining one(s),
    # finish the workflow instead.
    my $next;
    eval {
        $next = $workflow->prepareNextOperation(current => $operation);
    };
    if ($@) {
        my $err = $@;
        if (not $err->isa('Kanopya::Exception::Internal::NotFound')) {
            $err->rethrow();
        }

        # No remaning operation
        $self->log(
            level => 'info',
            msg   => "Finishing " . $workflow->workflow_name . " workflow <" . $workflow->id . ">"
        );
        $workflow->finish();
    }
    else {
        $self->log(
            level => 'info',
            msg   => "Executing " . $workflow->workflow_name . " next operation <" . $next->id . ">"
        );

        # Set the operation as ready
        $next->setState(state => 'ready');

        # Push the next operation on the execution channel
        $self->_component->execute(operation_id => $next->id);
    }

    # Acknowledge the message
    return 1;
}


=pod
=begin classdoc

Push a result on the channel 'operation_result'. Also serialize
the terminated operation parameters.

@param operation the terminated operation.
@param status the state of the execution of the operation.

=end classdoc
=cut

sub terminateOperation {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'operation', 'status' ]);

    my $operation = delete $args{operation};

    $self->log(level => 'info', msg => "Operation terminated with status <$args{status}>");

    # Serialize the parameters as its could be modified during
    # the operation executions steps.
    my $params = delete $operation->{params};
    $params->{context} = delete $operation->{context};
    $operation->serializeParams(params => $params);

    if (defined $args{exception} and ref($args{exception})) {
        $args{exception} = "$args{exception}";
    }

    # Produce a result on the operation_result channel
    $self->_component->terminate(operation_id => $operation->id, %args);

    # Acknowledge the message
    return 1;
}


=pod
=begin classdoc

Set the log appender to log in the workflow specific log file.

@param workflow the workflow to identify the log file

=end classdoc
=cut

sub setLogAppender {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'workflow' ]);

    if (exists Log::Log4perl->appenders()->{'workflow'}) {
        $log->eradicate_appender('workflow');
    }

    my $appender = Log::Log4perl::Appender->new("Log::Dispatch::File",
                       name      => "workflow",
                       filename  => $self->{config}->{logdir} . "workflows/" . $args{workflow}->id . ".log"
                   );

    $appender->layout(Log::Log4perl::Layout::PatternLayout->new("%d %c %p> %M - %m%n"));
    $log->add_appender($appender);
}


=pod
=begin classdoc

Log the workflow state.

@param operation the just terinated operation of the workflow
@param state the state of the workflow

=end classdoc
=cut

sub logWorkflowState {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'operation' ],
                         optional => { 'state' => '' });

    my $msg = $args{operation}->type . " <" . $args{operation}->id . "> " . $args{state};
    $self->log(level => 'info', msg => "---- [ Operation " . $msg . " ] ----");
}

1;
