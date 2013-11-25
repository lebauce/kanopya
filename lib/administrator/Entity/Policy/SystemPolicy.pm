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

use Manager::HostManager;
use Manager::DiskManager;

use Entity::Masterimage;
use ClassType::ServiceProviderType;

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
        is_mandatory => 0
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

Build the dynamic attributes definition depending on attributes
values given in parameters.

@return the dynamic attributes definition.

=end classdoc
=cut

sub getPolicyDef {
    my $self  = shift;
    my $class = ref($self) || $self;
    my %args  = @_;

    General::checkParams(args     => \%args,
                         required => [ 'attributes' ],
                         optional => { 'params' => {}, 'trigger' => undef });

    # Add the dynamic attributes to displayed
    push @{ $args{attributes}->{displayed} }, 'kernel_id';
    push @{ $args{attributes}->{displayed} }, 'masterimage_id';
    push @{ $args{attributes}->{displayed} }, 'systemimage_size';
    push @{ $args{attributes}->{displayed} }, 'cluster_basehostname';
    push @{ $args{attributes}->{displayed} }, 'cluster_si_persistent';
    push @{ $args{attributes}->{displayed} }, 'cluster_si_shared';
    push @{ $args{attributes}->{displayed} }, 'deploy_on_disk';
    push @{ $args{attributes}->{displayed} }, { components => [ 'component_type' ] };

    # Add the components to the relations definition
    $args{attributes}->{relations}->{components} = {
        attrs    => { accessor => 'multi' },
        cond     => { 'foreign.policy_id' => 'self.policy_id' },
        resource => 'component'
    };

    my @masterimages;
    for my $masterimage (Entity::Masterimage->search(hash => {})) {
        push @masterimages, $masterimage->toJSON();
    }
    my @kernels;
    for my $kernel (Entity::Kernel->search(hash => {})) {
        push @kernels, $kernel->toJSON();
    }

    # Get the list of possible component types from the cluster type
    my $clustertype;
    if (defined $args{params}->{masterimage_id}) {
        $clustertype
            = Entity::Masterimage->get(id => $args{params}->{masterimage_id})->masterimage_cluster_type;
    }
    else {
        $clustertype = ClassType::ServiceProviderType->find(hash => {
                            service_provider_name => "Cluster"
                       });
    }
    my @componenttypes;
    for my $componenttype ($clustertype->search(related => 'component_types', hash => { deployable => 1 })) {
        push @componenttypes, $componenttype->toJSON();
    }

    # Manually add the systemimage_size and deploy_on_disk attrs because they are manager params
    $args{attributes}->{attributes}->{deploy_on_disk}
        = Manager::HostManager->getManagerParamsDef->{deploy_on_disk};

    $args{attributes}->{attributes}->{systemimage_size}
        = Manager::DiskManager->getManagerParamsDef->{systemimage_size};

    $args{attributes}->{attributes}->{systemimage_size}->{is_mandatory}
        = defined $args{params}->{masterimage_id} ? 1 : 0;

    $args{attributes}->{attributes}->{kernel_id}->{options} = \@kernels;
    $args{attributes}->{attributes}->{masterimage_id}->{options} = \@masterimages;
    $args{attributes}->{attributes}->{components}->{attributes}->{attributes}->{component_type}->{options}
        = \@componenttypes;

    return $args{attributes};
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
