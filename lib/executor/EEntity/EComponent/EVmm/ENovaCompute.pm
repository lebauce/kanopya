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

package EEntity::EComponent::EVmm::ENovaCompute;
use base "EEntity::EComponent::EVmm";

use strict;
use warnings;

use EEntity;
use Hash::Merge qw(merge);
use OpenStack::API;

my $resources_keys = {
    ram => { name => 'ram' },
    cpu => { name => 'vcpus' },
};

sub postStartNode {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'cluster', 'host' ]);

    # The Puppet manifest is compiled a first time and requests the creation
    # of the database on the database cluster
    $self->SUPER::postStartNode(%args);

    # We ask :
    # - the database cluster to create databases and users
    # - Keystone to create endpoints, users and roles
    # - AMQP to create queues and users
    for my $component ($self->mysql5, $self->nova_controller->amqp, $self->nova_controller->keystone) {
        if ($component) {
            EEntity->new(entity => $component->service_provider)->reconfigure();
        }
    }

    # Now apply the manifest again
    $self->SUPER::postStartNode(%args);
}

=pod

=begin classdoc

Return the amount of available memory on a given hypervisor

@param host the pondered hypervisor

@return the available memory

=cut

sub getAvailableMemory {
    my ($self, %args) = @_;
 
    General::checkParams(args => \%args, required => [ "host" ],);

    my $host = $args{host};
    my $hostname = $host->node->node_hostname;
	my $e_controller = EEntity->new(entity => $self->nova_controller);

    my $host_details = $e_controller->api->tenant(id => $e_controller->api->{tenant_id} . '/os-hypervisors/detail')
                           ->get(target => 'compute')->{hypervisors};

    my ($hypervisor) = grep { $_->{hypervisor_hostname} eq $host->fqdn } @$host_details;

    my $memory = {
        mem_effectively_available   => $hypervisor->{free_ram_mb} * 1025 * 1024,
        mem_theoretically_available => ($host->host_ram * $e_controller->overcommitment_memory_factor) -
                                       ($hypervisor->{memory_mb_used} * 1024 * 1024),
    };

    return $memory;
}

=pod

=begin classdoc

Retrieve resources attributed to a vm

@param host an hypervisor hosting vms
@optional resources the list of desired resources
@optional vm the vm to probe

@return vms_resources a hash listing the resources per vm

=end classdoc

=cut

sub getVmResources {
    my ($self, %args) = @_;

    General::checkParams(
        args     => \%args,
        required => [ 'host' ],
        optional => { vm => undef, resources => [ 'ram', 'cpu' ] }
    );

    # If no vm specified, get resssources for all hypervisor vms.
    my @vms;
    if (not defined $args{vm}) {
        @vms = $args{host}->getVms;
    } else {
        push @vms, $args{vm};
    }
    
    my $vms_resources = {};

    for my $vm (@vms) {
        # we get the flavor of the vm
        my $uuid = $vm->openstack_vm_uuid;
        my $e_controller = EEntity->new(entity=> $self->nova_controller);
 
        my $details = $e_controller->api->tenant(id => $e_controller->api->{tenant_id})
                          ->servers(id => $uuid)
                          ->get(target => 'compute');

        my $flavor = $details->{server}->{flavor}->{id};

        #get the flavor's details
        my $f_details = $e_controller->api->tenant(id => $e_controller->api->{tenant_id})
                          ->flavors(id => $flavor)
                          ->get(target => 'compute');
   
        my $vm_resources = {};
        for my $resource (@{ $args{resources} }) {
			$vm_resources->{$vm->id}->{$resource} =
				$f_details->{flavor}->{$resources_keys->{$resource}->{name}};
        }

		$vms_resources = merge($vms_resources, $vm_resources);
    }

    return $vms_resources;
}

=pod

=begin classdoc

Return the amount of ram used by a given openstack vm

@param host the desired vm

@return detail of used, swaped and total RAM

=end classdoc

=cut

sub getRamUsedByVm {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [ 'host', 'hypervisor' ]);

    my $vm = $args{host};
    my $e_hypervisor = $args{hypervisor};
    my $vm_uuid = $vm->openstack_vm_uuid;
    my $e_controller = EEntity->new(entity=> $self->nova_controller);

    my $details = $e_controller->api->tenant(id => $e_controller->api->{tenant_id})
                      ->servers(id => $vm_uuid)
                      ->diagnostics
                      ->get(target => 'compute');

	#TODO find a way to retrieve swapped memory for the vm
    return {
        mem_ram  => $details->{'memory-rss'},
        mem_swap => undef,
        total    => $details->{'memory-rss'},
    }
}

1;
