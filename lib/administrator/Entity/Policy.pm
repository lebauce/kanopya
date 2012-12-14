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

package Entity::Policy;
use base 'Entity';

use strict;
use warnings;

use ParamPreset;
use Entity::ServiceProvider::Inside::Cluster;
use Entity::Network;
use Entity::Netconf;
use Entity::Masterimage;
use Entity::Kernel;
use ComponentType;

use Data::Dumper;
use Log::Log4perl 'get_logger';

use POSIX qw[strftime];

my $log = get_logger("");

use constant ATTR_DEF => {
    policy_name => {
        label        => 'Policy name',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1,
    },
    policy_desc => {
        label        => 'Description',
        type         => 'text',
        pattern      => '^.*$',
        is_mandatory => 0,
        is_editable  => 1,
    },
    policy_type => {
        pattern      => '^.*$',
        is_mandatory => 1,
    },
    param_preset_id => {
        pattern      => '^\d*$',
        is_mandatory => 0,
    },
};

sub getAttrDef { return ATTR_DEF; }

sub methods {
    return {
        getPolicyDef => {
            description => 'build the policy definition in function of policy attributes values.',
        },
    };
}


my $merge = Hash::Merge->new('LEFT_PRECEDENT');

sub new {
    my $class = shift;
    my %args = @_;

    # Firstly pop the policy atrributes
    my $attrs = {
        policy_name => delete $args{policy_name},
        policy_type => delete $args{policy_type},
        policy_desc => delete $args{policy_desc},
    };

    $class->checkAttrs(attrs => $attrs);

    # Build the policy pattern from
    my $pattern = $class->buildPattern(policy_type => $attrs->{policy_type}, hash => \%args);
    my $preset  = ParamPreset->new(params => $pattern);
    $attrs->{param_preset_id} = $preset->id;

    my $self = $class->SUPER::new(%$attrs);

    # Add the concrete policy to the Policy master group
    Entity::Policy->getMasterGroup->appendEntity(entity => $self);

    return $self;
}

sub toJSON {
    my ($self, %args) = @_;
    my $class = ref($self) || $self;

    General::checkParams(args => \%args, optional => { 'model' => undef });

    my $json = $self->SUPER::toJSON(%args);

    if (not $args{model}) {
        $json = $self->mergeValues(values => $json);
    }
    return $json;
}

sub update {
    my $self  = shift;
    my $class = ref($self) || $self;
    my %args  = @_;

    # Firstly pop the policy atrributes
    my $attrs = {
        policy_name => delete $args{policy_name},
        policy_desc => delete $args{policy_desc},
    };
    $self->SUPER::update(%$attrs);

    # Build the policy pattern from
    my $pattern = $class->buildPattern(policy_type => $self->policy_type, hash => \%args);
    $self->param_preset->update(params => $pattern, override => 1);
}

sub getPolicyDef {
    my $self  = shift;
    my $class = ref($self) || $self;
    my %args  = @_;

    my $attributes = {
        displayed => [ 'policy_name', 'policy_desc' ]
    };

    my $json = $class->toJSON(model => 1);

    # Remove the param_preset_id form the json, as
    # the contents of params preset are added to the json.
    delete $json->{attributes}->{param_preset_id};

    return $merge->merge($attributes, $json);
}

sub mergeValues {
    my $self  = shift;
    my $class = ref($self) || $self;
    my %args  = @_;

    General::checkParams(args => \%args, required => [ 'values' ]);

    # Use existing values if defined, but override them with
    # with values from parameters (LEFT_PRECEDENT).
    if (ref($self)) {
        my $existing = $self->getPolicyPattern();
        # Here we need to manually override the existing list values with
        # list value from paramters as the merge extends the list contents.
        for my $attrname (keys %{ $args{values} }) {
            if (ref($args{values}->{$attrname}) eq 'ARRAY') {
                $existing->{$attrname} = [];
            }
            elsif ("$args{values}->{$attrname}" eq "") {
                delete $args{values}->{$attrname};
            }
        }
        $args{values} = $merge->merge($args{values}, $existing);
    }
    return $args{values};
}

sub setValues {
    my $self  = shift;
    my $class = ref($self) || $self;
    my %args  = @_;

    General::checkParams(args     => \%args,
                         required => [ 'attributes', 'values' ],
                         optional => { 'set_mandatory'       => 0,
                                       'set_editable'        => 1,
                                       'set_params_editable' => 0 });

    # If set_params_editable defined, we must to set non editable all
    # attributes that come from the policy instance, all others all some parameters
    # added to the policy definition.
    my $noneditable = {};
    if (ref($self) and $args{set_params_editable}) {
        $noneditable = $self->getNonEditableAttributes(%{ $args{values} });
    }

    # Set the values
    for my $attrname (keys %{ $args{attributes}->{attributes} }) {
        if (defined $args{values}->{$attrname} and "$args{values}->{$attrname}" ne "") {
            $args{attributes}->{attributes}->{$attrname}->{value} = $args{values}->{$attrname};

            # Set attributes editable in function of parameters
            if (($args{set_params_editable} and not defined $noneditable->{$attrname}) or
                $args{set_editable}) {
                $args{attributes}->{attributes}->{$attrname}->{is_editable} = 1;
            }
        }
        else {
            $args{attributes}->{attributes}->{$attrname}->{is_editable} = 1;
        }
        if ($args{set_mandatory}) {
            $args{attributes}->{attributes}->{$attrname}->{is_mandatory} = 1;
        }
    }
}

sub getNonEditableAttributes {
    my ($self, %args) = @_;

    return $self->getPolicyPattern();
}

sub buildPattern {
    my $self  = shift;
    my $class = ref($self) || $self;
    my %args  = @_;

    General::checkParams(args => \%args, required => [ 'policy_type', 'hash' ]);

    my %pattern;

    # Build the complette list of cluster attributes.
    my $cluster_attrs = Entity::ServiceProvider::Inside::Cluster->getAttrDefs();

    # Transform the policy form hash to a cluster configuration pattern
    for my $name (keys %{$args{hash}}) {
        # Handle defined values only
        if (defined $args{hash}->{$name} and $args{hash}->{$name} ne '') {
            # Handle managers
            if ($name =~ m/_manager_id/) {
                my $manager_type = $name;
                $manager_type =~ s/_id$//g;

                # Set the manager infos
                $pattern{managers}->{$manager_type}->{manager_id} = $args{hash}->{$name};
                $pattern{managers}->{$manager_type}->{manager_type} = $manager_type;

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
            elsif ($name eq 'components' and ref($args{hash}->{$name}) eq 'ARRAY' and $args{policy_type} eq 'system') {
                my %components = map { $_->{component_type} => $_ } @{ $args{hash}->{$name} };
                $pattern{components} = \%components;
            }
            # Handle networks interfaces
            elsif ($name eq 'interfaces' and ref($args{hash}->{$name}) eq 'ARRAY' and $args{policy_type} eq 'network') {
                my $index = 0;
                my $interfaces = {};
                for my $interface (@{ $args{hash}->{$name} }) {
                    if (ref($interface->{netconfs}) ne 'ARRAY') {
                        $interface->{netconfs} = [ $interface->{netconfs} ];
                    }
                    # Transform the netconfs list into a hash for merging purpose
                    my %netconfs = map { $_ => $_ } @{ $interface->{netconfs} };
                    $interface->{netconfs} = \%netconfs;

                    my $identifier = join('_', keys %{ $interface->{netconfs} }) . '_' . $interface->{bonds_number};
                    if (defined $interfaces->{'interface_' . $identifier}) {
                        $identifier .= '_' .  $index;
                    }
                    $interfaces->{'interface_' . $identifier} = $interface;
                    $index++;
                }
                $pattern{interfaces} = $interfaces;
            }
            # Handle billing limit
            elsif ($name eq 'billing_limits' and ref($args{hash}->{$name}) eq 'ARRAY' and $args{policy_type} eq 'billing') {
                my %limits = map { join('_',  values $_) => $_ } @{ $args{hash}->{$name} };
                $pattern{billing_limits} = \%limits;
            }
            # Can we handle these params whithout hard code  ?
            elsif ($name =~ /systemimage_size/) {
                $pattern{managers}->{disk_manager}->{manager_params}->{$name} = $args{hash}->{$name};
            }
            # Handle orchestration data (already well formatted metrics and rules)
            elsif ($name eq 'orchestration_service_provider_id') {
                $pattern{orchestration}{service_provider_id} = $args{hash}->{$name};
            }
            # Handle cluster attributtes.
            elsif (exists $cluster_attrs->{$name}) {
                # TODO: checkAttr
                $pattern{$name} = $args{hash}->{$name};
            }
        }
    }

    #$log->debug("Returning configuration pattern for a $args{policy_type} policy:\n" . Dumper(\%pattern));
    return \%pattern;
}

sub getPolicyPattern {
    my $self = shift;
    my %args = @_;

    my $flat_hash = {};
    my $pattern = $self->param_preset->load();

    # Transform the policy configuration pattern to a flat hash
    for my $name (keys %$pattern) {
        # Handle managers
        if ($name eq 'managers') {
            for my $manager_type (keys %{$pattern->{$name}}) {
                # Set the manager id
                $flat_hash->{$manager_type . '_id'} = $pattern->{$name}->{$manager_type}->{manager_id};

                # Set the manager parameters
                for my $manager_param (keys %{$pattern->{$name}->{$manager_type}->{manager_params}}) {
                    $flat_hash->{$manager_param} = $pattern->{$name}->{$manager_type}->{manager_params}->{$manager_param};
                }
            }
        }
        # Handle components
        elsif ($name eq 'components') {
            for my $component (values %{ $pattern->{$name} }) {
                if (not defined $flat_hash->{'components'}) {
                    $flat_hash->{'components'} = [];
                }
                push @{ $flat_hash->{'components'} }, { component_type => $component->{component_type} };
            }
        }
        # Handle network interfaces
        elsif ($name eq 'interfaces') {
            for my $interface (values %{ $pattern->{$name} }) {
                if (not defined $flat_hash->{'interfaces'}) {
                    $flat_hash->{'interfaces'} = [];
                }

                if (defined $interface->{netconfs} and ref($interface->{netconfs}) eq 'HASH') {
                    my @netconfs = values %{ $interface->{netconfs} };
                    $interface->{netconfs} = \@netconfs;
                }
                push @{ $flat_hash->{'interfaces'} }, $interface;
            }
        }
        elsif ($name eq 'billing_limits') {
            for my $billing (values %{ $pattern->{$name} }) {
                if (not defined $flat_hash->{'billing_limits'}) {
                    $flat_hash->{'billing_limits'} = [];
                }
                push @{ $flat_hash->{'billing_limits'} }, $billing;
            }
        }
        else {
            $flat_hash->{$name} = $pattern->{$name};
        }
    }

    #$log->debug("Returning flattened policy hash:\n" . Dumper($flat_hash));
    return $flat_hash;
}

sub searchManagers {
    my $self  = shift;
    my $class = ref($self) || $self;
    my %args  = @_;

    General::checkParams(args => \%args,
                         required => [ 'component_category' ],
                         optional => { 'service_provider_id' => undef });

    # Build the list of host providers
    my $types = {
        component => 'Entity::Component',
        connector => 'Entity::Connector',
    };

    my @managers;
    for my $name (keys $types) {
        my $filters = { $name . '_type.' . $name . '_category' => $args{component_category} };
        if (defined $args{service_provider_id}) {
            $filters->{service_provider_id} = $args{service_provider_id};
        }
        @managers = (@managers, $types->{$name}->search(hash => $filters));
    }
    return @managers;
}

sub getMasterGroupName {
    my $self = shift;

    return 'Policy';
}

1;
