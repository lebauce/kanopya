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

use TryCatch;
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
    # TODO: Do not store the policy type in db.
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

use constant POLICY_ATTR_DEF          => {};
use constant POLICY_SELECTOR_ATTR_DEF => {};
use constant POLICY_SELECTOR_MAP      => {};

sub getPolicyAttrDef { return POLICY_ATTR_DEF; }
sub getPolicySelectorAttrDef { return POLICY_SELECTOR_ATTR_DEF; }
sub getPolicySelectorMap { return POLICY_SELECTOR_MAP; }

my $merge = Hash::Merge->new();
$merge->specify_behavior({
    'SCALAR' => {
            'SCALAR' => sub { $_[1] },
            'ARRAY'  => sub { [ $_[0], @{$_[1]} ] },
            'HASH'   => sub { $_[1] },
    },
    'ARRAY' => {
            'SCALAR' => sub { $_[1] },
            'ARRAY'  => sub { [ @{$_[1]} ] },
            'HASH'   => sub { $_[1] },
    },
    'HASH' => {
            'SCALAR' => sub { $_[1] },
            'ARRAY'  => sub { [ values %{$_[0]}, @{$_[1]} ] },
            'HASH'   => sub { Hash::Merge::_merge_hashes( $_[0], $_[1] ) },
    },
});


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

Override the parent mathod to find the policy
from policy_name and policy_type only.

=cut

sub findOrCreate {
    my ($class, %args) = @_;

    my $criteria = {};
    if (exists $args{policy_name}) {
        $criteria->{policy_name} = $args{policy_name};
    }
    if (exists $args{policy_type}) {
        $criteria->{policy_type} = $args{policy_type};
    }
    try {
        return $class->find(hash => $criteria);
    }
    catch ($err) {
        return $class->create(%args);
    }
}


=pod
=begin classdoc

Remove the related param preset from db.

=end classdoc
=cut

sub removePresets {
    my $self = shift;
    my %args = @_;

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

If called on an instance, return the JSON from database, and add the attributes
from the dynamic defintion that have values.

The dynamic attribute definition depends of possibly defined values of some
attributes, for example, the complete list of attributes of an hosting policy depends
of the value of the attribute 'host_manager'.

This method implemented in the base class of policies build the static attributes definition,
and then call getPolicyDef on the conrete policy to merge the dynamic attributes definition.

@return the attributes definiton.

=end classdoc
=cut

sub toJSON {
    my $self  = shift;
    my $class = ref($self) || $self;
    my %args  = @_;

    General::checkParams(args     => \%args,
                         optional => { 'params'        => {},
                                       'trigger'       => undef,
                                       'set_mandatory' => 0 });

    # If called on the class, return the attribute definition
    if (not ref($self)) {
        # Build the static attribute definition
        my $attributes = {
            displayed  => [ 'policy_name', 'policy_desc' ],
            attributes => $merge->merge(clone($class->getPolicySelectorAttrDef),
                                        clone($class->getPolicyAttrDef)),
        };
        $attributes = $merge->merge(clone($class->SUPER::toJSON()), $attributes);

        # Merge params with existing values
        # If the policy if is defined in params, instanciate it to merge params
        # with fixed values and force its as non editable.
        my $policy;
        if (defined $args{params}->{$class->policy_type . '_policy_id'}) {
            $policy = $class->get(id => $args{params}->{$class->policy_type . '_policy_id'});
            $args{params} = $policy->processParams(%args);
        }
        else {
            $args{params} = $class->processParams(%args);
        }

        # Merge with the dynamic attribute definition built from params
        my $policydef = $class->getPolicyDef(attributes => $attributes, %args);
        # Set the values of attributes from params and fixed values
        $class->setValues(attributes    => $policydef,
                          values        => $args{params},
                          set_mandatory => delete $args{set_mandatory},
                          non_editable  => defined $policy ? $policy->getNonEditableAttributes() : {});

        # Remove the param_preset_id form the json, as
        # the contents of params preset are added to the json.
        delete $policydef->{attributes}->{param_preset_id};

        return $policydef;
    }
    # If called on an instance, return the attributes values
    else {
        return $merge->merge($self->getParams(), $self->SUPER::toJSON());
    }
}


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

    return $args{attributes};
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
    my $params = $merge->merge($self->getParams(noarrays => 1), $args{params});
    my $pattern = $self->getPatternFromParams(params => $params);

    # Manually remove deleted params from the original params hashes,
    # because the merge of the params with the policy contents has
    # overriden the reference of the original params hash.
    for my $param (keys %{ $args{params} }) {
        if (not defined $params->{$param}) {
            delete $args{params}->{$param};
        }
    }

    # Finally merge the pattern built from input params with the static pattern from presets
    return $merge->merge($self->param_preset_id ? $self->param_preset->load() : {}, $pattern);
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
    my $class = ref($self) or throw Kanopya::Exception::Method();
    my %args  = @_;

    General::checkParams(args => \%args, optional => { 'params' => {} });

    my $pattern = {};
    my $attrdef = $class->getPolicyAttrDef;
    my %paramscopy = %{ $args{params} };

    # Transform the policy form params to a cluster configuration pattern
    for my $name (keys %{ $args{params} }) {
        # Handle defined values that belongs to the attrdef of the policy only
        if (defined $args{params}->{$name} && $args{params}->{$name} ne '' && exists $attrdef->{$name} &&
            ! ($attrdef->{$name}->{type} eq 'relation' && $attrdef->{$name}->{relation} eq 'single_multi')) {
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
            if (defined ref($args{values}->{$attrname}) && ref($args{values}->{$attrname}) eq 'ARRAY') {
                $existing->{$attrname} = [];
            }
            elsif (defined $args{values}->{$attrname} && "$args{values}->{$attrname}" eq "") {
                delete $args{values}->{$attrname};
            }
        }
        $args{values} = $merge->merge($existing, $args{values});
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

=end classdoc
=cut

sub setValues {
    my $self  = shift;
    my $class = ref($self) || $self;
    my %args  = @_;

    General::checkParams(args     => \%args,
                         required => [ 'attributes', 'values' ],
                         optional => { 'set_mandatory' => 0,
                                       'non_editable'  => {} });

    # Set the values
    for my $attrname (keys %{ $args{attributes}->{attributes} }) {
        if (defined ($args{values}->{$attrname}) && "$args{values}->{$attrname}" ne "") {
            $args{attributes}->{attributes}->{$attrname}->{value} = $args{values}->{$attrname};
        }
        # Set attributes editable in function of parameters
        if (! defined $args{non_editable}->{$attrname}) {
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

Set to undef the values of paramters that depends on an other one,
called a selector, in funtion of the selector relation map
(see POLICY_SELECTOR_MAP constant).

=end classdoc
=cut

sub unsetSelectors {
    my $self  = shift;
    my $class = ref($self) || $self;
    my %args  = @_;

    General::checkParams(args => \%args, required => [ 'selector', 'params' ]);

    my $map = $class->getPolicySelectorMap();
    if (ref($map->{$args{selector}}) eq "ARRAY") {
        for my $relation (@{ $map->{$args{selector}} }) {
            delete $args{params}->{$relation};
        }
    }
}


=pod
=begin classdoc

Get the non editable attributes list (fixed values in param presets).

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
                if (defined $manager_type) {
                    $manager_type =~ s/Manager$//g;
                    $manager_type = lcfirst($manager_type) . '_manager';

                    # Set the manager id
                    $flat_hash->{$manager_type . '_id'} = $pattern->{$name}->{$manager}->{manager_id};
                }

                # Set the manager parameters
                for my $manager_param (keys %{ $pattern->{$name}->{$manager}->{manager_params} }) {
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

@return the policy type

=end classdoc
=cut

sub policy_type {
    my $self = shift;

    if (ref($self)) {
        return $self->getAttr(name => 'policy_type');
    }
    else {
        (my $type = $self) =~ s/^Entity::Policy:://g;
        $type =~ s/Policy$//g;
        return lc($type);
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
