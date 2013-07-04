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
        label        => 'Master image',
        type         => 'relation',
        relation     => 'single',
        pattern      => '^\d*$',
        reload       => 1,
    },
    kernel_id => {
        label        => 'Kernel',
        type         => 'relation',
        relation     => 'single',
        pattern      => '^\d*$',
    },
    cluster_si_shared => {
        label        => 'System image shared',
        type         => 'boolean',
        is_mandatory => 1
    },
    cluster_si_persistent => {
        label        => 'Persistent system images',
        type         => 'boolean',
        is_mandatory => 1
    },
    cluster_basehostname => {
        label        => 'Cluster base hostname',
        type         => 'string',
        pattern      => '^[A-Za-z0-9]+$',
        is_mandatory => 1
    },
    components => {
        label        => 'Components',
        type         => 'relation',
        relation     => 'single_multi',
        is_editable  => 1,
        is_mandatory => 1,
        attributes   => {
            attributes => {
                policy_id => {
                    type     => 'relation',
                    relation => 'single',
                },
                component_type => {
                    label        => 'Component type',
                    type         => 'relation',
                    relation     => 'single',
                    pattern      => '^\d*$',
                    is_mandatory => 1,
                    is_editable  => 1
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
                         optional => { 'params'              => {},
                                       'set_mandatory'       => 0,
                                       'set_editable'        => 1,
                                       'set_params_editable' => 0 });

    # Merge params wirh existing values
    $args{params} = $self->processParams(%args);

    # Complete the attributes with common ones
    my $attributes = $self->SUPER::getPolicyDef(%args);

    my $displayed = [ 'kernel_id', 'masterimage_id',  'systemimage_size', 'cluster_basehostname',
                      'cluster_si_persistent', 'cluster_si_shared', 'deploy_on_disk' ];
    $attributes = $merge->merge($attributes, { displayed => $displayed });

    my @masterimages;
    for my $masterimage (Entity::Masterimage->search(hash => {})) {
        push @masterimages, $masterimage->toJSON();
    }
    my @kernels;
    for my $kernel (Entity::Kernel->search(hash => {})) {
        push @kernels, $kernel->toJSON();
    }
    my @componenttypes;
    for my $componenttype (ClassType::ComponentType->search(hash => {})) {
        push @componenttypes, $componenttype->toJSON();
    }

    # Manually add the systemimage_size and deploy_on_disk attrs because they are manager params
    $attributes->{attributes}->{deploy_on_disk} = {
        label        => 'Deploy on hard disk',
        type         => 'boolean',
        pattern      => '^\d*$',
        is_mandatory => 1
    };

    $attributes->{attributes}->{systemimage_size} = {
        label        => 'System image size',
        type         => 'integer',
        unit         => 'byte',
        pattern      => '^\d*$',
        is_mandatory => defined $args{params}->{masterimage_id} ? 1 : 0,
    };
    # Insert systemimage_size after
    splice @{ $attributes->{displayed} }, 2, 0, 'systemimage_size';

    $attributes->{attributes}->{kernel_id}->{options} = \@kernels;
    $attributes->{attributes}->{masterimage_id}->{options} = \@masterimages;
    $attributes->{attributes}->{components}->{attributes}
        ->{attributes}->{component_type}->{options} = \@componenttypes;

    $attributes->{relations} = {
        components => {
            attrs    => { accessor => 'multi' },
            cond     => { 'foreign.policy_id' => 'self.policy_id' },
            resource => 'component'
        },
    },

    push @{ $attributes->{displayed} }, {
        'components' => [ 'component_type' ]
    };

    $self->setValues(attributes          => $attributes,
                     values              => $args{params},
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
    if (defined $args{params}->{deploy_on_disk}) {
        $pattern->{managers}->{host_manager}->{manager_params}->{deploy_on_disk} = delete $args{params}->{deploy_on_disk};
    }
    return $pattern;
}

1;
