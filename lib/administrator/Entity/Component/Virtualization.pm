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
        pattern      => '^\d*$',
        is_mandatory => 1,
        is_editable  => 1
    },
    overcommitment_memory_factor => {
        label        => 'Overcommitment memory factor',
        type         => 'string',
        pattern      => '^\d*$',
        is_mandatory => 1,
        is_editable  => 1
    },
};

sub getAttrDef { return ATTR_DEF };

sub optimiaas {
    my ($self, %args) = @_;
    my $wf_params = {
        context => {
            cloudmanager_comp => $self,
        }
    };

    return Entity::Workflow->run(name => 'OptimiaasWorkflow', params => $wf_params);
}

sub getBaseConfiguration {
    return {
        overcommitment_cpu_factor => '1',
        overcommitment_memory_factor => '1'
    };
}

sub getOvercommitmentFactors {
    my ($self) = @_;
    return {
        overcommitment_cpu_factor    => $self->overcommitment_cpu_factor,
        overcommitment_memory_factor => $self->overcommitment_memory_factor,
    }
}

sub getPuppetDefinition {
    my ($self, %args) = @_;

    my $definitions = "\n";

    return {
        manifest     => $definitions,
        dependencies => []
    };
}

1;
