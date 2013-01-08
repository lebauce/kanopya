# Copyright © 2012 Hedera Technology SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

=pod

=begin classdoc

Kanopya module to handle operation and workflow execution 

@since 12/12/12
@instance hash
@self $self

=end classdoc

=cut

package Kanopya::Tools::Execution;

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Pod;

use Log::Log4perl qw(:easy);
my $log = get_logger("");

use Kanopya::Exceptions;
use General;
use Executor;

my @args = ();

BEGIN {
    # Test will fail if any executor is running
    my $executor_exist = `ps aux | grep kanopya-executor | grep -cv grep`;
    if ($executor_exist == 1) {
        throw Kanopya::Exception::Internal(error => 'An executor is already running');
    }
}

my $executor = Executor->new();

=pod

=begin classdoc

Lauch 1 executor->oneRun

=end classdoc

=cut

sub oneRun {
    my $self = shift;

    $executor->oneRun;
}

=pod

=begin classdoc

Manage operation and workflow execution
Check if all the operations of a workflow have been executed, and if not trigger oneRuns


=end classdoc

=cut

sub executeOne {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [ 'entity' ]);

    my $workflow;

    if (ref $args{entity} eq 'Entity::Operation') {
        $workflow = $args{entity}->workflow;
    }
    elsif (ref $args{entity} eq 'Entity::Workflow') {
        $workflow = $args{entity};
    }
    else {
        throw Kanopya::Exception::Internal(
            error => 'wrong type of entity given to execute'
        );
    }

    WORKFLOW:
    while(1) {
        $executor->oneRun;

        my $current;
        eval {
            $current = $workflow->getCurrentOperation;
        };

        # refresh workflow view
        $workflow = Entity::Workflow->find(hash => {workflow_id => $workflow->id});

        my $state = $workflow->state;
        if ($state eq 'running') {
            sleep(5);
            next WORKFLOW;
        }
        elsif ($state eq 'done') {
            diag('Workflow ' . $workflow->id . ' done');
            last WORKFLOW;
        }
        elsif ($state eq 'failed') {
            diag('Workflow ' . $workflow->id . ' failed');
            throw Kanopya::Exception::Internal(error => 'Execution of workflow ' . $workflow->workflow_name . ' (' .$workflow->id . ') failed');
        }
        elsif ($state eq 'cancelled') {
            diag('Workflow ' . $workflow->id . ' cancelled');
            throw Kanopya::Exception::Internal(error => 'Execution of workflow ' . $workflow->workflow_name . ' (' .$workflow->id . ') cancelled');
        }
    }

}

=pod

=begin classdoc

Execute all operations in queue

=end classdoc

=cut

sub executeAll {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, optional => { 'timeout' => 300 });
    my $timeout = $args{timeout};

    my $operation;
    while ($timeout > 0) {
        eval {
            $operation = Entity::Operation->find(hash => {});
        };
        if ($@) {
            last;
        }
        else {
            sleep 5;
            $timeout -= 5;
            $executor->oneRun;
            $log->info("sleep 5 ($timeout)");
        }
    }
}

sub startCluster {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'cluster' ]);

    my $cluster = $args{cluster};

    Kanopya::Tools::Execution->executeOne(entity => $cluster->start());
    $cluster = $cluster->reload();

    my ($state, $timestemp) = $cluster->getState;
    if ($state eq 'up') {
        diag("Cluster " . $cluster->cluster_name . " started successfully");
    }
    else {
        die "Cluster is not 'up'";
    }

    return $cluster;
}

1;
