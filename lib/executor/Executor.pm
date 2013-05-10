#    Copyright © 2011 Hedera Technology SAS
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

package Executor;
use base Daemon::MessageQueuing;

use strict;
use warnings;

use General;
use Message;

use Entity::Workflow;
use Entity::Operation;
use EEntity::EOperation;

use XML::Simple;
use Data::Dumper;

use Log::Log4perl "get_logger";
use Log::Log4perl::Layout;
use Log::Log4perl::Appender;

my $log = get_logger("");


sub new {
    my ($class) = @_;

    my $self = $class->SUPER::new(confkey => 'executor');

    $self->{timerrefs} = {};

    # Defined closures for callbacks
    my $execute = sub {
        my %args = @_;
        my $ack = 1;
        eval {
            $ack = $self->executeOperation(%args);
        };
        if ($@) { $log->error($@); }

        return $ack;
    };
    my $run = sub {
        my %args = @_;
        my $ack = 1;
        eval {
            $ack = $self->runWorkflow(%args);
        };
        if ($@) { $log->error($@); }

        return $ack;
    };
    my $handle = sub {
        my %args = @_;
        my $ack = 1;
        eval {
            $ack = $self->handleResult(%args);
        };
        if ($@) { $log->error($@); }

        return $ack;
    };

    # Register the callback for used channels
    $self->registerWorker(channel => 'operation', callback => \&$execute);
    $self->registerWorker(channel => 'workflow', callback => \&$run);
    $self->registerWorker(channel => 'operation_result', callback => \&$handle);

    return $self;
}

sub executeOperation {
    my ($self, %args) = @_;

    General::checkParams(args  => \%args, required => [ "operation_id" ]);

    my $operation;
    eval {
        $operation = EEntity::EOperation->new(
                         operation => Entity::Operation->get(id => $args{operation_id})
                     );
    };
    if ($@) {
        # The operation does not exists, probably due to a workflow cancel
        $log->warn("Operation <$args{operation_id}> does not exists, skipping.");
        return 1;
    }

    $log->info("---- [ Operation " . $operation->type  . " <" . $operation->id . "> ] ----");
    Message->send(from    => 'Executor',
                  level   => 'info',
                  content => "Operation Processing [$operation]...");

    # Initialize EOperation and context
    eval {
        $log->info("Step <check>");
        $operation->check();
    };
    if ($@) {
        # Probably a compilation error on the operation class.
        return $self->terminateOperation(operation => $operation,
                                         status    => 'cancelled',
                                         exception => $@);
    }

    # Check if the operation require validation.
#    if ($operation->state eq 'validated') {
#        $operation->setState(state => 'ready');
#    }
#    else {
#        $log->debug("Calling validation of operation $operation.");
#
#        if (not $operation->validation()) {
#            # Probably a compilation error on the operation class.
#            return $self->terminateOperation(operation => $operation,
#                                             status    => 'waiting_validation');
#        }
#    }

    # Skip the proccessing steps id postreported
    my $delay;
    if ($operation->state ne 'postreported') {
        # Check preconditions for processing
        eval {
            $log->info("Step <prerequisites>");
            $delay = $operation->prerequisites();
        };
        if ($@) {
            return $self->terminateOperation(operation => $operation,
                                             status    => 'cancelled',
                                             exception => $@);
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

            $log->info("Step <prepare>");
            $operation->prepare();

            $log->info("Step <process>");
            $operation->process();

            $operation->commitTransaction;
        };
        if ($@) {
            # If some rollback defined, undo them
            if (defined $operation->{erollback}) {
                $operation->{erollback}->undo();
            }
            # Rollback transaction
            $operation->rollbackTransaction;

            return $self->terminateOperation(operation => $operation,
                                             status    => 'cancelled',
                                             exception => $@);
        }
    }

    $log->info("Step <postrequisites>");
    eval {
         $delay = $operation->postrequisites();
    };
    if ($@) {
        return $self->terminateOperation(operation => $operation,
                                         status    => 'cancelled',
                                         exception => $@);
    }
    # Report the operation if delay is set
    if ($delay) {
        return $self->terminateOperation(operation => $operation,
                                         status    => 'postreported',
                                         time      => time + $delay);
    }

    # Finishing the operation.
    eval {
        $log->info("Step <finish>");
        $operation->finish();
    };
    if ($@) {
        return $self->terminateOperation(operation => $operation,
                                         status    => 'cancelled',
                                         exception => $@);
    }

    # Terminate the operation with success
    return $self->terminateOperation(operation => $operation,
                                     status    => 'succeeded');
}

sub terminateOperation {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'operation', 'status' ]);

    my $operation = delete $args{operation};

    $log->info("Operation terminated with status <$args{status}>");

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

sub runWorkflow {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'workflow_id' ]);

    my $workflow = EEntity->new(entity => Entity::Workflow->get(id => $args{workflow_id}));

    # Set the workflow as running
    $workflow->setState(state => 'running');

    # Pop the first operation
    my $first;
    eval {
        $first = $workflow->getNextOperation();
    };
    if ($@) {
        $log->warn($@);
        $workflow->finish();
    }
    else {
        $log->info("Running " . $workflow->workflow_name . " workflow <" . $workflow->id . "> ");
        $log->info("Executing " . $workflow->workflow_name . " first operation <" . $first->id . ">");
    
        # Push the first operation on the execution channel
        $self->_component->execute(operation_id => $first->id);
    }

    # Acknowledge the message
    return 1;
}

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
        $log->warn("Operation <$args{operation_id}> does not exists, skipping.");
        return 1;
    }

    my $workflow  = EEntity->new(entity => $operation->workflow);

    # Set the operation state
    $operation->setState(state => $args{status});

    # Operation succeeded
    if ($args{status} eq 'succeeded') {
        $log->info("---- [ Operation " . $operation->type . " <" . $operation->id . "> SUCCEED ] ----");

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
            $log->info("---- [ Operation " . $operation->type . " <" . $operation->id . "> REPORTED ] ----");

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
                }
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
    # Operation failed
    elsif ($args{status} eq 'cancelled') {

        General::checkParams(args => \%args, optional => { 'exception' => undef });

        $log->info("---- [ Operation " . $operation->type  . " <" . $operation->id . "> FAILED ] ----");
        $log->error($args{exception});

        Message->send(from    => 'Executor',
                      level   => 'error',
                      content => "[$operation] Execution Aborted : $args{exception}");

        # Try to cancel all workflow operations, and delete them.
        $log->info("Cancelling " . $workflow->workflow_name . " workflow <" . $workflow->id . ">");
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
        $log->info("Finishing " . $workflow->workflow_name . " workflow <" . $workflow->id . ">");
        $workflow->finish();
    }
    else {
        $log->info("Executing " . $workflow->workflow_name . " next operation <" . $next->id . ">");

        # Set the operation as ready
        $next->setState(state => 'ready');

        # Push the next operation on the execution channel
        $self->_component->execute(operation_id => $next->id);
    }

    # Acknowledge the message
    return 1;
}

1;

