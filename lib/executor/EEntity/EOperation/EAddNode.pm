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
use Entity::ServiceProvider::Inside::Cluster;
use Entity::Masterimage;
use Entity::Systemimage;
use Entity::Host;
use CapacityManagement;
use Entity::Workflow;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");
my $errmsg;


sub prerequisites {
    my ($self, %args) = @_;

    General::checkParams(args => $self->{context}, required => [ "cluster" ]);

    if (defined $self->{params}->{remediation_workflow_id}){

        my $wf = Entity::Workflow->get(id => $self->{params}->{remediation_workflow_id});
        $log->info('Remediation workflow <'.($self->{params}->{remediation_workflow_id}).'> STATE <'.($wf->getAttr(name => 'state')).'> ');

        if($wf->getAttr(name => 'state') eq 'cancelled') {
            $log->info('Remediation workflow <'.($self->{params}->{remediation_workflow_id}).'> cancelled, EXCEPTION');
            throw Kanopya::Exception::Internal(error => 'Remediation workflow <'.($self->{params}->{remediation_workflow_id}).'> has been cancelled');
        }
        elsif ($wf->getAttr(name => 'state') eq 'done') {
            $log->info('Remediation workflow <'.($self->{params}->{remediation_workflow_id}).'> done, let us continue');
            # HERE NO RETURN => CONTINUE AFTER THE IF
        }
        elsif ($wf->getAttr(name => 'state') eq 'running') {
            $log->info('Remediation workflow <'.($self->{params}->{remediation_workflow_id}).'> still running, waiting for its end');
            return 20;
        }
        else {
            $log->info('Remediation workflow <'.($self->{params}->{remediation_worfklow_id}).'> status unknown : '.($wf->getAttr(name => 'state')).', EXCEPTION');
            throw Kanopya::Exception::Internal(error => 'Remediation workflow <'.($self->{params}->{remediation_workflow_id}).'> has been cancelled');
        }
    }

    my $cluster = $self->{context}->{cluster};
    my $host_type = $cluster->getHostManager->hostType;

    if($host_type eq 'Virtual Machine') {

        $self->{context}->{host_manager} = EFactory::newEEntity(
                                               data => $cluster->getManager(manager_type => 'host_manager'),
                                           );

        my @hvs   = $self->{context}->{host_manager}->hypervisors;
        my @hv_in_ids;
        for my $hv (@hvs) {
            my ($state,$time_stamp) = $hv->getNodeState();
            $log->info('hv <'.($hv->getId()).'>, state <'.($state).'>');
            if($state eq 'in') {
                push @hv_in_ids, $hv->getId();
            }
        }
        $log->info("Hvs selected <@hv_in_ids>");

        my $host_manager_params = $cluster->getManagerParameters(manager_type => 'host_manager');
        $log->info('host_manager_params :'.(Dumper $host_manager_params));

        my $cm = CapacityManagement->new(
                     cloud_manager => $self->{context}->{host_manager},
                 );

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
            my $hv_cluster = $self->{context}->{host_manager}->getServiceProvider();
            my $wf = $hv_cluster->addNode();
            $self->{params}->{remediation_workflow_id} = $wf->getAttr(name => 'workflow_id');

            $log->info('Launch remediation workflow id <'.($self->{params}->{remediation_workflow_id}).'>');
            return 15;
        }
   }
   else {   #Physical
       return 0
   }
}
=head2 prepare

    $op->prepare();

=cut

sub prepare {
    my $self = shift;
    my %args = @_;
    $self->SUPER::prepare();

    General::checkParams(args => $self->{context}, required => [ "cluster" ]);

    # Get the disk manager for disk creation
    my $disk_manager = $self->{context}->{cluster}->getManager(manager_type => 'disk_manager');
    $self->{context}->{disk_manager} = EFactory::newEEntity(data => $disk_manager);

    # Get the export manager for disk creation
    my $export_manager = $self->{context}->{cluster}->getManager(manager_type => 'export_manager');
    $self->{context}->{export_manager} = EFactory::newEEntity(data => $export_manager);

    # Get the masterimage for node systemimage creation.
    if ($self->{context}->{cluster}->masterimage) {
        $self->{context}->{masterimage} = EEntity->new(entity => $self->{context}->{cluster}->masterimage);
    }

    # Check if a host is specified.
    if (defined $self->{context}->{host}) {
        my $host_manager_id = $self->{context}->{host}->host_manager_id;
        my $cluster_host_manager_id = $self->{context}->{cluster}->getManager(manager_type => 'host_manager')->id;

        # Check if the specified host is managed by the cluster host manager
        if ($host_manager_id != $cluster_host_manager_id) {
            $errmsg = "Specified host <$args{host_id}>, is not managed by the same host manager than the " .
                      "cluster one (<$host_manager_id>) ne <$cluster_host_manager_id).";
            throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
        }
    }

    $self->{params}->{node_number} = $self->{context}->{cluster}->getNewNodeNumber();
    $log->debug("Node number for this new node: $self->{params}->{node_number} ");

    my $maxnode = $self->{context}->{cluster}->cluster_max_node;
    if ($maxnode < $self->{params}->{node_number}) {
        throw Kanopya::Exception::Internal::WrongValue(error => "Too many nodes, limited to " . $maxnode);
    }

    my $systemimage_name = $self->{context}->{cluster}->cluster_name . '_' .
                           $self->{params}->{node_number};

    # Check for existing systemimage for this node.
    my $existing_image;
    eval {
        $existing_image = Entity::Systemimage->find(hash => { systemimage_name => $systemimage_name });
    };

    # If systemimage context defined, force to use it.
    # If systemimage already exist for this node, use it.
    if (not $self->{context}->{systemimage}) {
        if ($existing_image) {
            $log->info("Using existing systemimage instance <$systemimage_name>");
            $self->{context}->{systemimage} = EFactory::newEEntity(data => $existing_image);
        }
        # Else if it is the first node, or the cluster si policy is dedicated, create a new one.
        elsif (($self->{params}->{node_number} == 1) or (not $self->{context}->{cluster}->cluster_si_shared)) {
            $log->info("A new systemimage instance <$systemimage_name> must be created");

            my $systemimage_desc = 'System image for node ' . $self->{params}->{node_number}  .' in cluster ' .
                                   $self->{context}->{cluster}->getAttr(name => 'cluster_name') . '.';

            eval {
               my $entity = Entity::Systemimage->new(systemimage_name => $systemimage_name,
                                                     systemimage_desc => $systemimage_desc);
               $self->{context}->{systemimage} = EFactory::newEEntity(data => $entity);
            };
            if($@) {
                throw Kanopya::Exception::Internal::WrongValue(error => $@);
            }
            $self->{params}->{create_systemimage} = 1;
        }
        # Else if it is the firest node, or the cluster si policy is dedicated, create a new one.
        else {
            $self->{context}->{systemimage} = EFactory::newEEntity(
                                                  data => $self->{context}->{cluster}->getMasterNodeSystemimage
                                              );
        }
    }
}

sub execute {
    my $self = shift;
    $self->SUPER::execute();

    if (not defined $self->{context}->{host}) {
        # Just call Master node addition, other node will be add by the state manager
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

    my $createdisk_params   = $self->{context}->{cluster}->getManagerParameters(manager_type => 'disk_manager');
    my $createexport_params = $self->{context}->{cluster}->getManagerParameters(manager_type => 'export_manager');

    # Create system image for node if required.
    if ($self->{params}->{create_systemimage} and $self->{context}->{masterimage}) {

        # Creation of the device based on distribution device
        my $container = EEntity->new(entity => $self->{context}->{disk_manager}->createDisk(
                            name       => $self->{context}->{systemimage}->systemimage_name,
                            size       => delete $createdisk_params->{systemimage_size},
                            # TODO: get this value from masterimage attrs.
                            filesystem => 'ext3',
                            erollback  => $self->{erollback},
                            %{ $createdisk_params }
                        ));

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
        my $hosts = $self->{context}->{cluster}->getHosts();
        if (! scalar keys %$hosts) {
            $self->{context}->{cluster}->setState(state => "down");
        }
    }

    if ($self->{context}->{host}) {
        $self->{context}->{host}->setState(state => "down");
    }
}

1;
