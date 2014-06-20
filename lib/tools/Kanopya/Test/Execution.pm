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

package Kanopya::Test::Execution;

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Pod;

use Log::Log4perl qw(:easy);
my $log = get_logger("");

use Kanopya::Exceptions;
use Daemon;
use General;
use EEntity;
use Entity::Component::Lvm2;
use Entity::Component::Iscsi::Iscsitarget1;
use Entity::Systemimage;
use Entity::Component::KanopyaDeploymentManager;
use Entity::Masterimage;

use Daemon::MessageQueuing::Executor;

my @args = ();

BEGIN {
    # Test will fail if any executor is running
    if (Daemon->isDaemonRunning(name => 'kanopya-executor')) {
        throw Kanopya::Exception::Internal(error => 'An executor is already running');
    }
}

my $executor = Daemon::MessageQueuing::Executor->new();

Kanopya::Test::Execution->purgeQueues();


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

    for my $queue ('kanopya.executor.workflow',
                   'kanopya.executor.operation',
                   'kanopya.executor.operation_result') {
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
        elsif ($state eq 'failed' || $state eq 'cancelled') {
            my $failed = $workflow->getFailedOperation;
            my $exception;
            if (defined $failed &&
                defined $failed->param_preset &&
                defined $failed->param_preset->load()->{exception}) {
                $exception = $failed->param_preset->load()->{exception};
            }
            else {
                $exception = "Workflow <" . $workflow->label . "> failed. "
            }

            throw Kanopya::Exception::Test(error => $exception);
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

    Kanopya::Test::Execution->executeOne(entity => $cluster->start());
    $cluster = $cluster->reload();

    if (scalar ($cluster->nodes) < $cluster->cluster_min_node) {
        Kanopya::Test::Execution->executeAll(timeout => 3600);
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

    Kanopya::Test::Execution->executeOne(entity => $cluster->addNode(%$components_params));

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


sub deployNode {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'node' ]);

    diag('Register master image');
    my $masterimage;
    lives_ok {
        $masterimage = Kanopya::Test::Execution::registerMasterImage();
    } 'Register master image';

    diag('Create the system image for the node to deploy');
    my $systemimage;
    my $lvm = Entity::Component::Lvm2->find();
    my $iscsi = Entity::Component::Iscsi::Iscsitarget1->find();
    $systemimage = Entity::Systemimage->new(systemimage_name => "deploy_node_test" . time);

    my $container = EEntity->new(entity => $lvm)->createDisk(
                        name       => $systemimage ->systemimage_name,
                        size       => 1024 * 1024 * 1024 * 4,
                        filesystem => 'ext3',
                    );

    # Create a temporary local container to access to the masterimage file.
    my $master_container = EEntity->new(entity => Entity::Container::LocalContainer->new(
                               container_name       => $masterimage->masterimage_name,
                               container_size       => $masterimage->masterimage_size,
                               container_filesystem => 'ext3',
                               container_device     => $masterimage->masterimage_file,
                           ));

    # Copy the masterimage container contents to the new container
    $master_container->copy(dest     => $container,
                            econtext => Kanopya::Test::Execution->_executor->_host->getEContext);

    # Remove the temporary container
    $master_container->remove();

    my $container_access = EEntity->new(entity => $iscsi)->createExport(
                               container    => $container,
                               export_name  => $systemimage->systemimage_name,
                               iscsi_portal => IscsiPortal->find()->id
                           );

    EEntity->new(entity => $systemimage)->activate(container_accesses => [ $container_access ]);

    diag('Deploy the node via the KanopyaDeploymentManager');
    my $deployment_mamager = Entity::Component::KanopyaDeploymentManager->find();
    my $operation = $deployment_mamager->deployNode(
                        node         => $args{node},
                        systemimage  => $systemimage,
                        kernel_id    => $masterimage->masterimage_defaultkernel_id,
                        boot_policy  => 'PXE Boot via ISCSI',
                    );

    Kanopya::Test::Execution->executeOne(entity => $operation);
}

sub checkNodeUp {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'node' ]);

    if (! EEntity->new(entity => $args{node}->host->reload)->checkUp()) {
        die 'Host ' . $args{node}->host->label . ' not up.'
    }
    if (! EEntity->new(entity => $args{node}->reload)->checkComponents()) {
        die 'Components of the node ' . $args{node}->label . ' are not up.'
    }
}


=pod

=begin classdoc

Register a masterimage into kanopya

@param masterimage_name (unamed argument)

@return masterimage the created masterimage

=end classdoc

=cut

sub registerMasterImage {
    my $name = shift || $ENV{'MASTERIMAGE'} || "centos-6.3-opennebula3.tar.bz2";

    diag('Deploy master image');
    my $deploy = Entity::Masterimage->create(
                     file_path => "/masterimages/" . $name,
                     keep_file => 1
                 );

    Kanopya::Test::Execution->executeOne(entity => $deploy);

    return Entity::Masterimage->find(hash     => { },
                                     order_by => 'masterimage_id');
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
