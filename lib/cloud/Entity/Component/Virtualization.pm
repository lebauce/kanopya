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

=pod
=begin classdoc

TODO

=end classdoc
=cut

package Entity::Component::Virtualization;
use base "Entity::Component";

use strict;
use warnings;

use constant ATTR_DEF => {
    executor_component_id => {
        label        => 'Workflow manager',
        type         => 'relation',
        relation     => 'single',
        pattern      => '^[0-9\.]*$',
        is_mandatory => 1,
        is_editable  => 0,
    },
    repositories => {
        label       => 'Virtual machine images repositories',
        type        => 'relation',
        relation    => 'single_multi',
        is_editable => 1,
        description => 'Where VM images are stored',
    },
    hypervisors => {
        label       => 'Hypervisors',
        type        => 'relation',
        relation    => 'single_multi',
        is_editable => 1,
        description => 'The list of hypervisors in this virtualisation manager',
    },
    overcommitment_cpu_factor => {
        label        => 'Overcommitment cpu factor',
        type         => 'integer',
        pattern      => '^\d*\.?\d+$',
        is_mandatory => 0,
        is_editable  => 0,
        description  => 'Set a ratio for CPU Overcommitment',
    },
    overcommitment_memory_factor => {
        label        => 'Overcommitment memory factor',
        type         => 'integer',
        pattern      => '^\d*\.?\d+$',
        is_mandatory => 0,
        is_editable  => 0,
        description  => 'Set a ratio for Memory Overcommitment',
    },
};

sub getAttrDef { return ATTR_DEF };

sub optimiaas {
    my ($self, %args) = @_;
    General::checkParams(
        args     => \%args,
        optional => {
            policy => 'stack',
        }
    );

    $self->executor_component->run(
        name   => 'OptimiaasWorkflow',
        params => {
            context => {
                cloudmanager_comp => $self,
            },
            policy => $args{policy},
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

Promote a host to the Entity::Host::Hypervisor class

@return OpenstackHypervisor instance of OpenstackHypervisor

=end classdoc
=cut

sub addHypervisor {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);

    return Entity::Host::Hypervisor->promote(promoted => $args{host}, iaas_id => $self->id);
}


=pod
=begin classdoc

@return a list of active hypervisors

=end classdoc
=cut

sub activeHypervisors {
    my $self = shift;

    my @hypervisors = $self->search(related  => 'hypervisors',
                                    hash     => { active => 1 },
                                    prefetch => [ 'node' ]);

    return \@hypervisors;
}


=pod
=begin classdoc

@return a list of active hypervisors whose nodes are 'in', ruled by this manager

=end classdoc
=cut

sub activeAndInHypervisors {
    my $self = shift;

    my $active_hypervisors = $self->activeHypervisors;

    my @active_in_hypervisors;
    for my $active_hypervisor (@{ $active_hypervisors }) {
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
