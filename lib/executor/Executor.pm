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

use Log::Log4perl "get_logger";
our $VERSION = '1.00';
use General;
use Kanopya::Exceptions;
use Administrator;
use XML::Simple;
use Data::Dumper;
use EFactory;
use Operation;
use Message;

my $log = get_logger("executor");

=head2 new

    my $executor = Executor->new();

Executor::new creates a new executor object.

=cut

sub new {
    my $class = shift;
    my $self = {};

    bless $self, $class;

    $self->_init();

    return $self;
}

=head2 _init

Executor::_init is a private method used to define internal parameters.

=cut

sub _init {
    my $self = shift;
    
    $self->{config} = XMLin("/opt/kanopya/conf/executor.conf");

    General::checkParams(args => $self->{config}->{user}, required => [ "name", "password" ]);

    my $adm = Administrator::authenticate(
                  login    => $self->{config}->{user}->{name},
                  password => $self->{config}->{user}->{password}
              );

    return;
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
    my $errors;
    my $opdata = Operation::getNextOp();

    if ($opdata){
        my $op = EFactory::newEOperation(op => $opdata, config => $self->{config});
        my $workflow = $op->getWorkflow;

        my $opclass = ref($op);

        $log->info("---- [$opclass] retrieved ; execution processing ----");
        Message->send(
            from    => 'Executor',
            level   => 'info',
            content => "Operation Processing [$opclass]..."
        );

        # start transaction
        $adm->{db}->txn_begin;
        eval {
            my $delay;

            $log->debug("Calling check of operation $opclass.");
            $op->check();

            # If the operation never been processed, check its prerequisite
            if ($op->getAttr(name => 'state') eq 'pending') {
                $log->debug("Calling prerequisite of operation $opclass.");
                $delay = $op->prerequisites();

                # If the prerequisite are validated, process the operation
                if (not $delay) {
                    $op->setState(state => 'processing');

                    $log->debug("Calling prepare of operation $opclass.");
                    $op->prepare();

                    $log->debug("Calling execute of operation $opclass.");
                    $op->process();
                }
            }

            # If the operation has been processed, check its postrequisite
            if ($op->getAttr(name => 'state') eq 'processing') {
                $log->debug("Calling postrequisite of operation $opclass.");
                $delay = $op->postrequisites();
            }

            # Report the operation if required
            if ($delay) {
                $op->report(duration => $delay);

                # commit transaction
                $adm->{db}->txn_commit;
                $log->info("---- [$opclass] Execution reported ($delay s.) ----");
                next;
            }
        };
        if ($@) {
            my $err_exec = $@;

            # TODO: Cancel the whole workflow.

            # rollback transaction
            $adm->{db}->txn_rollback;
            $log->info("Rollback, Cancel operation will be call");
            eval {
                $adm->{db}->txn_begin;

                $op->cancel();
                $op->setState(state => 'canceled');

                $adm->{db}->txn_commit;
            };
            if ($@){
                my $err_rollback = $@;
                $log->error("Error during operation cancel :\n$err_rollback");

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
            # commit transaction
            eval {
                $op->finish();
            };
            if ($@) {
                my $err_finish = $@;
                $log->error("Error during operation finish :\n$err_finish");

                $errors .= $err_finish;
            }
            $adm->{db}->txn_commit;
            $log->info("---- [$opclass] Execution succeed ----");
            Message->send(
                from    => 'Executor',
                level   => 'info',
                content => "[$opclass] Execution Success"
            );

            $op->setState(state => 'succeeded');

            # Update the workflow context
            $workflow->updateParams(params => $op->{params}, context => $op->{context});
        }

        eval {
            $op->delete();
        };
        if ($@) {
            my $err_delop = $@;
            $log->error("Error during operation deletion : $err_delop");
            Message->send(
                from    => 'Executor',
                level   => 'error',
                content => "[$opclass] Deletion Error : $err_delop"
            );

            $errors .= $err_delop;
        }

        $workflow->updateState();
    }
    else { sleep 2; }

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
