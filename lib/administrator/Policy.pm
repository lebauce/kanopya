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

package Policy;
use base 'BaseDB';

use strict;
use warnings;

use ParamPreset;
use Entity::InterfaceRole;
use Entity::ServiceProvider::Inside::Cluster;

use Hash::Merge;

use Data::Dumper;
use Log::Log4perl 'get_logger';

my $log = get_logger('administrator');

use constant ATTR_DEF => {
    policy_name => {
        pattern      => '^.*$',
        is_mandatory => 1,
        is_extended  => 0
    },
    policy_desc => {
        pattern      => '^.*$',
        is_mandatory => 0,
        is_extended  => 0
    },
    policy_type => {
        pattern      => '^.*$',
        is_mandatory => 1,
        is_extended  => 0
    },
    param_preset_id => {
        pattern      => '^\d*$',
        is_mandatory => 0,
        is_extended  => 0
    },
};

sub getAttrDef { return ATTR_DEF; }

sub methods {
    return {
        'getFlattenedHash' => {
            'description' => 'Return a single level hash with all attributes and values of the policy',
            'perm_holder' => 'entity',
        },
    };
}

sub new {
    my $class = shift;
    my %args = @_;
    my $self;

    # Firstly pop the policy atrributes
    my $attrs = {
        policy_name => delete $args{policy_name},
        policy_type => delete $args{policy_type},
        policy_desc => delete $args{policy_desc},
    };

    $log->info(Dumper($attrs));

    # Pop the policy id if defined
    my $policy_id = delete $args{policy_id};

    # If policy_id defined, this is a policy update.
    if ($policy_id) {
        $self = Policy->get(id => $policy_id);

        # Set the policy atrributtes
        for my $name (keys %$attrs) {
            $self->setAttr(name => $name, value => $attrs->{$name});
        }
        $self->save();

        # Remove the old policy configuration parttern.
        my $presets = ParamPreset->get(id => $self->getAttr(name => 'param_preset_id'));

        # Build the policy pattern from
        my $pattern = $class->buildPatternFromHash(policy_type => $attrs->{policy_type}, hash => \%args);
        $presets->update(params => $pattern, override => 1);
    }
    # Else this a policy creation
    else {
        $class->checkAttrs(attrs => $attrs);

        # Build the policy pattern from
        my $pattern = $class->buildPatternFromHash(policy_type => $attrs->{policy_type}, hash => \%args);
        my $preset  = ParamPreset->new(name => $attrs->{policy_type} . '_policy', params => $pattern);
        $attrs->{param_preset_id} = $preset->getAttr(name => 'param_preset_id');

        $self = $class->SUPER::new(%$attrs);
    }
    return $self;
}

sub buildPatternFromHash {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'policy_type', 'hash' ]);

    my %pattern;
    my $merge = Hash::Merge->new('RIGHT_PRECEDENT');

    # Build the complette list of cluster attributes.
    my $cluster_attrs;
    my $attributes_def = Entity::ServiceProvider::Inside::Cluster->getAttrDefs();
    foreach my $module (keys %$attributes_def) {
        $cluster_attrs = $merge->merge($cluster_attrs, $attributes_def->{$module});
    }

    # Transform the policy form hash to a cluster configuration pattern
    for my $name (keys %{$args{hash}}) {
        # Handle defined values only
        if (defined $args{hash}->{$name} and $args{hash}->{$name} ne '') {
            # Handle managers
            if ($name =~ m/_manager_id/) {
                my $manager_type = $name;
                $manager_type =~ s/_id$//g;

                # Set the manager infos
                $pattern{managers}->{$manager_type} = {
                    manager_id   => $args{hash}->{$name},
                    manager_type => $manager_type
                };

                # Set the manager params if required
                my $manager = Entity->get(id => $args{hash}->{$name});
                my @params = map { $_->{name} } @{ $manager->getPolicyParams(policy_type => $args{policy_type}) };
                for my $param (@params) {
                    if (defined $args{hash}->{$param} and $args{hash}->{$param}) {
                        $pattern{managers}->{$manager_type}->{manager_params}->{$param} = $args{hash}->{$param};
                    }
                }
            }
            # Handle components
            elsif ($name =~ m/^component_type_/) {
                $pattern{components}->{'component_' . $args{hash}->{$name}}->{component_type} = $args{hash}->{$name};
            }
            # Handle networks interfaces
            elsif ($name =~ m/^interface_role_/) {
                # Get the intefrace role name
                my $role_name = Entity::InterfaceRole->get(id => $args{hash}->{$name})->getAttr(name => 'interface_role_name');
                $pattern{interfaces}->{$role_name}->{interface_role} = $args{hash}->{$name};

                my $interface_index = $name;
                $interface_index =~ s/^interface_role_//g;
                if ($args{hash}->{'interface_networks_' . $interface_index}) {
                    $pattern{interfaces}->{$role_name}->{interface_networks} = [ $args{hash}->{'interface_networks_' . $interface_index} ];
                }
            }
            # Can we handle this param whithout hard code  ?
            elsif ($name eq 'systemimage_size') {
                $pattern{managers}->{disk_manager}->{manager_params}->{$name} = $args{hash}->{$name};
            }
            # Handle cluster attributtes.
            elsif (exists $cluster_attrs->{$name}) {
                # TODO: checkAttr
                $pattern{$name} = $args{hash}->{$name};
            }
        }
    }

    $log->debug("Returning configuration pattern for a $args{policy_type} policy:\n" . Dumper(\%pattern));
    return \%pattern;
}

sub getFlattenedHash {
    my $self = shift;
    my %args = @_;

    my %flat_hash;
    my $pattern = ParamPreset->get(id => $self->getAttr(name => 'param_preset_id'))->load();

    # Transform the policy configuration pattern to a flat hash
    for my $name (keys %$pattern) {
        # Handle managers
        if ($name eq 'managers') {
            for my $manager_type (keys %{$pattern->{$name}}) {
                # Set the manager id
                $flat_hash{$manager_type . '_id'} = $pattern->{$name}->{$manager_type}->{manager_id};

                # Set the manager parameters
                for my $manager_param (keys %{$pattern->{$name}->{$manager_type}->{manager_params}}) {
                    $flat_hash{$manager_param} = $pattern->{$name}->{$manager_type}->{manager_params}->{$manager_param};
                }
            }
        }
        # Handle components
        elsif ($name eq 'components') {
            for my $component (values %{ $pattern->{$name} }) {
                if (not defined $flat_hash{'component_type'}) {
                    $flat_hash{'component_type'} = [];
                }
                push @{ $flat_hash{'component_type'} }, $component->{component_type};
            }
        }
        # Handle network interfaces
        elsif ($name eq 'interfaces') {
            for my $interface (values %{ $pattern->{$name} }) {
                if (not defined $flat_hash{'network_interface'}) {
                    $flat_hash{'network_interface'} = [];
                }

                # For instance, do not return a list of network, as we are not able
                # to handle mutliple network association to one interface.
                if (defined $interface->{interface_networks} and ref($interface->{interface_networks}) eq 'ARRAY' and
                    scalar($interface->{interface_networks})) {
                    $interface->{interface_networks} = $interface->{interface_networks}[0];
                }
                push @{ $flat_hash{'network_interface'} }, $interface;
            }
        }
        else {
            $flat_hash{$name} = $pattern->{$name};
        }
    }

    $log->debug("Returning flattened policy hash:\n" . Dumper(\%flat_hash));
    return \%flat_hash;
}

sub getParamPreset {
    my $self = shift;
    my %args = @_;

    return ParamPreset->get(id => $self->getAttr(name => 'param_preset_id'));
}

1;
