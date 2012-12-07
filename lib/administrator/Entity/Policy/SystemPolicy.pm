# Copyright © 2011-2012 Hedera Technology SAS
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

package Entity::Policy::SystemPolicy;
use base 'Entity::Policy';

use strict;
use warnings;

use Data::Dumper;
use Log::Log4perl 'get_logger';

my $log = get_logger("");

use constant ATTR_DEF => {};

sub getAttrDef { return ATTR_DEF; }


my $merge = Hash::Merge->new('RIGHT_PRECEDENT');

sub getPolicyDef {
    my $self  = shift;
    my $class = ref($self) || $self;
    my %args  = @_;

    General::checkParams(args => \%args, optional => { 'set_mandatory' => 0 });

    %args = %{ $self->mergeValues(values => \%args) };

    my @masterimages;
    for my $masterimage (Entity::Masterimage->search(hash => {})) {
        push @masterimages, $masterimage->toJSON();
    }
    my @kernels;
    for my $kernel (Entity::Kernel->search(hash => {})) {
        push @kernels, $kernel->toJSON();
    }
    my @componenttypes;
    for my $componenttype (ComponentType->search(hash => {})) {
        push @componenttypes, $componenttype->toJSON();
    }

    my $attributes = {
        displayed  => [
            'masterimage_id', 'kernel_id', 'systemimage_size', 'cluster_si_shared',
            'cluster_si_persistent', 'cluster_basehostname'
        ],
        attributes =>  {
            masterimage_id => {
                label    => 'Master image',
                type     => 'relation',
                relation => 'single',
                pattern  => '^\d*$',
                options  => \@masterimages,
            },
            kernel_id => {
                label   => 'Kernel',
                type     => 'relation',
                relation => 'single',
                pattern  => '^\d*$',
                options  => \@kernels,
            },
            systemimage_size => {
                label   => 'System image size',
                type    => 'integer',
                unit    => 'byte',
                pattern => '^\d*$',
            },
            cluster_si_shared => {
                label   => 'System image shared',
                type    => 'boolean',
            },
            cluster_si_persistent => {
                label   => 'Persistent system images',
                type    => 'boolean',
            },
            cluster_basehostname => {
                label   => 'Cluster base hostname',
                type    => 'string',
                pattern => '^[a-z_0-9]+$',
            },
            components => {
                label       => 'Components',
                type        => 'relation',
                relation    => 'single_multi',
                is_editable => 1,
                attributes  => {
                    attributes => {
                        policy_id => {
                            type     => 'relation',
                            relation => 'single',
                        },
                        component_type => {
                            label       => 'Component type',
                            type        => 'relation',
                            relation    => 'single',
                            pattern     => '^\d*$',
                            options     => \@componenttypes,
                            is_editable => 1
                        },
                    }
                }
            },
        },
        relations => {
            components => {
                attrs    => { accessor => 'multi' },
                cond     => { 'foreign.policy_id' => 'self.policy_id' },
                resource => 'component'
            },
        },
    };

    push @{ $attributes->{displayed} }, {
        'components' => [ 'component_type' ]
    };

    # Complete the attributes with common ones
    $attributes = $merge->merge($self->SUPER::getPolicyDef(%args), $attributes);

    $self->setValues(attributes => $attributes, values => \%args);
    return $attributes;
}

1;
