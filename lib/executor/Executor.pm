# Executor.pm - Object class of Executor server

#    Copyright © 2011 Hedera Technology SAS
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
# Created 14 july 2010


=head1 NAME

<Executor> – <Executor main class>

=head1 VERSION

This documentation refers to <Executor> version 1.0.0.

=head1 SYNOPSIS

use <Executor>;


=head1 DESCRIPTION

Executor is the main execution class of executor service

=head1 METHODS

=cut

package Executor;

use strict;
use warnings;

use General;
use BaseDB;
use Kanopya::Config;
use Kanopya::Exceptions;
use EFactory;
use Entity::Operation;
use Message;

use XML::Simple;

use Data::Dumper;
use Log::Log4perl "get_logger";
use Log::Log4perl::Layout;
use Log::Log4perl::Appender;
my $log = get_logger("");

our $VERSION = '1.00';

=head2 new

    my $executor = Executor->new();

Executor::new creates a new executor object.

=cut

sub new {
    my ($class) = @_;
    my $self = {};

    bless $self, $class;

    $self->{config} = Kanopya::Config::get('executor');

    General::checkParams(args => $self->{config}->{user}, required => [ "name", "password" ]);

    BaseDB->authenticate(login    => $self->{config}->{user}->{name},
                         password => $self->{config}->{user}->{password});

    $self->{include_blocked} = 1;
    $self->{last_workflow_id} = -1;

    return $self;
}

=head2 run

Executor->run() run the executor server.

=cut

sub run {
    my ($self, $running) = @_;

    Message->send(
        from    => 'Executor',
        level   => 'info',
        content => "Kanopya Executor started."
    );

    while ($$running) {
        $self->execnround(run => 1);
    }

    Message->send(
        from    => 'Executor',
        level   => 'warning',
        content => "Kanopya Executor stopped"
    );
}

sub oneRun {
    my ($self) = @_;

    my $operation = Entity::Operation->getNextOp(include_blocked => $self->{include_blocked});

    my ($op, $workflow, $delay, $logprefix);
    if ($operation){
        $log->info("\n\n");

        $workflow = EFactory::newEEntity(data => $operation->getWorkflow);

        # init log appender for this workflow if this one is not the same as the last executed
        if($workflow->id != $self->{last_workflow_id}) {
            my $appenders = Log::Log4perl->appenders();

            if(exists $appenders->{'WORKFLOW'}) {
                $log->eradicate_appender('WORKFLOW');
            }
            my $layout = Log::Log4perl::Layout::PatternLayout->new("%d %c %p> %M - %m%n");
            my $file_appender = Log::Log4perl::Appender->new(
                                    "Log::Dispatch::File",
                                    name      => "WORKFLOW",
                                    filename  => $self->{config}->{logdir} . "workflows/" . $workflow->id . ".log"
                                );

            $file_appender->layout($layout);
            $log->add_appender($file_appender);
            $self->{last_workflow_id} = $workflow->id;
        }

        # Initialize EOperation and context
        eval {
            $op = EFactory::newEOperation(op => $operation);
            $logprefix = "[" . $workflow->workflow_name . " workflow <" . $workflow->id .
                         "> - Operation " . $op->type  . " <" . $op->id . ">]";

            $log->info("---- $logprefix ----");
            Message->send(
                from    => 'Executor',
                level   => 'info',
                content => "Operation Processing [$op]..."
            );

            $log->info("Check step");
            $op->check();
        };
        if ($@) {
            $log->error("$op context initilisation failed:$@");

            # Probably a compilation error on the operation class.
            $log->info("Cancelling " . $workflow->workflow_name . " workflow <" . $workflow->id . ">");
            $workflow->cancel(config => $self->{config}, state => 'failed');
            return;
        }

        # Try to lock the context to check if entities are locked by others workflow
        if ($op->state eq 'validated') {
            $op->setState(state => 'ready');
        }
        else {
            $log->debug("Calling validation of operation $op.");

            if (not $op->validation()) {
                $op->setState(state => 'waiting_validation');

                $log->info("---- [$op] Operation waiting validation. ----");
                return;
            }
        }

        # Try to lock the context to check if entities are locked by others workflow
        eval {
            $log->debug("Locking context for $op");
            $operation->lockContext();

            if ($op->state eq 'blocked') {
                $op->setState(state => 'ready');
            }
        };
        if ($@) {
            my $message = $@;
            $op->setState(state => 'blocked');

            $log->info("---- [$op] Unable to get locks, skip. ----");
            $log->debug($message);

            # Unset the option include_blocked, to avoid
            # fetching this operation at the next loop.
            $self->{include_blocked} = 0;
            return;
        }

        # Process the operation
        eval {
            # Start transaction for prerequisite/postrequisite
            $operation->beginTransaction;

            # If the operation never been processed, check its prerequisite
            if ($op->state eq 'ready' or $op->state eq 'prereported') {

                $log->info("Prerequisites step");
                $delay = $op->prerequisites();

                # If the prerequisite are validated, process the operation
                if ($delay == 0) {
                    $op->setState(state => 'processing');

                    $operation->commitTransaction;

                    # Start transaction for processing
                    $operation->beginTransaction;

                    $log->info("Prepare step");
                    $op->prepare();

                    $log->info("Process step");
                    $op->process();
                }
            }

            # If the operation has been processed, check its postrequisite
            if ($op->state eq 'processing' or $op->state eq 'postreported') {

                $log->info("Postrequisites step");
                $delay = $op->postrequisites();
            }

            # Report the operation if required
            if ($delay != 0) {
                if ($delay < 0) {
                    $op->setState(state => 'pending');
                }
                else {
                    # Update the context with possibles newly set params
                    $op->{params}->{context} = $op->{context};
                    $op->setParams(params => $op->{params});
    
                    $op->report(duration => $delay);
    
                    if ($op->state eq 'ready') {
                        $op->setState(state => 'prereported');
                    }
                    elsif ($op->state eq 'processing') {
                        $op->setState(state => 'postreported');
                    }
                }
                $operation->commitTransaction;

                throw Kanopya::Exception::Execution::OperationReported(error => 'Operation reported');
            }
        };
        if ($@) {
            my $err_exec = $@;

            if ($err_exec->isa('Kanopya::Exception::Execution::OperationReported')) {
                $log->info("--- $logprefix Processing REPORTED ($delay s.)");
                return;
            } else {
                $log->error("--- $logprefix Processing FAILED : $err_exec");
            }

            $log->info("$op rollback processing");
            if(defined $op->{erollback}) {
                $op->{erollback}->undo();
            }
            # Rollback transaction
            $operation->rollbackTransaction;

            # Cancelling the workflow
            eval {
                # Try to cancel all workflow operations, and delete them.
                # Context entities will be unlocked by this call
                $log->info("Cancelling " . $workflow->workflow_name . " workflow <" . $workflow->id . ">");
                $workflow->cancel(config => $self->{config}, state => 'failed');
            };
            if ($@){
                my $err_rollback = $@;
                $log->error("Workflow cancel failed:$err_rollback");
            }

            if (!(ref($err_exec) eq "HASH") or !$err_exec->{hidden}){
                Message->send(
                    from    => 'Executor',
                    level   => 'error',
                    content => "[$op] Execution Aborted : $err_exec"
                );
            }
            else {
                $log->info("Warning : $err_exec");
            }

        }
        else {
            # Finishing the operation.
            eval {
                $log->info("Finish step");
                $op->finish();
            };
            if ($@) {
                my $err_finish = $@;
                $log->error("Finish failed :$err_finish");
            }

            # Commit transaction
            $operation->commitTransaction;

            $log->info("---- $logprefix Processing SUCCEED ----");
            Message->send(
                from    => 'Executor',
                level   => 'info',
                content => "[$op] Execution Success"
            );

            # Unlock the context to update it.
            eval {
                $log->debug("Unlocking context for $op");
                $operation->unlockContext();
            };
            if ($@) {
                my $err_unlock = $@;
                $log->error("Context unlock failed:$err_unlock");
            }

            eval {
                # Update the workflow context
                $workflow->pepareNextOp(context => $op->{context}, params => $op->{params});
            };
            if ($@) {
                my $err_prepare = $@;
                $log->error("Error during workflow prepare :\n$err_prepare");
            }
        }

        # Set the option include_blocked, to check if blocked operation can get locks
        # as the just finished operation probably free some locks.
        $self->{include_blocked} = 1;
    }
    else {
        sleep 5;
    }
}

=head2 execnrun

Executor->execnround((run => $nbrun)) run the executor server for only one round.

=cut

sub execnround {
    my ($self, %args) = @_;

    while ($args{run}) {
        $args{run} -= 1;
        eval {
            $self->oneRun();
        };
        if ($@) {
            $log->error($@);
        }
    }
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
