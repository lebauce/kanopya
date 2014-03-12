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

Kanopya::Tools::Execution->purgeQueues();


=pod

=begin classdoc

Launch 1 executor->oneRun

=end classdoc

=cut

sub oneRun {
    my ($self, %args) = @_;

    $log->info("Fetching on queue <workflow>");
    eval { $executor->oneRun(cbname => 'run_workflow', duration => 1); };
    $log->info("Fetching on queue <operation>");
    eval { $executor->oneRun(cbname => 'execute_operation', duration => 1); };
    $log->info("Fetching on queue <operation_result>");
    eval { $executor->oneRun(cbname => 'handle_result', duration => 1); };
}

=pod

=begin classdoc

Launch n executor->oneRun

=end classdoc

=cut

sub nRun {
    my ($self, %args) = @_;

    for (1..$args{n}) {
        $self->oneRun;
    }
}


=pod
=begin classdoc

Purge the executor queues.

=end classdoc
=cut

sub purgeQueues {
    my ($self, %args) = @_;

    for my $queue ('workflow', 'operation', 'operation_result') {
        $executor->purgeQueue(queue => $queue);
    }
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
        eval {
            $log->debug("Calling oneRun with cbname <run_workflow>");
            $executor->oneRun(cbname => 'run_workflow', duration => 1);
            $log->debug("Called oneRun with cbname <run_workflow>");
        };
        if ($@) {
            my $err = $@;
            if (not $err->isa('Kanopya::Exception::MessageQueuing::NoMessage')) {
                $err->rethrow();
            }
        }
        eval {
            $log->debug("Calling oneRun with cbname <execute_operation>");
            $executor->oneRun(cbname => 'execute_operation', duration => 1);
            $log->debug("Called oneRun with cbname <execute_operation>");
        };
        if ($@) {
            my $err = $@;
            if (not $err->isa('Kanopya::Exception::MessageQueuing::NoMessage')) {
                $err->rethrow();
            }
        }
        eval {
            $log->debug("Calling oneRun with cbname <operation_result>");
            $executor->oneRun(cbname => 'handle_result', duration => 1);
            $log->debug("Called oneRun with with cbname <operation_result>");
        };
        if ($@) {
            my $err = $@;
            if (not $err->isa('Kanopya::Exception::MessageQueuing::NoMessage')) {
                $err->rethrow();
            }
        }

        my $state = $workflow->reload->state;
        if ($state eq 'running') {
            diag('Workflow ' . $workflow->id . ' still running...');
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
        elsif ($state eq 'interrupted') {
            diag('Workflow ' . $workflow->id . ' interrupted');
            throw Kanopya::Exception::Internal(error => 'Execution of workflow ' . $workflow->workflow_name . ' (' .$workflow->id . ') interrupted');
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
        $log->info("Checking remaning operations...");
        eval {
            $operation = Entity::Operation->find(hash => {});
        };
        if ($@) {
            $log->info("No more operations, exiting...");
            last;
        }
        else {
            $log->info("sleep 5 ($timeout)");
            sleep 5;
            $timeout -= 5;
            $log->info("Fetching on queue <workflow>");
            eval { $executor->oneRun(cbname => 'run_workflow', duration => 1); };
            $log->info("Fetching on queue <operation>");
            eval { $executor->oneRun(cbname => 'execute_operation', duration => 1); };
            $log->info("Fetching on queue <operation_result>");
            eval { $executor->oneRun(cbname => 'handle_result', duration => 1); };
        }
    }
}

sub startCluster {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'cluster' ]);

    my $cluster = $args{cluster};

    Kanopya::Tools::Execution->executeOne(entity => $cluster->start());
    $cluster = $cluster->reload();

    if (scalar ($cluster->nodes) < $cluster->cluster_min_node) {
        Kanopya::Tools::Execution->executeAll(timeout => 3600);
        $cluster = $cluster->reload();
    }

    my ($state, $timestemp) = $cluster->getState;
    if ($state eq 'up') {
        diag("Cluster " . $cluster->cluster_name . " started successfully");
    }
    else {
        die "Cluster is not 'up'";
    }

    return $cluster;
}

sub addNode {
    my ($self, %args) = @_;

    General::checkParams(
        args => \%args, required => [ 'cluster' ],
        optional => { 'component_types' => undef }
    );

    my $cluster = $args{cluster};
    my $components_params = {};
    if (defined $args{component_types}) {
        $components_params = {
            component_types => $args{component_types},
        };
    }

    my $old_node_number = scalar ($cluster->nodes);

    Kanopya::Tools::Execution->executeOne(entity => $cluster->addNode(%$components_params));

    $cluster = $cluster->reload();
    if (scalar ($cluster->nodes) != $old_node_number+1) {
        die 'Node not added to cluster ' . $cluster->cluster_name;
    }

    my @nodes = $cluster->nodes;
    my $node = $nodes[$old_node_number];

    my ($state, $timestemp) = $node->host->getState;
    if ($state eq 'up') {
        diag("Node " . $node->node_hostname . " added successfully");
    }
    else {
        die "Node is not 'up'";
    }

    return $node;
}


=pod
=begin classdoc

@return the executor singleton

=end classdoc
=cut

sub _executor {
    my ($class, %args) = @_;

    return $executor;
}

1;
