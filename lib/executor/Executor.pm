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
my $log = get_logger("executor");

our $VERSION = '1.00';

=head2 new

    my $executor = Executor->new();

Executor::new creates a new executor object.

=cut

sub new {
    my $class = shift;
    my $self = {};

    bless $self, $class;

    $self->{config} = Kanopya::Config::get('executor');

    General::checkParams(args => $self->{config}->{user}, required => [ "name", "password" ]);

    my $adm = Administrator::authenticate(
                  login    => $self->{config}->{user}->{name},
                  password => $self->{config}->{user}->{password}
              );

    $self->{include_blocked} = 1;

    return $self;
}

=head2 run

Executor->run() run the executor server.

=cut

sub run {
    my $self = shift;
    my $running = shift;
    
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
    my $self = shift;
    my $adm = Administrator->new();

    my $operation = Operation->getNextOp(include_blocked => $self->{include_blocked});

    my ($op, $opclass, $workflow, $delay, $errors);
    if ($operation){
        $workflow = EWorkflow->new(data => $operation->getWorkflow, config => $self->{config}) ;

        # Initialize EOperation and context
        eval {
            $op = EFactory::newEOperation(op => $operation, config => $self->{config});
            $opclass = ref($op);

            $log->info("---- [$opclass] retrieved ; execution processing ----");
            Message->send(
                from    => 'Executor',
                level   => 'info',
                content => "Operation Processing [$opclass]..."
            );

            $log->debug("Calling check of operation $opclass.");
            $op->check();
        };
        if ($@) {
            $log->error("Error during operation context initilisation:\n$@");

            # Probably a compilation error on the operation class.
            $workflow->ecancel(config => $self->{config});
            next;
        }

        # Try to lock the context to check if entities are locked by others workflow
        eval {
            $log->debug("Calling lock of operation $opclass.");
            $workflow->lockContext();

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
            next;
        }

        # Process the operation
        eval {
            # Start transaction for prerequisite/postrequisite
            $adm->{db}->txn_begin;

            # If the operation never been processed, check its prerequisite
            if ($op->getAttr(name => 'state') eq 'ready' or
                $op->getAttr(name => 'state') eq 'prereported') {

                $log->debug("Calling prerequisite of operation $opclass.");
                $delay = $op->prerequisites();

                # If the prerequisite are validated, process the operation
                if (not $delay) {
                    $op->setState(state => 'processing');

                    $adm->{db}->txn_commit;

                    # Start transaction for processing
                    $adm->{db}->txn_begin;

                    $log->debug("Calling prepare of operation $opclass.");
                    $op->prepare();

                    $log->debug("Calling execute of operation $opclass.");
                    $op->process();
                }
            }

            # If the operation has been processed, check its postrequisite
            if ($op->getAttr(name => 'state') eq 'processing' or
                $op->getAttr(name => 'state') eq 'portreported') {

                $log->debug("Calling postrequisite of operation $opclass.");
                $delay = $op->postrequisites();
            }

            # Report the operation if required
            if ($delay) {
                $op->report(duration => $delay);

                if ($op->getAttr(name => 'state') eq 'ready') {
                    $op->setState(state => 'prereported');
                }
                elsif ($op->getAttr(name => 'state') eq 'processing') {
                    $op->setState(state => 'postreported');
                }

                $adm->{db}->txn_commit;
                $log->info("---- [$opclass] Execution reported ($delay s.) ----");
                next;
            }
        };
        if ($@) {
            my $err_exec = $@;

            # Rollback transaction
            $adm->{db}->txn_rollback;
            $log->info("Rollback, Cancel workflow will be call");

            # Cancelling the workflow
            eval {
                # Unlock the entities as the workflow will be cancelled
                $workflow->unlockContext();

                $adm->{db}->txn_begin;

                # Try to cancel all workflow operations, and delete them.
                $workflow->ecancel(config => $self->{config});

                $adm->{db}->txn_commit;
            };
            if ($@){
                my $err_rollback = $@;
                $log->error("Error during workflow cancel :\n$err_rollback");

                $errors .= $err_rollback;
            }
            if (!($err_exec =~ /HASH/) or !$err_exec->{hidden}){
                Message->send(
                    from    => 'Executor',
                    level   => 'error',
                    content => "[$opclass] Execution Aborted : $err_exec"
                );
                $log->error("Error during execution : $err_exec");
            }
            else {
                $log->info("Warning : $err_exec");
            }
            $errors .= $err_exec;
        }
        else {
            # Finishing the operation.
            eval {
                $op->finish();
            };
            if ($@) {
                my $err_finish = $@;
                $log->error("Error during operation finish :\n$err_finish");

                $errors .= $err_finish;
            }

            # Commit transaction
            $adm->{db}->txn_commit;

            $log->info("---- [$opclass] Execution succeed ----");
            Message->send(
                from    => 'Executor',
                level   => 'info',
                content => "[$opclass] Execution Success"
            );

            # Unlock the context to update it.
            eval {
                $workflow->unlockContext();
            };
            if ($@) {
                my $err_unlock = $@;
                $log->error("Error during context unlock :\n$err_unlock");

                $errors .= $err_unlock;
            }

            eval {
                # Update the workflow context
                $workflow->pepareNextOp(context => $op->{context}, params => $op->{params});

                # If the workflow isn't finished, lock the context
                # to protect entities from other workflows.
                if ($workflow->getAttr(name => 'state') eq 'running') {
                    $workflow->lockContext();
                }
            };
            if ($@) {
                my $err_prepare = $@;
                $log->error("Error during workflow prepare :\n$err_prepare");

                $errors .= $err_prepare;
            }
        }

        # Set the option include_blocked, to check if blocked operation can get locks
        # as the just finished operation probably free some locks.
        $self->{include_blocked} = 1;
    }
    else {
        sleep 2;
    }

    if (defined $errors) {
        throw Kanopya::Exception::Execution(error => $errors);
    };
}

=head2 execnrun

Executor->execnround((run => $nbrun)) run the executor server for only one round.

=cut

sub execnround {
    my $self = shift;
    my %args = @_;

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
