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

@param cluster        the cluster to add node
@param host_manager   the host manager to get a new free host
@param disk_manager   the disk manager to create the disk
@param export_manager the export manager to export the disk

=end classdoc
=cut

sub check {
    my ($self, %args) = @_;

    General::checkParams(args     => $self->{context},
                         required => [ "cluster" ],
                         optional => { "forced_host" => undef });

    # Add the manager to the context
    # TODO: Probably not the proper place...
    my $cluster = $self->{context}->{cluster};
    $self->{context}->{host_manager}
        = EEntity->new(entity => $cluster->getManager(manager_type => 'HostManager'));
    $self->{context}->{disk_manager}
        = EEntity->new(entity => $cluster->getManager(manager_type => 'DiskManager'));
    $self->{context}->{export_manager}
        = EEntity->new(entity => $cluster->getManager(manager_type => 'ExportManager'));

    # TODO: Move this virtual machine specific code to the host manager
    if ($self->{context}->{host_manager}->hostType eq 'Virtual Machine') {
        $self->{context}->{host_manager_sp} = $self->{context}->{host_manager}->service_provider;
    }

    # Check all the components are properly configured
    my @components = $self->{context}->{cluster}->components;
    map { $_->checkConfiguration() } @components;

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
    $self->{context}->{host_manager}->increaseConsumers();
    $self->{context}->{disk_manager}->increaseConsumers();
    $self->{context}->{export_manager}->increaseConsumers();

    # $self->{params}->{needhypervisor} comes from the case of automatic hypervisor scaleout when
    # infrastructure needs more space

    if (defined $self->{params}->{needhypervisor}) {
        $log->debug('Do not manage EAddNode states when comming from automatic hypervideur add');
        return 0;
    }

    # Check cluster states
    # TODO: Definitely clean the entity states mechanism
    my $updating_in_workflow;
    my @entity_states = $self->{context}->{cluster}->entity_states;
    for my $entity_state (@entity_states) {
        # The only authorized state is 'updating' by the current workflow, that correspond to
        # a multi node StartCluster workflow.
        if ($entity_state->consumer->id == $self->workflow->id && $entity_state->state eq 'updating') {
            $updating_in_workflow = 1;
        }
        else {
            throw Kanopya::Exception::Execution::InvalidState(
                      error => "The cluster <"
                               .$self->{context}->{host_manager}->service_provider->cluster_name
                               .'> is <'.$entity_state->state
                               .'> which is not a correct state to accept addnode'
                  );
        }
    }

    # Check the cluster state
    my ($state, $timestamp) = $self->{context}->{cluster}->reload->getState;
    if (! ($state eq 'up' || $state eq 'down' || ($state eq 'updating' && $updating_in_workflow))) {
        $log->debug("State is <$state> which is an invalid state");
        throw Kanopya::Exception::Execution::InvalidState(
                  error => "The cluster <" . $self->{context}->{cluster}->cluster_name .
                           "> has to be <up|down|updating (by current workflow only)> not <$state>"
              );
    }

    if (defined $self->{context}->{host_manager_sp}) {
        # Check cluster states
        my @entity_states = $self->{context}->{host_manager_sp}->entity_states;

        for my $entity_state (@entity_states) {
            throw Kanopya::Exception::Execution::InvalidState(
                      error => "The iaas cluster <"
                               .$self->{context}->{host_manager_sp}->cluster_name
                               .'> is <'.$entity_state->state
                               .'> which is not a correct state to accept addnode'
                  );
        }

        my ($hv_state, $hv_timestamp) = $self->{context}->{host_manager_sp}->reload->getState;
        if (not ($hv_state eq 'up')) {
            $log->debug("State of hypervisor cluster is <$hv_state> which is an invalid state");
            throw Kanopya::Exception::Execution::InvalidState(
                      error => "The hypervisor cluster <" . $self->{context}->{host_manager_sp}->cluster_name .
                               "> has to be <up>, not <$hv_state>"
                  );
        }
        $self->{context}->{host_manager_sp}->setState(state => 'updating');
        $self->{context}->{host_manager_sp}->setConsumerState(state => 'updating', consumer => $self->workflow);
    }

    $self->{context}->{cluster}->setState(state => 'updating');
    $self->{context}->{cluster}->setConsumerState(state => 'updating', consumer => $self->workflow);
}


=pod
=begin classdoc

If the host type is a virtual machine, find an hypervisor, and synchronize
the database with the infrastructure if required.

=end classdoc
=cut

sub prerequisites {
    my ($self, %args) = @_;

    my $cluster = $self->{context}->{cluster};
    my $host_type = $cluster->getHostManager->hostType;

    # TODO: Move this virtual machine specific code to the host manager
    if ($host_type eq 'Virtual Machine') {
        my @hvs = @{ $self->{context}->{host_manager}->hypervisors };
        my @hv_in_ids;
        for my $hv (@hvs) {
            my ($state,$time_stamp) = $hv->getNodeState();
            $log->info('hv <'.($hv->id()).'>, state <'.($state).'>');
            if ($state eq 'in') {
                push @hv_in_ids, $hv->id;
            }
        }
        $log->info("Hvs selected <@hv_in_ids>");

        my $host_manager_params = $cluster->getManagerParameters(manager_type => 'HostManager');
        $log->info('host_manager_params :'.(Dumper $host_manager_params));

        my $cm = CapacityManagement->new(cloud_manager => $self->{context}->{host_manager});

        my $hypervisor_id = $cm->getHypervisorIdForVM(
                                selected_hv_ids => \@hv_in_ids,
                                resources       => {
                                    ram           => $host_manager_params->{ram},
                                    cpu           => $host_manager_params->{core},
                                    # Even if there is memory overcommitment VM needs effectively 1GB to boot the OS
                                    ram_effective => 1*1024*1024*1024,
                                }
                            );

        if (defined $hypervisor_id) {
            $log->info("Hypervisor <$hypervisor_id> ready");
            my $host = Entity::Host->get(id => $hypervisor_id);

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

            $log->info('Hypervisor confirmed, start node');
            $self->{context}->{hypervisor} = $host;
            return 0;
        }
        else {
#            throw Kanopya::Exception::Internal('Hypervisor cluster is full ! Please start a new hypervisor');
            # TODO debug with state management

            $log->info('Need to start a new hypervisor');
            $self->{context}->{vm_cluster} = $self->{context}->{cluster};
            my @vmms = $self->{context}->{host_manager}->vmms;
            my $host_manager_sp = $vmms[0]->service_provider;
            my $workflow_to_enqueue = { name => 'AddNode', params => { context => { cluster => $host_manager_sp, }  }};

            $self->workflow->enqueueBefore(
                current_operation => $self,
                workflow          => $workflow_to_enqueue,
            );

            $log->info('Enqueue "add hypervisor" operations before starting a new virtual machine');
            $self->{params}->{needhypervisor} = 1;
            return -1;
        }
   }
   else {   #Physical
       return 0
   }
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
                $self->{context}->{cluster}->findRelated(
                    filters => [ 'components' ],
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
        $self->{context}->{host} = $self->{context}->{host_manager}->getFreeHost(
                                       cluster => $self->{context}->{cluster}
                                   );

        if (not defined $self->{context}->{host}) {
            throw Kanopya::Exception::Internal(error => "Could not find a usable host");
        }
    }

    # Check service billing limits
    my $host_metrics = {
        ram => $self->{context}->{host}->host_ram,
        cpu => $self->{context}->{host}->host_core,
    };

    $self->{context}->{cluster}->checkBillingLimits(metrics => $host_metrics);

    # Check the user quota on ram and cpu
    $self->{context}->{cluster}->owner->canConsumeQuota(resource => 'ram',
                                                        amount   => $self->{context}->{host}->host_ram);
    $self->{context}->{cluster}->owner->canConsumeQuota(resource => 'cpu',
                                                        amount   => $self->{context}->{host}->host_core);

    my $createdisk_params   = $self->{context}->{cluster}->getManagerParameters(manager_type => 'DiskManager');
    my $createexport_params = $self->{context}->{cluster}->getManagerParameters(manager_type => 'ExportManager');

    # Check for existing systemimage for this node.
    my $existing_image;
    my $systemimage_name = $self->{context}->{cluster}->cluster_name . '_' .
                           $self->{params}->{node_number};
    eval {
        $existing_image = Entity::Systemimage->find(hash => { systemimage_name => $systemimage_name });
    };

    # If systemimage context defined, force to use it.
    # If systemimage already exist for this node, use it.
    if (not $self->{context}->{systemimage}) {
        if ($existing_image) {
            $log->info("Using existing systemimage instance <$systemimage_name>");
            $self->{context}->{systemimage} = EEntity->new(data => $existing_image);
        }
        # Else if it is the first node, or the cluster si policy is dedicated, create a new one.
        else {
            $log->info("A new systemimage instance <$systemimage_name> must be created");

            my $systemimage_desc = 'System image for node ' . $self->{params}->{node_number}  .' in cluster ' .
                                   $self->{context}->{cluster}->cluster_name . '.';

            eval {
               my $entity = Entity::Systemimage->new(systemimage_name    => $systemimage_name,
                                                     systemimage_desc    => $systemimage_desc,
                                                     service_provider_id => $self->{context}->{cluster}->id);
               $self->{context}->{systemimage} = EEntity->new(data => $entity);
            };
            if($@) {
                throw Kanopya::Exception::Internal::WrongValue(error => $@);
            }
            $self->{params}->{create_systemimage} = 1;
        }
    }

    # Create system image for node if required.
    if ($self->{params}->{create_systemimage} and $self->{context}->{cluster}->masterimage) {

        # Creation of the device based on distribution device
        my $container = $self->{context}->{disk_manager}->createDisk(
                            name       => $self->{context}->{systemimage}->systemimage_name,
                            size       => delete $createdisk_params->{systemimage_size},
                            # TODO: get this value from masterimage attrs.
                            filesystem => 'ext3',
                            erollback  => $self->{erollback},
                            cluster    => $self->{context}->{cluster},
                            %{ $createdisk_params }
                        );

        $log->debug('Container creation for new systemimage');

        # Create a temporary local container to access to the masterimage file.
        my $master_container = EEntity->new(entity => Entity::Container::LocalContainer->new(
                                   container_name       => $self->{context}->{cluster}->masterimage->masterimage_name,
                                   container_size       => $self->{context}->{cluster}->masterimage->masterimage_size,
                                   # TODO: get this value from masterimage attrs.
                                   container_filesystem => 'ext3',
                                   container_device     => $self->{context}->{cluster}->masterimage->masterimage_file,
                               ));

        # Copy the masterimage container contents to the new container
        $master_container->copy(dest      => $container,
                                econtext  => $self->getEContext,
                                erollback => $self->{erollback});

        # Remove the temporary container
        $master_container->remove();

        foreach my $comp ($self->{context}->{cluster}->masterimage->component_types) {
            $self->{context}->{systemimage}->installedComponentLinkCreation(component_type_id => $comp->id);
        }
        $log->info('System image <' . $self->{context}->{systemimage}->systemimage_name . '> creation complete');

        # Add the created container to the export manager params
        $createexport_params->{container} = $container;
    }

    # Export system image for node if required.
    if (not $self->{context}->{systemimage}->active) {
        # Creation of the export to access to the system image container
        my @accesses;
        my $portals = defined $createexport_params->{iscsi_portals} ?
                          delete $createexport_params->{iscsi_portals} : [ 0 ];
        for my $portal_id (@{ $portals }) {
            try {
                push @accesses, $self->{context}->{export_manager}->createExport(
                                    export_name  => $self->{context}->{systemimage}->systemimage_name,
                                    iscsi_portal => $portal_id,
                                    erollback    => $self->{erollback},
                                    %{ $createexport_params }
                                );
            }
            catch ($err) {
                if (scalar(@accesses)) {
                    $log->error("Exporting systemimage with portal <$portal_id> failed, but at least one export for " .
                                "systemimage " . $self->{context}->{systemimage}->label . " succeeded, continuing...");
                }
                else {
                    $err->rethrow();
                }
            }

        }

        # Activate the system by linking it to the container accesses
        $self->{context}->{systemimage}->activate(container_accesses => \@accesses,
                                                  erollback          => $self->{erollback});
    }
}


=pod
=begin classdoc

Set the host as 'locked'.

=end classdoc
=cut

sub finish {
    my ($self, %args) = @_;

    $self->{context}->{host}->setState(state => "locked");
    $self->{context}->{host}->setConsumerState(state => 'adding', consumer => $self->workflow);

    # Add state to hypervisor if defined
    if (defined $self->{context}->{hypervisor}) {
        $self->{context}->{host_manager_sp}->setConsumerState(state => 'scaleout', consumer => $self->workflow);
        $self->{context}->{hypervisor}->setConsumerState(state => 'scaleout', consumer => $self->workflow);
    }

    # Release managers
    $self->{context}->{host_manager}->decreaseConsumers();
    $self->{context}->{disk_manager}->decreaseConsumers();
    $self->{context}->{export_manager}->decreaseConsumers();

    delete $self->{context}->{host_manager};
    delete $self->{context}->{disk_manager};
    delete $self->{context}->{export_manager};
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
        $self->{context}->{host_manager}->decreaseConsumers();
        $self->{context}->{disk_manager}->decreaseConsumers();
        $self->{context}->{export_manager}->decreaseConsumers();
    }

    if (defined $self->{params}->{needhypervisor}) {
        $self->{context}->{cluster}->setState(state => 'up');
    }
    else {
        $self->{context}->{cluster}->restoreState();
    }

    $self->{context}->{cluster}->removeState(consumer => $self->workflow);

    if (defined $self->{context}->{host_manager_sp}) {
        $log->debug('Remove host_manager sp <'.$self->{context}->{host_manager_sp}->id.'> state');
        $self->{context}->{host_manager_sp}->setState(state => 'up');
        $self->{context}->{host_manager_sp}->removeState(consumer => $self->workflow);
    }

    if (defined $self->{context}->{host}) {
        $log->debug('Remove host <'.$self->{context}->{host}->id.'> state');
        $self->{context}->{host}->setState(state => 'down');
        $self->{context}->{host}->removeState(consumer => $self->workflow);
    }

    if (defined $self->{context}->{hypervisor}) {
        $log->debug('Remove hypervisor <'.$self->{context}->{hypervisor}->id.'> state');
        $self->{context}->{hypervisor}->removeState(consumer => $self->workflow);
    }

    if (defined $self->{context}->{vm_cluster}) {
        $log->debug('Remove vm_cluster <'.$self->{context}->{vm_cluster}->id.'> state');
        $self->{context}->{vm_cluster}->setState(state => 'up');
        $self->{context}->{vm_cluster}->removeState(consumer => $self->workflow);
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
