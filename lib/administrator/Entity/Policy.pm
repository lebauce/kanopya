# Copyright © 2011-2013 Hedera Technology SAS
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

Base class to manage cluster configuration policies.
Currently 7 type of policy are identifyed: hosting, storage, network,
scalability, system, orchestration and billing. The type is used for
sorting policies only, or for user interface purposes.

A policy is composed by a name, a type, and a hash representing a sub hash
of the cluster configuration pattern. When creating or reconfigurating a
cluster, all policies pattern are merged to reconstituate the cluster
configuration pattern.

Note that this pattern is stored as JSON in the param preset table, and
represent the dynamic attributes of the policy.

Selector attributes are specific attributes that are capable to trigger
the reload of the attribute definition on the fly. Those parameters have
the reload property set. The selector relation map indicate which selector
attributes could be reloaded by another selector attrbiute.

@since    2012-Aug-16
@instance hash
@self     $self

=end classdoc

=cut

package Entity::Policy;
use base 'Entity';

use strict;
use warnings;

use ParamPreset;

use Clone qw(clone);
use Hash::Merge;

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

use constant POLICY_ATTR_DEF          => {};
use constant POLICY_SELECTOR_ATTR_DEF => {};
use constant POLICY_SELECTOR_MAP      => {};

sub getPolicyAttrDef { return POLICY_ATTR_DEF; }
sub getPolicySelectorAttrDef { return POLICY_SELECTOR_ATTR_DEF; }
sub getPolicySelectorMap { return POLICY_SELECTOR_MAP; }

my $merge = Hash::Merge->new('LEFT_PRECEDENT');


=pod
=begin classdoc

@constructor

Create a concrete policy by tranforming keys/values parameters
into a pattern that can be stored in the param preset table.

@return a class instance

=end classdoc
=cut

sub new {
    my $class = shift;
    my %args = @_;

    # Firstly pop the policy atrributes
    my $attrs = {
        policy_name => delete $args{policy_name},
        policy_type => delete $args{policy_type},
        policy_desc => delete $args{policy_desc},
    };

    # Create a policy with an empty pattern
    my $self = $class->SUPER::new(%$attrs);

    # Build the policy pattern from args
    $self->setPatternFromParams(params => \%args);

    return $self;
}


=pod
=begin classdoc

As the same as the constructor, update the policy real attrs,
and override the params preset by storing a new pattern builded
from keys/values parameters.

=end classdoc
=cut

sub update {
    my $self  = shift;
    my %args  = @_;

    # Firstly pop the policy atrributes
    my $attrs = {
        policy_name => delete $args{policy_name},
        policy_desc => delete $args{policy_desc},
    };
    $self->SUPER::update(%$attrs);

    # Firstly empty the old pattern
    $self->removePresets();

    # Build the policy pattern from args
    $self->setPatternFromParams(params => \%args);
}


=pod
=begin classdoc

Manualy remove the related param presets as delete on cascade
could not be used here.

=end classdoc
=cut

sub delete {
    my $self  = shift;
    my %args  = @_;

    $self->removePresets();
    $self->SUPER::delete();
}


=pod
=begin classdoc

Remove the related param preset from db.

=end classdoc
=cut

sub removePresets {
    my $self  = shift;
    my %args  = @_;

    # Firstly empty the old pattern
    my $presets = $self->param_preset;
    if ($presets) {
        # Detach presets from the policy
        $self->setAttr(name => 'param_preset_id', value => undef, save => 1);

        # Remove the preset
        $presets->remove();
    }
}


=pod
=begin classdoc

Like toJSON (with option 'model'), build the dynamic attribute definition
of the policy. The attribute definition depends of possibly defined values of some
attributes, for example, the complete list of attributes of an hosting policy depends
of the value of the attribute 'host_manager'.

This method implemented in the base class of policies only build the real (static)
attribute list, dynamic ones are handled in concrete classes.

@return the static attributes definiton.

=end classdoc
=cut

sub getPolicyDef {
    my $self  = shift;
    my $class = ref($self) || $self;
    my %args  = @_;

    General::checkParams(args     => \%args,
                         optional => { 'params'  => {},
                                       'trigger' => undef });

    # Firstly Merge policy attr def with selector only attr def
    my $policy_attrdef = $merge->merge(clone($class->getPolicyAttrDef),
                                       clone($class->getPolicySelectorAttrDef));

    my $attributes = {
        displayed  => [ 'policy_name', 'policy_desc' ],
        attributes => $policy_attrdef,
    };

    my $json = clone($class->toJSON(model => 1));

    # Remove the param_preset_id form the json, as
    # the contents of params preset are added to the json.
    delete $json->{attributes}->{param_preset_id};

    return $merge->merge($attributes, $json);
}


=pod
=begin classdoc

Update the params in function of the trigger effects.
An attribute trriger could affect the merge of the params
with the existings values, and unset some params.

@return the processed param hash

=end classdoc
=cut

sub processParams {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ 'params' ],
                         optional => { 'trigger' => undef });

    # If the trigger attribute is set to undef, remove it further
    # from the params merged with exiting values
    my $trigger_unset = (defined $args{trigger} && not defined $args{params}->{$args{trigger}});

    # Merge params with existing values.
    $args{params} = $self->mergeValues(values => $args{params});

    # Unset manager if the provider is the trigger
    if (defined $args{trigger}){
        $self->unsetSelectors(selector => $args{trigger}, params => $args{params});
        if ($trigger_unset){
            delete $args{params}->{$args{trigger}};
        }
    }
    return $args{params};
}


=pod
=begin classdoc

Flat params given in parameters are merged with the exsting ones
in the param presets of the policy, and converted into a pattern.

As a policy is often stored with non fixed values, for further completion,
this method is usefull to get the complette pattern of a policy by giving
additional params given by the user at cluster creation time.

@optional params the flat keys/values parameters describing the policy.

@return the policy pattern respecting the cluster configuration pattern format.

=end classdoc
=cut

sub getPattern {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, optional => { 'params' => {} });

    # Merge the policy params with those given in parameters
    # Set the option 'noarrays' for getting policy params because
    # the merge module is not able to merge arrays, so the resulting
    # merged params will have duplicated values in arrays.
    my $params  = $merge->merge($args{params}, $self->getParams(noarrays => 1));
    my $pattern = $self->getPatternFromParams(params => $params);

    # Manually remove deleted params from the original params hashes,
    # because the merge of the params with the policy contents has
    # overriden the reference of the original params hash.
    for my $param (keys %{ $args{params} }) {
        if (not defined $params->{$param}) {
            delete $args{params}->{$param};
        }
    }
    return $pattern
}


=pod
=begin classdoc

Transform the keys/values parameters to a pattern respecting the cluster
configuration pattern format. 

This method implemented in the base class of policies only handle
common parameters types that can be defined by all policies. Policy type
specific parameters are handled in the concrete implementation.

@optional params the flat keys/values parameters describing the policy.

@return the policy pattern respecting the cluster configuration pattern format.

=end classdoc
=cut

sub getPatternFromParams {
    my $self  = shift;
    my $class = ref($self);
    my %args  = @_;

    General::checkParams(args => \%args, optional => { 'params' => {} });

    my $pattern = {};
    my $attrdef = $class->getPolicyAttrDef;
    my %paramscopy = %{$args{params}};

    # Transform the policy form params to a cluster configuration pattern
    for my $name (keys %{$args{params}}) {
        # Handle defined values that belongs to the attrdef of the policy only
        if (defined $args{params}->{$name} and $args{params}->{$name} ne '' and exists $attrdef->{$name} and
            not ($attrdef->{$name}->{type} eq 'relation' and $attrdef->{$name}->{relation} eq 'single_multi')) {

            # Handle managers
            if ($name =~ m/_manager_id/) {
                my $manager_key = $name;
                $manager_key =~ s/_id$//g;

                my $manager_type = join('', map { ucfirst($_) } split('_', $manager_key));

                # Set the manager infos
                $pattern->{managers}->{$manager_key}->{manager_id}   = delete $args{params}->{$name};
                $pattern->{managers}->{$manager_key}->{manager_type} = $manager_type;

                # Set the manager params if required.
                # Build the method name that return the managers params in funtion of the type
                # of the manager, and call it on the manager instance.
                my $manager = Entity->get(id => $pattern->{managers}->{$manager_key}->{manager_id});
                my $method = 'get' . $manager_type . 'Params';

                my @params = keys % { $manager->$method(params => \%paramscopy) };
                for my $param (@params) {
                    if (defined $args{params}->{$param} and $args{params}->{$param}) {
                        $pattern->{managers}->{$manager_key}->{manager_params}->{$param} = delete $args{params}->{$param};
                    }
                }
            }
            # Handle cluster attributtes.
            else {
                # TODO: checkAttr
                $pattern->{$name} = delete $args{params}->{$name};
            }
        }
    }
    return $pattern;
}


=pod
=begin classdoc

Store params as a pattern in the policy param presets.

@param params the flat keys/values parameters describing the policy.

=end classdoc
=cut

sub setPatternFromParams {
    my $self  = shift;
    my %args  = @_;

    General::checkParams(args => \%args, required => [ 'params' ]);

    my $preset = ParamPreset->new(params => $self->getPattern(params => $args{params}));
    $self->setAttr(name => 'param_preset_id', value => $preset->id, save => 1);
}


=pod
=begin classdoc

Merge the values given in parameter with the instance ones.

@param values the policy attribute values

@return the values defining the policy.

=end classdoc
=cut

sub mergeValues {
    my $self  = shift;
    my $class = ref($self) || $self;
    my %args  = @_;

    General::checkParams(args => \%args, required => [ 'values' ]);

    # Use existing values if defined, but override them with
    # with values from parameters (LEFT_PRECEDENT).
    if (ref($self)) {
        my $existing = $self->getParams();

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


=pod
=begin classdoc

Add the defined values into the policy attribute definition hash map.
It could be usefull to get the attrdef hash with values to avoid
re-requesting the api to get values after getting the attributes.

@param attributes the attribute defintion hash to fill with values
@param values to add to the attrdef

@optional set_mandatory force to set attrbiutes as mandatory
@optional set_editable force to set attributes as editable
@optional set_params_editable force to set attributes as editable
          only if they are not stored in param preset, set attributes
          as non editable instead.

=end classdoc
=cut

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
    # attributes that comme from the policy instance only, all others are
    # some parameters added to the original policy definition.
    my $noneditable = {};
    if (ref($self) and $args{set_params_editable}) {
        $noneditable = $self->getNonEditableAttributes(%{ $args{values} });
    }

    # Set the values
    for my $attrname (keys %{ $args{attributes}->{attributes} }) {
        if (defined ($args{values}->{$attrname}) && "$args{values}->{$attrname}" ne "") {
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

        # If the attribute do not belongs to the base type Policy, use set_mandatory option
        if (not defined Entity::Policy->getAttrDef->{$attrname}) {
            my $mandatory = ($args{set_mandatory} and $args{attributes}->{attributes}->{$attrname}->{is_mandatory});
            $args{attributes}->{attributes}->{$attrname}->{is_mandatory} = $mandatory ? 1 : 0;
        }
    }
}


=pod
=begin classdoc

Set to undef the values of paramters taht depends on an other one,
called a selector, in funtion of the selector relation map
(see POLICY_SELECTOR_MAP constant).

=end classdoc
=cut

sub unsetSelectors {
    my $self  = shift;
    my $class = ref($self) || $self;
    my %args  = @_;

    General::checkParams(args => \%args, required => [ 'selector', 'params' ]);

    my $map = $self->getPolicySelectorMap();
    if (ref($map->{$args{selector}}) eq "ARRAY") {
        for my $relation (@{ $map->{$args{selector}} }) {
            delete $args{params}->{$relation};
        }
    }
}


=pod
=begin classdoc

Get the non editable attributes list for the 'set_params_editable' mode
of the method setValues.

This method implemented in the base class of policies simply return
the stored param preset in the param format (not pattern).

@return the non editable params list

=end classdoc
=cut

sub getNonEditableAttributes {
    my ($self, %args) = @_;

    return $self->getParams();
}


=pod
=begin classdoc

Get the param preset (dynamic attributes) of the policy in a flat
format keys/values. It is usefull for example to display and edit
the policy pattern.

@return the parameters hash.

@todo dispath policy type pecific params hnadling a concrete classes.

=end classdoc
=cut

sub getParams {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, optional => { 'noarrays' => 0, 'exclude' => [] });

    my $flat_hash = {};
    my $presets = $self->param_preset;
    my $pattern = $presets ? $presets->load() : {};

    # Transform the policy configuration pattern to a flat hash
    ATTRIBUTE:
    for my $name (keys %$pattern) {
        # Handle managers
        if ($name eq 'managers') {
            for my $manager (keys %{$pattern->{$name}}) {
                my $manager_type = $pattern->{$name}->{$manager}->{manager_type};
                $manager_type =~ s/Manager$//g;
                $manager_type = lcfirst($manager_type) . '_manager';

                # Set the manager id
                $flat_hash->{$manager_type . '_id'} = $pattern->{$name}->{$manager}->{manager_id};

                # Set the manager parameters
                for my $manager_param (keys %{$pattern->{$name}->{$manager}->{manager_params}}) {
                    $flat_hash->{$manager_param} = $pattern->{$name}->{$manager}->{manager_params}->{$manager_param};
                }
            }
        }
        # Handle components
        elsif ($name eq 'components') {
            if ($args{noarrays}) { next ATTRIBUTE; }

            for my $component (values %{ $pattern->{$name} }) {
                if (not defined $flat_hash->{'components'}) {
                    $flat_hash->{'components'} = [];
                }
                push @{ $flat_hash->{'components'} }, { component_type => $component->{component_type} };
            }
        }
        # Handle network interfaces
        elsif ($name eq 'interfaces') {
            if ($args{noarrays}) { next ATTRIBUTE; }

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
        # Handle billing limits
        elsif ($name eq 'billing_limits') {
            if ($args{noarrays}) { next ATTRIBUTE; }

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


=pod
=begin classdoc

Utility method to search among existing managers in function of
manager category.

@return a manager list.

=end classdoc
=cut

sub searchManagers {
    my $self  = shift;
    my %args  = @_;

    General::checkParams(args => \%args,
                         required => [ 'component_category' ],
                         optional => { 'service_provider_id' => undef });

    my $searchargs = {
        custom => { category => $args{component_category} }
    };
    if (defined $args{service_provider_id}) {
        $searchargs->{hash}->{service_provider_id} = $args{service_provider_id};
    }

    return Entity::Component->search(%$searchargs);
}


=pod
=begin classdoc

Check if the given attr trigger the reload ofattr def
by setting it to an undef value.

=end classdoc
=cut

sub isAttributeUnset {
    my $self = shift;
    my %args  = @_;

    General::checkParams(args => \%args, required => [ 'name', 'params', 'trigger' ]);

    return $args{trigger} eq $args{name} and not defined $args{params}->{$args{name}};
}


=pod
=begin classdoc

Set the first options selected in params if the attribute is mandatory.

=end classdoc
=cut

sub setFirstSelected {
    my $self = shift;
    my %args  = @_;

    General::checkParams(args => \%args, required => [ 'name', 'attributes', 'params' ]);

    if (defined $args{attributes}->{$args{name}}->{options}) {
        my @options;
        if (ref($args{attributes}->{$args{name}}->{options}) eq "ARRAY") {
            @options = @{ $args{attributes}->{$args{name}}->{options} };
        }
        elsif (ref($args{attributes}->{$args{name}}->{options}) eq "HASH") {
            @options = keys %{ $args{attributes}->{$args{name}}->{options} };
        }

        # Set the first option as seleted if the attr is mandatory
        if ($args{attributes}->{$args{name}}->{is_mandatory} and scalar (@options) > 0) {
            # If the options are json objects, use the pk as value
            if (ref($options[0]) eq "HASH" && defined ($options[0]->{pk})) {
                $args{params}->{$args{name}} = $options[0]->{pk};
            }
            else {
                $args{params}->{$args{name}} = $options[0];
            }
        }
    }
}


=pod
=begin classdoc

@return the master group name associated with this entity

=end classdoc
=cut

sub getMasterGroupName {
    my $self = shift;

    return 'Policy';
}

1;
