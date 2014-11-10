#    Copyright © 2014 Hedera Technology SAS
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

=pod
=begin classdoc

Execution lib for the AWS component.

@see <package>Entity::Component::Virtualization::AwsAccount</package>

=end classdoc
=cut

package EEntity::EComponent::EVirtualization::EAwsAccount;
use parent EEntity::EComponent::EVirtualization;
use parent EManager::EHostManager::EVirtualMachineManager;

use strict;
use warnings;

use AwsInstanceType;

=pod
=begin classdoc

Override the parent execution method to forward the call to the component entity.

@see <package>EManager::EHostManager</package>

=end classdoc
=cut

sub getFreeHost {
    my ($self, %args) = @_;
    # General::checkParams(args => \%args, required => [ 'type' ]);
    return $self->_entity->getFreeHost(%args);
}

=pod
=begin classdoc

Create and start a virtual machine from the given parameters by calling the nova api.

@see <package>Manager::HostManager</package>

=end classdoc
=cut

sub startHost {
    my ($self, %args) = @_;
    return $self->_entity->startHost(%args);
}

=pod
=begin classdoc

Query AWS to register a "virtual" hypervisor, existing virtual machines
and all available options.

=end classdoc
=cut

sub synchronize {
    my ($self, %args) = @_;
    return $self->_load(infra => $self->_ec2->getInfrastructure);
}


=pod
=begin classdoc

Terminate a host

=end classdoc
=cut

sub halt {
    my ($self, %args) = @_;
    return $self->_entity->halt(%args);
}


sub stopHost {
    my ($self, %args) = @_;
    return $self->_entity->stopHost(%args);
}

sub releaseHost {
    my ($self, %args) = @_;
    return $self->_entity->releaseHost(%args);
}

sub postStart {
    my ($self, %args) = @_;
    return $self->_entity->postStart(%args);
}

sub getHypervisorVMs {
    my ($self, %args) = @_;
    return $self->_entity->getHypervisorVMs(%args);
}

sub getVMDetails {
    my ($self, %args) = @_;
    return $self->_entity->getVMDetails(%args);
}

sub increaseConsumers {
    my ($self, %args) = @_;
    return $self->_entity->increaseConsumers(%args);
}

sub decreaseConsumers {
    my ($self, %args) = @_;
    return $self->_entity->decreaseConsumers(%args);
}

=begin classdoc

Create AWS VMs with given instance IDs.

@param vm_uuids (Hashref) A hash of VM Instance IDs to Hypervisor (Host) IDs

=end classdoc

=cut

sub repairVmInInfraUnkInDB {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => [ 'vm_uuids' ]);
    my $vm_infos = $self->_entity->_ec2->getInstances(
        use_cache_if_not_older_than => 10
    );
    
    while (my ($vm_uuid, $hv_id) = each (%{$args{vm_uuids}})) {
        my $instance_id = $self->_entity->_removeAwsPrefix($vm_uuid);
        my $vm_info = $vm_infos->get($instance_id);
                
        $self->_entity->createAwsVirtualHost(
            aws_instance_type => $vm_info->{type},
            instance_id       => $instance_id,
            hypervisor_id     => $hv_id,
            mac_address       => $vm_info->{mac_addr}
        );
    }
}


=pod

=begin classdoc

Synchronize VM RAM and cores with infrastructure

@param host (Host) Hypervisor

=end classdoc

=cut

sub repairVMRessourceIntegrity {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => [ 'host' ]);

    my $vm_infos = $self->_entity->_ec2->getInstances(
        use_cache_if_not_older_than => 10
    );

    for my $vm ($args{host}->virtual_machines) {
        my $instance_id = $self->_entity->_removeAwsPrefix($vm->host_serial_number);
        my $vm_info = $vm_infos->get($instance_id);
        my $aws_it = AwsInstanceType->getType(name => $vm_info->{type});
        
        # Micro-benchmark shows: no need to check for change of values.
        # update() won't do useless SQL UPDATEs.
        $vm->update(
            host_ram  => $aws_it->ram,
            host_core => $aws_it->cpu
        );
    }
}

=cut
=begin classdoc

Ensure that a freshly started VM has its own admin IP. 
Called by EKanopyaDeploymentManager::checkNodeUp.

@param node (Entity::Node) The Host instance

@return Boolean (1 or 0), whether the node is up

=end classdoc
=cut

sub checkUp {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => [ 'host' ]);
    my $node = $args{host}->node;
    return 0 if defined $node->admin_ip_addr;
    
    my $aws = $self->_entity;
    
    my $instance_id = $aws->_removeAwsPrefix($args{host}->host_serial_number);
    my $vm_info = $aws->_ec2->getInstances(InstanceId => [$instance_id])->arrayref->[0];
    $aws->setNodeState(node => $node, vm_info => $vm_info);    
    
    if (defined $vm_info->{ip}) {
        $node->update(admin_ip_addr => $vm_info->{ip});
        return 0;
    } else {
        return 10;
    }
}


1;
