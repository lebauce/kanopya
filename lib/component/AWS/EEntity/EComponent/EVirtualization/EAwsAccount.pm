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


=pod
=begin classdoc

Override the parent execution method to forward the call to the component entity.

@see <package>EManager::EHostManager</package>

=end classdoc
=cut

sub getFreeHost {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => [ 'flavor' ]);

    my %flavors = %{$self->param_preset->load->{flavors}};
    while (my ($flavor_id, $flavor) = each (%flavors)) {
        if ($flavor->{name} eq $args{flavor}) {
            $args{ram} = $flavor->{ram} * 1024 * 1024; # MB to B
            $args{core} = $flavor->{vcpus};
            last;
        }
    }
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

1;

