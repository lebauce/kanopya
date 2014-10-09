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
use Manager::StorageManager;

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
    deployment_manager_id => {
        label        => "Deployment manager",
        type         => 'relation',
        relation     => 'single',
        pattern      => '^\d*$',
        reload       => 1,
        is_mandatory => 1,
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
    push @{ $args{attributes}->{displayed} }, 'masterimage_id';
    push @{ $args{attributes}->{displayed} }, 'systemimage_size';
    push @{ $args{attributes}->{displayed} }, 'cluster_basehostname';
    push @{ $args{attributes}->{displayed} }, 'cluster_si_persistent';
    push @{ $args{attributes}->{displayed} }, 'deployment_manager_id';

    my @masterimages;
    for my $masterimage (Entity::Masterimage->search(hash => {})) {
        push @masterimages, $masterimage->toJSON();
    }

    # Manually add the systemimage_size attrs because they are manager params
    $args{attributes}->{attributes}->{systemimage_size}
        = Manager::StorageManager->getManagerParamsDef->{systemimage_size};

    $args{attributes}->{attributes}->{systemimage_size}->{is_mandatory}
        = defined $args{params}->{masterimage_id} ? 1 : 0;

    $args{attributes}->{attributes}->{masterimage_id}->{options} = \@masterimages;

    # Build the list of deployment managers
    my $manager_options = {};
    for my $component (Entity::Component->search(custom => { category => 'DeploymentManager' })) {
        $manager_options->{$component->id} = $component->toJSON;
        $manager_options->{$component->id}->{label} = $component->label;
    }
    my @manageroptions = values %{$manager_options};
    $args{attributes}->{attributes}->{deployment_manager_id}->{options} = \@manageroptions;

    # If deployment_manager_id defined but do not corresponding to a available value,
    # it is an old value, so delete it.
    if (not $manager_options->{$args{params}->{deployment_manager_id}}) {
        delete $args{params}->{deployment_manager_id};
    }
    # If no disk_manager_id defined and and attr is mandatory, use the first one as value
    if (! $args{params}->{deployment_manager_id} && $args{set_mandatory}) {
        $self->setFirstSelected(name       => 'deployment_manager_id',
                                attributes => $args{attributes}->{attributes},
                                params     => $args{params});
    }

    if ($args{params}->{deployment_manager_id}) {
        # Get the deployment manager params from the selected deployment manager
        my $deploymentmanager = Entity->get(id => $args{params}->{deployment_manager_id});
        my $managerparams = $deploymentmanager->getDeploymentManagerParams(params => $args{params});

        for my $attrname (keys %{ $managerparams }) {
            $args{attributes}->{attributes}->{$attrname} = $managerparams->{$attrname};
            # If no value defined in params, use the first one
            if (! $args{params}->{$attrname} && $args{set_mandatory}) {
                $self->setFirstSelected(name       => $attrname,
                                        attributes => $args{attributes}->{attributes},
                                        params     => $args{params});
            }

            # If the attribute is a manager, set it as reload trigger as
            # it probably hav specific params too
            if ($attrname =~ m/.*_manager_id/) {
                $args{attributes}->{attributes}->{$attrname}->{reload} = 1;
            }

            # HCMDeploymentManager specific, should not be in the generic policy code
            if ($attrname eq "components") {
                push @{ $args{attributes}->{displayed} }, { components => [ 'component_type' ] };

                # Add the components to the relations definition
                $args{attributes}->{relations}->{components} = {
                    attrs    => { accessor => 'multi' },
                    cond     => { 'foreign.policy_id' => 'self.policy_id' },
                    resource => 'component'
                };
            }
            else {
                # Add the attribute to the displayed list
                push @{ $args{attributes}->{displayed} }, $attrname;
            }
        }
    }
    # Remove possibly defined value of attributes that depends on disk_manager_id.
    # (It is probably a first implementation of the full generic version of
    # manager management in policies...)
    else {
        for my $dependency (@{ $self->getPolicySelectorMap->{deployment_manager_id} }) {
            delete $args{params}->{$dependency};
        }
    }

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

    if (ref($args{params}->{components}) eq 'ARRAY') {
        my %components = map { 'component_' . $_->{component_type} => $_ }
                             @{ delete $args{params}->{components} };
        $args{params}->{components} = \%components;
    }

    my $pattern = $self->SUPER::getPatternFromParams(params => $args{params});

    if (defined $args{params}->{systemimage_size}) {
        $pattern->{managers}->{storage_manager}->{manager_params}->{systemimage_size}
            = delete $args{params}->{systemimage_size};
    }
    if (defined $args{params}->{boot_policy}) {
        $pattern->{managers}->{storage_manager}->{manager_params}->{boot_policy}
            = delete $args{params}->{boot_policy};
    }
    if (defined $args{params}->{deploy_on_disk}) {
        $pattern->{managers}->{host_manager}->{manager_params}->{deploy_on_disk}
            = delete $args{params}->{deploy_on_disk};
    }
    return $pattern;
}

1;
