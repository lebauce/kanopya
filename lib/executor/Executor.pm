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
use Kanopya::Config;
use Kanopya::Exceptions;
use Administrator;
use EFactory;
use Operation;
use EWorkflow;
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

    my $adm = Administrator::authenticate(
                  login    => $self->{config}->{user}->{name},
                  password => $self->{config}->{user}->{password}
              );

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
    my $adm = Administrator->new();

    my $operation = Operation->getNextOp(include_blocked => $self->{include_blocked});

    my ($op, $opclass, $workflow, $delay, $logprefix);
    if ($operation){
        $log->info("\n\n");
        $workflow = EWorkflow->new(data => $operation->getWorkflow, config => $self->{config}) ;
        my $workflow_name = $workflow->getAttr(name => 'workflow_name');
        $workflow_name = defined $workflow_name ? $workflow_name : 'Anonymous';
        my $workflow_id = $workflow->getAttr(name => 'workflow_id');
        
        # init log appender for this workflow if this one is not the same as the last executed
        if($workflow_id != $self->{last_workflow_id}) {
            my $appenders = Log::Log4perl->appenders();
        
            if(exists $appenders->{'WORKFLOW'}) {
                $log->eradicate_appender('WORKFLOW');
            }    
        
            my $layout = Log::Log4perl::Layout::PatternLayout->new("%d %c %p> %M - %m%n");
            my $file_appender = Log::Log4perl::Appender->new(
                              "Log::Dispatch::File",
                              name      => "WORKFLOW",
                              filename  => $self->{config}->{logdir}."workflows/$workflow_id.log");
            $file_appender->layout($layout);
            $log->add_appender($file_appender);
            $self->{last_workflow_id} = $workflow_id;
        }


        # Initialize EOperation and context
        eval {
            $op = EFactory::newEOperation(op => $operation, config => $self->{config});
            $opclass = ref($op);
            my $op_type = $op->getAttr(name => 'type');
            my $op_id = $op->getAttr(name => 'operation_id');
            $logprefix = "[$workflow_name workflow <$workflow_id> -";
            $logprefix .= " Operation $op_type <$op_id>]";

            $log->info("---- $logprefix ----");
            Message->send(
                from    => 'Executor',
                level   => 'info',
                content => "Operation Processing [$opclass]..."
            );

            $log->info("Check step");
            $op->check();
        };
        if ($@) {
            $log->error("$opclass context initilisation failed:$@");

            # Probably a compilation error on the operation class.
            $log->info("Cancelling $workflow_name workflow <$workflow_id>");
            $workflow->cancel(config => $self->{config});
            return;
        }

        # Try to lock the context to check if entities are locked by others workflow
        eval {
            $log->debug("Locking context for $opclass");
            $operation->lockContext();

            if ($op->getAttr(name => 'state') eq 'blocked') {
                $op->setState(state => 'ready');
            }
        };
        if ($@) {
            $op->setState(state => 'blocked');

            $log->info("---- [$opclass] Unable to get locks, skip. ----");

            # Unset the option include_blocked, to avoid
            # fetching this operation at the next loop.
            $self->{include_blocked} = 0;
            return;
        }

        # Process the operation
        eval {
            # Start transaction for prerequisite/postrequisite
            $adm->{db}->txn_begin;

            # If the operation never been processed, check its prerequisite
            if ($op->getAttr(name => 'state') eq 'ready' or
                $op->getAttr(name => 'state') eq 'prereported') {

                $log->info("Prerequisites step");
                $delay = $op->prerequisites();

                # If the prerequisite are validated, process the operation
                if (not $delay) {
                    $op->setState(state => 'processing');

                    $adm->{db}->txn_commit;

                    # Start transaction for processing
                    $adm->{db}->txn_begin;

                    $log->info("Prepare step");
                    $op->prepare();

                    $log->info("Process step");
                    $op->process();
                }
            }

            # If the operation has been processed, check its postrequisite
            if ($op->getAttr(name => 'state') eq 'processing' or
                $op->getAttr(name => 'state') eq 'postreported') {

                $log->info("Postrequisites step");
                $delay = $op->postrequisites();
            }

            # Report the operation if required
            if ($delay) {
                # Update the context with possibles newly set params
                $op->{params}->{context} = $op->{context};
                $op->setParams(params => $op->{params});

                $op->report(duration => $delay);

                if ($op->getAttr(name => 'state') eq 'ready') {
                    $op->setState(state => 'prereported');
                }
                elsif ($op->getAttr(name => 'state') eq 'processing') {
                    $op->setState(state => 'postreported');
                }

                $adm->{db}->txn_commit;
                
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

            $log->info("$opclass rollback processing");
            $op->{erollback}->undo();

            # Rollback transaction
            $adm->{db}->txn_rollback;

            # Cancelling the workflow
            eval {
#                # Unlock the entities as the workflow will be cancelled
#                $workflow->unlockContext();

#                $adm->{db}->txn_begin;

                # Try to cancel all workflow operations, and delete them.
                # Context entities will be unlocked by this call
                $log->info("Cancelling $workflow_name workflow $workflow_id");
                $workflow->cancel(config => $self->{config});

#                $adm->{db}->txn_commit;
            };
            if ($@){
                my $err_rollback = $@;
                $log->error("Workflow cancel failed:$err_rollback");
            }
            
            if (!(ref($err_exec) eq "HASH") or !$err_exec->{hidden}){
                Message->send(
                    from    => 'Executor',
                    level   => 'error',
                    content => "[$opclass] Execution Aborted : $err_exec"
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
            $adm->{db}->txn_commit;

            $log->info("---- $logprefix Processing SUCCEED ----");
            Message->send(
                from    => 'Executor',
                level   => 'info',
                content => "[$opclass] Execution Success"
            );

            # Unlock the context to update it.
            eval {
                $log->debug("Unlocking context for $opclass");
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
