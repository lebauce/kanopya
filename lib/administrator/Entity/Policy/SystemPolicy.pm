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

=pod

=begin classdoc

The system policy defines the parameters describing how
a service provider configure the operatig system that will
install on disks for it's hosts.

@since    2012-Aug-16
@instance hash
@self     $self

=end classdoc

=cut

package Entity::Policy::SystemPolicy;
use base 'Entity::Policy';

use strict;
use warnings;

use Data::Dumper;
use Log::Log4perl 'get_logger';

use Clone qw(clone);

my $log = get_logger("");

use constant ATTR_DEF => {};

sub getAttrDef { return ATTR_DEF; }

use constant POLICY_ATTR_DEF => {
    masterimage_id => {
        label    => 'Master image',
        type     => 'relation',
        relation => 'single',
        pattern  => '^\d*$',
    },
    kernel_id => {
        label   => 'Kernel',
        type     => 'relation',
        relation => 'single',
        pattern  => '^\d*$',
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
                    is_editable => 1
                },
            }
        }
    },
};

sub getPolicyAttrDef { return POLICY_ATTR_DEF; }

my $merge = Hash::Merge->new('RIGHT_PRECEDENT');


=pod

=begin classdoc

Get the static policy attributes definition from the parent,
and merge with the policy type specific dynamic attributes
depending on attributes values given in parameters.

@return the dynamic attributes definition.

=end classdoc

=cut

sub getPolicyDef {
    my $self  = shift;
    my $class = ref($self) || $self;
    my %args  = @_;

    General::checkParams(args     => \%args,
                         optional => { 'set_mandatory'       => 0,
                                       'set_editable'        => 1,
                                       'set_params_editable' => 0 });

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

    my $policy_attrdef = clone($class->getPolicyAttrDef);

    # Manually add the systemimage_size attr because it is a manager param
    $policy_attrdef->{systemimage_size} = {
        label   => 'System image size',
        type    => 'integer',
        unit    => 'byte',
        pattern => '^\d*$',
    };

    $policy_attrdef->{kernel_id}->{options} = \@kernels;
    $policy_attrdef->{masterimage_id}->{options} = \@masterimages;
    $policy_attrdef->{components}->{attributes}->{attributes}->{component_type}->{options} = \@componenttypes;

    my $attributes = {
        displayed  => [ 'kernel_id', 'masterimage_id', 'systemimage_size', 'cluster_basehostname',
                        'cluster_si_persistent', 'cluster_si_shared' ],
        attributes => $policy_attrdef,
        relations  => {
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

    $self->setValues(attributes          => $attributes,
                     values              => \%args,
                     set_mandatory       => delete $args{set_mandatory},
                     set_editable        => delete $args{set_editable},
                     set_params_editable => delete $args{set_params_editable});

    return $attributes;
}


=pod

=begin classdoc

Handle system policy specific parameters to build
the policy pattern. Here, handle the list of component to install
by transforming the conpmponent array to a hash, and handle the param
systemimage_size that should be stored as disk_manager param in the
resulting pattern.

@return a policy pattern fragment

=end classdoc

=cut

sub getPatternFromParams {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'params' ]);

    my $pattern = $self->SUPER::getPatternFromParams(params => $args{params});

    if (ref($args{params}->{components}) eq 'ARRAY') {
        my %components = map { $_->{component_type} => $_ } @{ delete $args{params}->{components} };
        $pattern->{components} = \%components;
    }
    if (defined $args{params}->{systemimage_size}) {
        $pattern->{managers}->{disk_manager}->{manager_params}->{systemimage_size} = delete $args{params}->{systemimage_size};
    }
    return $pattern;
}

1;
