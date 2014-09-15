# Copyright © 2010-2013 Hedera Technology SAS
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

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

=pod
=begin classdoc

Select a host for the new node, create the system image export it.

@since    2012-Aug-20
@instance hash
@self     $self

=end classdoc
=cut

package EEntity::EOperation::EAddNode;
use base "EEntity::EOperation";

use strict;
use warnings;

use Kanopya::Exceptions;
use Entity::ServiceProvider::Cluster;
use Entity::Systemimage;
use Entity::Host;
use CapacityManagement;
use Entity::Workflow;
use ClassType::ComponentType;

use TryCatch;
use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");
my $errmsg;


=pod
=begin classdoc

@param cluster         the cluster to add node
@param host_manager    the host manager to get a new free host
@param storage_manager the storage manager to create the system image

=end classdoc
=cut

sub check {
    my ($self, %args) = @_;

    General::checkParams(args     => $self->{context},
                         required => [ "service_manager", "cluster", "host_manager",
                                       "storage_manager" ],
                         optional => { "forced_host" => undef });

    # TODO: Move this virtual machine specific code to the host manager
    if ($self->{context}->{host_manager}->hostType eq 'Virtual Machine') {
        $self->{context}->{host_manager_sp} = $self->{context}->{host_manager}->service_provider;
    }

    # Check all the components are properly configured
    my @components = $self->{context}->{cluster}->components;
    map { $_->checkConfiguration(ignore => \@components) } @components;

    # Managing vm scale out after automatic hypervisor scale out (sorry...)
    if (! defined $self->{params}->{needhypervisor} && defined $self->{context}->{vm_cluster}) {
        $self->{context}->{cluster} = $self->{context}->{vm_cluster};
        delete $self->{context}->{vm_cluster};
    }
}


=pod
=begin classdoc

Check if the cluster is stable, ask to the manager the permission to use them.

=end classdoc
=cut

sub prepare {
    my ($self, %args) = @_;

    # Ask to the manager if we can use them
    $self->{context}->{host_manager}->increaseConsumers(operation => $self);
    $self->{context}->{storage_manager}->increaseConsumers(operation => $self);

    # $self->{params}->{needhypervisor} comes from the case of automatic hypervisor scaleout when
    # infrastructure needs more space

    if (defined $self->{params}->{needhypervisor}) {
        $log->debug('Do not manage EAddNode states when comming from automatic hypervideur add');
        return 0;
    }

    # Check the cluster state
    my ($state, $timestamp) = $self->{context}->{cluster}->reload->getState;
    if (! ($state eq 'up' || $state eq 'down' )) {
        $log->debug("State is <$state> which is an invalid state");
        throw Kanopya::Exception::Execution::InvalidState(
                  error => "The cluster <" . $self->{context}->{cluster}->cluster_name .
                           "> has to be <up|down> not <$state>"
              );
    }
}


=pod
=begin classdoc

If the host type is a virtual machine, find an hypervisor, and synchronize
the database with the infrastructure if required.

=end classdoc
=cut

sub prerequisites {
    my ($self, %args) = @_;
    my $params = $self->{context}->{cluster}->getManagerParameters(manager_type => 'HostManager');
    my $hypervisor_id = undef;

    try {
        $hypervisor_id = $self->{context}->{host_manager}->selectHypervisor(%{ $params })
    }
    catch (Kanopya::Exception::NotImplemented $err) {
        # Physical
        $log->warn($err);
        return 0;
    }

    if (defined $hypervisor_id) {
        my $host = Entity::Host->get(id => $hypervisor_id);
        $log->info('Hypervisor <' . $host->node->node_hostname
                   . '> has been selected to boot the virtual machine');

        $self->{context}->{hypervisor} = $host;
        my $diff_infra_db = $self->{context}
                                 ->{host_manager}
                                 ->checkHypervisorVMPlacementIntegrity(host => $host);

        if (! $self->{context}->{host_manager}->isInfrastructureSynchronized(hash => $diff_infra_db)) {
            # Repair infra before retrying AddNode
            $self->workflow->enqueueBefore(
                current_operation => $self,
                operation => {
                    priority => 200,
                    type     => 'SynchronizeInfrastructure',
                    params   => {
                        context => {
                            hypervisor => $host
                        },
                        diff_infra_db => $diff_infra_db,
                    }
                }
            );
            return -1;
        }
        return 0;
    }
    else {
        $log->info('Need to start a new hypervisor');
        $self->{context}->{vm_cluster} = $self->{context}->{cluster};

        my @vmms;
        try {
            @vmms = $self->{context}->{host_manager}->vmms;
        }
        catch {
            throw Kanopya::Exception::Execution::ResourceNotFound(
                      error => "The hypervisor cluster is full, please start a new hypervisor."
                  );
        }

        my $host_manager_sp = $vmms[0]->service_provider;
        my $workflow_to_enqueue = {
            name => 'AddNode',
            params => {
                context => {
                    cluster         => $host_manager_sp,
                    service_manager => $host_manager_sp->service_manager,
                    host_manager    => $host_manager_sp->getManager(manager_type => 'HostManager'),
                    storage_manager => $host_manager_sp->getManager(manager_type => 'StorageManager')
                }
            }
        };

        $self->workflow->enqueueBefore(
            current_operation => $self,
            workflow          => $workflow_to_enqueue,
        );

        $log->info('Enqueue "add hypervisor" operations before starting a new virtual machine');
        $self->{params}->{needhypervisor} = 1;
        return -1;
    }
    return 0;
}


=pod
=begin classdoc

If the host type is a virtual machine, find an hypervisor, and synchronize
the database with the infrastructure if required.

=end classdoc
=cut

sub execute {
    my $self = shift;

    # Get the node number
    $self->{params}->{node_number} = $self->{context}->{cluster}->getNewNodeNumber();
    $log->debug("Node number for this new node: $self->{params}->{node_number} ");

    # Check node number consistency
    my $maxnode = $self->{context}->{cluster}->cluster_max_node;
    if ($maxnode < $self->{params}->{node_number}) {
        throw Kanopya::Exception::Internal::WrongValue(error => "Too many nodes, limited to " . $maxnode);
    }

    # Check requested components for this node
    if (defined $self->{params}->{component_types}) {
        my @notavailable;
        for my $component_type_id (@{ $self->{params}->{component_types} }) {
            eval {
                $self->{context}->{cluster}->find(
                    related => 'components',
                    hash    => { 'component_type.component_type_id' => $component_type_id }
                );
            };
            if ($@) {
                push @notavailable, ClassType::ComponentType->get(id => $component_type_id)->component_name;
            }
        }
        if (scalar (@notavailable)) {
            throw Kanopya::Exception::Internal::WrongValue(
                      error => "Component(s) <" . join(', ', @notavailable) . "> not available on this cluster."
                  );
        }
    }

    # Check if a host is specified.
    if (exists $self->{context}->{forced_host} && defined $self->{context}->{forced_host} &&
        ($self->{context}->{forced_host}->host_manager_id == $self->{context}->{host_manager}->id)) {
        $self->{context}->{host} = delete $self->{context}->{forced_host};
    }
    else {
        # Get a free host
        # Merge all manager parameters to gather all required params for searching a free host
        my $managers_params = $self->{context}->{cluster}->getManagerParameters();
        $self->{context}->{host} = $self->{context}->{host_manager}->getFreeHost(%{ $managers_params });

        if (not defined $self->{context}->{host}) {
            throw Kanopya::Exception::Internal(error => "Could not find a usable host");
        }
    }

    # Check service billing limits
    $self->{context}->{cluster}->checkBillingLimits(metrics => {
        ram => $self->{context}->{host}->host_ram,
        cpu => $self->{context}->{host}->host_core
    });

    # Check the user quota on ram and cpu
    $self->{context}->{cluster}->owner->canConsumeQuota(resource => 'ram',
                                                        amount   => $self->{context}->{host}->host_ram);
    $self->{context}->{cluster}->owner->canConsumeQuota(resource => 'cpu',
                                                        amount   => $self->{context}->{host}->host_core);

    # Check for existing systemimage for this node.
    my $systemimage_name = $self->{context}->{cluster}->cluster_name . '_' .
                           $self->{params}->{node_number};

    # If systemimage context defined, force to use it.
    # If systemimage already exist for this node, use it.
    # Else create a new system image from the masterimage
    if (! defined $self->{context}->{systemimage}) {
        try {
            $self->{context}->{systemimage} = EEntity->new(entity => Entity::Systemimage->find(hash => {
                                                  systemimage_name => $systemimage_name
                                              }));
            $log->info("Using existing systemimage instance <$systemimage_name>");
        }
        catch {
            $log->info("A new systemimage instance <$systemimage_name> must be created");

            my $systemimage_desc = 'System image for node ' . $self->{params}->{node_number} .
                                   ' in cluster ' . $self->{context}->{cluster}->cluster_name . '.';

            # Retrieve the storage manager parameters from the cluster
            my $storage_params = $self->{context}->{cluster}->getManagerParameters(
                                     manager_type => 'StorageManager'
                                 );

            $self->{context}->{systemimage}
                = $self->{context}->{storage_manager}->createSystemImage(
                      systemimage_name => $systemimage_name,
                      systemimage_desc => $systemimage_desc,
                      masterimage      => $self->{context}->{cluster}->masterimage,
                      erollback        => $self->{erollback},
                      %{ $storage_params }
                  );
        }
    }

    # Define a hostname
    my $hostname = $self->{context}->{cluster}->getNodeHostname(
                       node_number => $self->{params}->{node_number}
                   );

    # Register the node in the cluster
    my $params = { host        => $self->{context}->{host},
                   systemimage => $self->{context}->{systemimage},
                   number      => $self->{params}->{node_number},
                   hostname    => $hostname };

    # Install specified components on the node
    if ($self->{params}->{component_types}) {
        $params->{components}
            = $self->{context}->{cluster}->search(
                  related => 'components',
                  hash    => {
                      'component_type.component_type_id' => $self->{params}->{component_types}
                  }
              );
    }
    $self->{context}->{node} = $self->{context}->{cluster}->registerNode(%$params);

    # Create the node working directory where generated files will be stored.
    my $dir = $self->_executor->getConf->{clusters_directory} . '/' . $hostname;
    $self->getEContext->execute(command => "mkdir -p $dir");

}


=pod
=begin classdoc

Set the host as 'locked'.

=end classdoc
=cut

sub finish {
    my ($self, %args) = @_;

    $self->{context}->{host}->setState(state => "locked");

    # Release managers
    $self->{context}->{host_manager}->decreaseConsumers(operation => $self);
    $self->{context}->{storage_manager}->decreaseConsumers(operation => $self);
}


=pod
=begin classdoc

Restore the clutser and host states.

=end classdoc
=cut

sub cancel {
    my ($self, %args) = @_;

    # If the managers has not been released at finish, decrease at cancel
    if ($self->state ne 'succeeded') {
        $self->{context}->{host_manager}->decreaseConsumers(operation => $self);
        $self->{context}->{storage_manager}->decreaseConsumers(operation => $self);
    }

    if (defined $self->{params}->{needhypervisor}) {
        $self->{context}->{cluster}->setState(state => 'up');
    }
    else {
        $self->{context}->{cluster}->restoreState();
    }

    $self->{context}->{host_manager}->removeState(consumer => $self->workflow);

    if (defined $self->{context}->{host_manager_sp}) {
        $log->debug('Remove host_manager sp <'.$self->{context}->{host_manager_sp}->id.'> state');
        $self->{context}->{host_manager_sp}->setState(state => 'up');
    }

    if (defined $self->{context}->{host}) {
        $log->debug('Remove host <'.$self->{context}->{host}->id.'> state');
        $self->{context}->{host}->setState(state => 'down');
    }

    if (defined $self->{context}->{hypervisor}) {
        $log->debug('Remove hypervisor <'.$self->{context}->{hypervisor}->id.'> state');
    }

    if (defined $self->{context}->{vm_cluster}) {
        $log->debug('Remove vm_cluster <'.$self->{context}->{vm_cluster}->id.'> state');
        $self->{context}->{vm_cluster}->setState(state => 'up');
    }

    if (defined $self->{context}->{host}->node) {
        my $dir = $self->_executor->getConf->{clusters_directory};
        $dir .= '/' . $self->{context}->{host}->node->node_hostname;
        $self->getEContext->execute(command => "rm -r $dir");

        $self->{context}->{cluster}->unregisterNode(node => $self->{context}->{host}->node);
    }

    if (defined $self->{context}->{host}) {
        eval {
            $self->{context}->{host}->release();
        };
        if ($@) {
            $log->warn("Cancel rollback failed: $@");
        }
    }
}

1;
