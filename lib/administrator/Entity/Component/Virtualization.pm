#    Copyright © 2011 Hedera Technology SAS
#
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

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

package Entity::Component::Virtualization;
use base "Entity::Component";

use strict;
use warnings;

use constant ATTR_DEF => {
    repositories => {
        label       => 'Virtual machine images repositories',
        type        => 'relation',
        relation    => 'single_multi',
        is_editable => 1,
    },
    overcommitment_cpu_factor => {
        label        => 'Overcommitment cpu factor',
        type         => 'string',
        pattern      => '^\d*\.?\d+$',
        is_mandatory => 0,
        is_editable  => 1
    },
    overcommitment_memory_factor => {
        label        => 'Overcommitment memory factor',
        type         => 'string',
        pattern      => '^\d*\.?\d+$',
        is_mandatory => 0,
        is_editable  => 1
    },
};

sub getAttrDef { return ATTR_DEF };

sub optimiaas {
    my $self = shift;

    $self->service_provider->getManager(manager_type => 'ExecutionManager')->run(
        name   => 'OptimiaasWorkflow',
        params => {
            context => {
                cloudmanager_comp => $self,
            }
        }
    );

}

sub getBaseConfiguration {
    return {
        overcommitment_cpu_factor => '1',
        overcommitment_memory_factor => '1'
    };
}


=pod

=begin classdoc

Return a list of active hypervisors whose nodes are 'in', ruled by this manager

@return a list of active hypervisors whose nodes are 'in', ruled by this manager

=end classdoc

=cut

sub activeAndInHypervisors {
    my $self = shift;

    my $active_hypervisors = $self->activeHypervisors;

    my @active_in_hypervisors;

    for my $active_hypervisor (@{$active_hypervisors}) {
        my ($state,$time_stamp) = $active_hypervisor->getNodeState();
        if ($state eq 'in') {
            push @active_in_hypervisors, $active_hypervisor;
        }
    }

    return @active_in_hypervisors;
}


sub getOvercommitmentFactors {
    my ($self) = @_;
    return {
        overcommitment_cpu_factor    => $self->overcommitment_cpu_factor,
        overcommitment_memory_factor => $self->overcommitment_memory_factor,
    }
}

1;
