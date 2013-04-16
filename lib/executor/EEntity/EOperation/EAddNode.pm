# Copyright © 2010-2012 Hedera Technology SAS
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

package EEntity::EOperation::EAddNode;
use base "EEntity::EOperation";

use strict;
use warnings;

use Kanopya::Exceptions;
use Entity::ServiceProvider::Cluster;
use Entity::Masterimage;
use Entity::Systemimage;
use Entity::Host;
use CapacityManagement;
use Entity::Workflow;
use ClassType::ComponentType;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");
my $errmsg;


sub prerequisites {
    my ($self, %args) = @_;

    General::checkParams(args => $self->{context}, required => [ "cluster" ]);

    my $cluster = $self->{context}->{cluster};
    my $host_type = $cluster->getHostManager->hostType;

    # TODO: Move this virtual machine specific code to the host manager
    if ($host_type eq 'Virtual Machine') {
        $self->{context}->{host_manager} = EEntity->new(
                                               data => $cluster->getManager(manager_type => 'HostManager'),
                                           );

        my @hvs   = @{ $self->{context}->{host_manager}->hypervisors };
        my @hv_in_ids;
        for my $hv (@hvs) {
            my ($state,$time_stamp) = $hv->getNodeState();
            $log->info('hv <'.($hv->getId()).'>, state <'.($state).'>');
            if($state eq 'in') {
                push @hv_in_ids, $hv->getId();
            }
        }
        $log->info("Hvs selected <@hv_in_ids>");

        my $host_manager_params = $cluster->getManagerParameters(manager_type => 'HostManager');
        $log->info('host_manager_params :'.(Dumper $host_manager_params));

        my $cm = CapacityManagement->new(cloud_manager => $self->{context}->{host_manager});

        my $hypervisor_id = $cm->getHypervisorIdForVM(
                                # blacklisted_hv_ids => $self->{params}->{blacklisted_hv_ids},
                                selected_hv_ids => \@hv_in_ids,
                                wanted_values   => {
                                    ram           => $host_manager_params->{ram},
                                    cpu           => $host_manager_params->{core},
                                    # Even if there is memory overcommitment VM needs effectively 1GB to boot the OS
                                    ram_effective => 1*1024*1024*1024
                                }
                            );

        if(defined $hypervisor_id) {
            $log->info("Hypervisor <$hypervisor_id> ready");
            $self->{context}->{hypervisor} = Entity::Host->get(id => $hypervisor_id);
            return 0;
        }
        else {
            $log->info('Need to start a new hypervisor');
            my $hv_cluster = $self->{context}->{host_manager}->service_provider;
            my $workflow_to_enqueue = { name => 'AddNode', params => { context => { cluster => $hv_cluster, }  }};
            $self->workflow->enqueueBefore(workflow => $workflow_to_enqueue);
            $log->info('Enqueue "add hypervisor" operations before starting a new virtual machine');
            return -1;
        }
   }
   else {   #Physical
       return 0
   }
}


sub prepare {
    my $self = shift;
    my %args = @_;
    $self->SUPER::prepare();

    General::checkParams(args => $self->{context}, required => [ "cluster" ]);

    # Get the disk manager for disk creation
    my $disk_manager = $self->{context}->{cluster}->getManager(manager_type => 'DiskManager');
    $self->{context}->{disk_manager} = EEntity->new(data => $disk_manager);

    # Get the export manager for disk creation
    my $export_manager = $self->{context}->{cluster}->getManager(manager_type => 'ExportManager');
    $self->{context}->{export_manager} = EEntity->new(data => $export_manager);

    # Get the masterimage for node systemimage creation.
    if ($self->{context}->{cluster}->masterimage) {
        $self->{context}->{masterimage} = EEntity->new(entity => $self->{context}->{cluster}->masterimage);
    }

    # Check if a host is specified.
    if (defined $self->{context}->{host}) {
        my $host_manager_id = $self->{context}->{host}->host_manager_id;
        my $cluster_host_manager_id = $self->{context}->{cluster}->getManager(manager_type => 'HostManager')->id;

        # Check if the specified host is managed by the cluster host manager
        if ($host_manager_id != $cluster_host_manager_id) {
            delete $self->{context}->{host};
            # TODO throw the following error when new context and param system passing through operations

            # $errmsg = 'Specified host <.'($self->{context}->{host}->id).'>, is not managed by the same host manager than the ' .
            #     "cluster one (<$host_manager_id>) != <$cluster_host_manager_id>).";
            #     throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
        }
    }

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
        for my $component_type_id (@{ $self->{params}->{component_types}  }) {
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
        elsif (($self->{params}->{node_number} == 1) or (not $self->{context}->{cluster}->cluster_si_shared)) {
            $log->info("A new systemimage instance <$systemimage_name> must be created");

            my $systemimage_desc = 'System image for node ' . $self->{params}->{node_number}  .' in cluster ' .
                                   $self->{context}->{cluster}->cluster_name . '.';

            eval {
               my $entity = Entity::Systemimage->new(systemimage_name => $systemimage_name,
                                                     systemimage_desc => $systemimage_desc);
               $self->{context}->{systemimage} = EEntity->new(data => $entity);
            };
            if($@) {
                throw Kanopya::Exception::Internal::WrongValue(error => $@);
            }
            $self->{params}->{create_systemimage} = 1;
        }
        else {
            $self->{context}->{systemimage} = EEntity->new(
                                                  data => $self->{context}->{cluster}->getSharedSystemimage
                                              );
        }
    }
}

sub execute {
    my $self = shift;
    $self->SUPER::execute();

    if (not defined $self->{context}->{host}) {
        # Get a free host
        $self->{context}->{host} = $self->{context}->{cluster}->addNode();

        if (not defined $self->{context}->{host}) {
            throw Kanopya::Exception::Internal(error => "Could not find a usable host");
        }

        # If the host ifaces are not configured to netconfs at resource declaration step,
        # associate them according to the cluster interfaces netconfs
        my @ifaces = $self->{context}->{host}->configuredIfaces;
        if (scalar @ifaces == 0) {
            $self->{context}->{host}->configureIfaces(cluster => $self->{context}->{cluster});
        }
    }

    # Check the user quota on ram and cpu
    $self->{context}->{cluster}->user->canConsumeQuota(resource => 'ram',
                                                       amount   => $self->{context}->{host}->host_ram);
    $self->{context}->{cluster}->user->canConsumeQuota(resource => 'cpu',
                                                       amount   => $self->{context}->{host}->host_core);

    $self->{context}->{host}->setState(state => "locked");

    # If it is the first node, the cluster is starting
    if ($self->{params}->{node_number} == 1) {
        $self->{context}->{cluster}->setState(state => 'starting');
        $self->{context}->{cluster}->save();
    }

    my $createdisk_params   = $self->{context}->{cluster}->getManagerParameters(manager_type => 'DiskManager');
    my $createexport_params = $self->{context}->{cluster}->getManagerParameters(manager_type => 'ExportManager');

    # Create system image for node if required.
    if ($self->{params}->{create_systemimage} and $self->{context}->{masterimage}) {

        # Creation of the device based on distribution device
        my $container = $self->{context}->{disk_manager}->createDisk(
                            name       => $self->{context}->{systemimage}->systemimage_name,
                            size       => delete $createdisk_params->{systemimage_size},
                            # TODO: get this value from masterimage attrs.
                            filesystem => 'ext3',
                            erollback  => $self->{erollback},
                            %{ $createdisk_params }
                        );

        $log->debug('Container creation for new systemimage');

        # Create a temporary local container to access to the masterimage file.
        my $master_container = EEntity->new(entity => Entity::Container::LocalContainer->new(
                                   container_name       => $self->{context}->{masterimage}->masterimage_name,
                                   container_size       => $self->{context}->{masterimage}->masterimage_size,
                                   # TODO: get this value from masterimage attrs.
                                   container_filesystem => 'ext3',
                                   container_device     => $self->{context}->{masterimage}->masterimage_file,
                               ));

        # Copy the masterimage container contents to the new container
        $master_container->copy(dest      => $container,
                                econtext  => $self->getEContext,
                                erollback => $self->{erollback});

        # Remove the temporary container
        $master_container->remove();

        foreach my $comp ($self->{context}->{masterimage}->component_types) {
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
            push @accesses, $self->{context}->{export_manager}->createExport(
                                export_name  => $self->{context}->{systemimage}->systemimage_name,
                                iscsi_portal => $portal_id,
                                erollback    => $self->{erollback},
                                %{ $createexport_params }
                            );
        }

        # Activate the system by linking it to the container accesses
        $self->{context}->{systemimage}->activate(container_accesses => \@accesses,
                                                  erollback          => $self->{erollback});
    }
}

sub finish {
    my $self = shift;

    # Do not require masterimage in context any more.
    delete $self->{context}->{masterimage};

    # Do not require storage managers in context any more.
    delete $self->{context}->{disk_manager};
    delete $self->{context}->{export_manager};
}

sub _cancel {
    my $self = shift;

    if ($self->{context}->{cluster}) {
        if (! scalar(@{ $self->{context}->{cluster}->getHosts() })) {
            $self->{context}->{cluster}->setState(state => "down");
        }
    }

    if ($self->{context}->{host}) {
        $self->{context}->{host}->setState(state => "down");
    }
}

1;
