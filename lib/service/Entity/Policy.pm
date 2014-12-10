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
use POSIX qw[strftime];
use Hash::Merge;
use TryCatch;
use Data::Dumper;
use Log::Log4perl 'get_logger';

my $log = get_logger("");

use constant ATTR_DEF => {
    policy_name => {
        label        => 'Policy name',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1,
	description  => 'It is the name of the policy',
    },
    policy_desc => {
        label        => 'Description',
        type         => 'text',
        pattern      => '^.*$',
        is_mandatory => 0,
        is_editable  => 1,
	description  => 'It is the description of the policy',
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
        $policydef = $merge->merge(clone($class->SUPER::toJSON()), $policydef);
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

    # Push all attributes to the displayed fiels according the extra tag "order"
    my $attrdef = $args{attributes}->{attributes};

    my @sorted = sort { ($attrdef->{$a}->{order} || 0) <=> ($attrdef->{$b}->{order} || 0) }
                     keys (%{ $attrdef });
    for my $attrname (@sorted) {
        $class->handlePolicyDefAttribute(attrname => $attrname, %args);
    }
    return $args{attributes};
}


=pod
=begin classdoc

Recursivly handle policy attributes, so handle as the same way
static policy attrs and dynamic attrs that depends of the managers.

=end classdoc
=cut

sub handlePolicyDefAttribute {
    my $self  = shift;
    my $class = ref($self) || $self;
    my %args  = @_;

    General::checkParams(args     => \%args,
                         required => [ 'attrname', 'attributes', 'params' ]);

    # Handle list of complex elements
    my $attrdef = $args{attributes}->{attributes};
    if ($attrdef->{$args{attrname}}->{type} eq 'relation' &&
        $attrdef->{$args{attrname}}->{relation} eq 'single_multi') {

        # Get the attribute definition of the related element
        my $relation_attrdef = $attrdef->{$args{attrname}}->{attributes}->{attributes};

        # Add the relation attributes to the displayed ones
        my @displayed = grep { $_ ne "policy_id" } keys %{ $relation_attrdef };
        push @{ $args{attributes}->{displayed} }, { $args{attrname} => \@displayed };

        # Add the relation to the relations definition
        $args{attributes}->{relations}->{$args{attrname}} = {
            attrs    => { accessor => 'multi' },
            cond     => { 'foreign.policy_id' => 'self.policy_id' },
            resource => $args{attrname}
        };
    }
    else {
        # Add the attribute to displayed
        push @{ $args{attributes}->{displayed} }, $args{attrname};
    }

    # If the attribute correspond to a manager id, fill the options,
    # handle the dynamic attrs of the manager.
    if ($attrdef->{$args{attrname}}->{type} eq 'relation' &&
        $attrdef->{$args{attrname}}->{relation} eq 'single' &&
        $args{attrname} =~ m/_manager_id/) {

        # Deduce the manager type from the attr name...
        (my $manager_key = $args{attrname}) =~ s/_id$//g;
        my $manager_type = join('', map { ucfirst($_) } split('_', $manager_key));

        # Build the list of available managers of this type
        my $manager_options = {};
        for my $component (Entity::Component->search(custom => { category => $manager_type })) {
            $manager_options->{$component->id} = $component->toJSON;
            $manager_options->{$component->id}->{label} = $component->label;
        }
        my @manageroptions = values %{ $manager_options };
        $attrdef->{$args{attrname}}->{options} = \@manageroptions;
        $attrdef->{$args{attrname}}->{reload} = 1;

        # If the id of the manager defined but do not corresponding to a available value,
        # it is an old value, so delete it.
        if (not $manager_options->{$args{params}->{$args{attrname}}}) {
            delete $args{params}->{$args{attrname}};
        }
        # If no manager id defined and and attr is mandatory, use the first one as value
        if (! $args{params}->{$args{attrname}} && $args{set_mandatory}) {
            $self->setFirstSelected(name       => $args{attrname},
                                    attributes => $attrdef,
                                    params     => $args{params});
        }

        # If a value defined for the manager id, handle dynamic attributes of the managers
        if ($args{params}->{$args{attrname}}) {
            # Get the manager params from the selected manager
            my $manager = Entity::Component->get(id => $args{params}->{$args{attrname}});

            # Build the name of the method to call from the manager type to get the params
            # of the proper type.
            my $paramsmethod = "get" . $manager_type . "Params";
            my $managerparams = $manager->$paramsmethod(params => $args{params});

            # Add the dynamic attr of the manager to the policy attr def
            my @dynamic_attrs = sort { $managerparams->{$a}->{order} <=> $managerparams->{$b}->{order} }
                                    keys (%{ $managerparams });
            for my $dynamic_attrname (@dynamic_attrs) {
                $attrdef->{$dynamic_attrname} = $managerparams->{$dynamic_attrname};

                # If no value defined in params, use the first one
                if (! $args{params}->{$dynamic_attrname} && $args{set_mandatory}) {
                    $self->setFirstSelected(name       => $dynamic_attrname,
                                            attributes => $attrdef,
                                            params     => $args{params});
                }

                # Handle the dynamic attr as the static ones, if not done by a manager
                # TODO: With the folliwing grep, we do not detect relations single_multi
                #       handle at the beguining of the merthod
                if (! scalar(grep { $_ eq $dynamic_attrname } @{ $args{attributes}->{displayed} })) {
                    $class->handlePolicyDefAttribute(%args, attrname => $dynamic_attrname);
                }
            }
        }
        # Remove possibly defined value of attributes that depends on the manager id.
        else {
            for my $dependency (@{ $self->getPolicySelectorMap->{$args{attrname}} }) {
                delete $args{params}->{$dependency};
            }
        }
    }
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

    my $attrdef = $class->toJSON(params => $args{params})->{attributes};
    my %paramscopy = %{ $args{params} };

    # Firstly move all array values to hashes as a configuration pattern could be merged
    # without duplicating array values.
    my $params = $self->relationsListToHash(params => $args{params}, attrdef => $attrdef);

    # Transform the policy form params to a cluster configuration pattern
    my $pattern = {};
    for my $name (keys %{ $class->getPolicyAttrDef }) {
        # Handle defined values that belongs to the attrdef of the policy only
        if (defined $params->{$name} && $params->{$name} ne '') {
            # Handle managers
            if ($name =~ m/_manager_id/) {
                my $manager_key = $name;
                $manager_key =~ s/_id$//g;

                my $manager_type = join('', map { ucfirst($_) } split('_', $manager_key));

                # Set the manager infos
                $pattern->{managers}->{$manager_key}->{manager_id}   = delete $params->{$name};
                $pattern->{managers}->{$manager_key}->{manager_type} = $manager_type;

                # Set the manager params if required.
                # Build the method name that return the managers params in funtion of the type
                # of the manager, and call it on the manager instance.
                my $managerdef = $pattern->{managers}->{$manager_key};
                my $manager = Entity::Component->get(id => $managerdef->{manager_id});
                my $method = 'get' . $manager_type . 'Params';

                my @managerparams = keys % { $manager->$method(params => \%paramscopy) };
                for my $param (@managerparams) {
                    if (defined $params->{$param} and $params->{$param}) {
                        $managerdef->{manager_params}->{$param} = delete $params->{$param};
                    }
                }
            }
            # Handle cluster attributtes.
            else {
                # TODO: checkAttr
                $pattern->{$name} = delete $params->{$name};
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
    my $class = ref($self) || $self;

    General::checkParams(args => \%args, optional => { 'noarrays' => 0, 'exclude' => [] });

    my $presets = $self->param_preset;
    my $pattern = $presets ? $presets->load() : {};

    # Process the multi level hash pattern to build to key/value hash

    # Firstly move the manager params from the manager level to the root level
    if (defined $pattern->{managers}) {
        my $managers = delete $pattern->{managers};

        # Browse all the managers to get thier respective params
        for my $manager (keys %{ $managers }) {
                my $manager_type = $managers->{$manager}->{manager_type};
                if (defined $manager_type) {
                    $manager_type =~ s/Manager$//g;
                    $manager_type = lcfirst($manager_type) . '_manager';

                    # Set the manager id
                    $pattern->{$manager_type . '_id'} = $managers->{$manager}->{manager_id};
                }

                # Set the manager parameters
                for my $manager_param (keys %{ $managers->{$manager}->{manager_params} }) {
                    $pattern->{$manager_param}
                        = delete $managers->{$manager}->{manager_params}->{$manager_param};
                }
        }
    }

    # List params values are stored as hashes because they need to be merged
    # So keep the the values of the hash as value for the param.
    return $self->relationsHashToList(params  => $pattern,
                                      attrdef => $class->toJSON(params => $pattern)->{attributes});
}


=pod
=begin classdoc

Check if the given attr trigger the reload ofattr def
by setting it to an undef value.

=end classdoc
=cut

sub relationsHashToList {
    my $self = shift;
    my %args = @_;
    my $class = ref($self) || $self;

    General::checkParams(args => \%args, required => [ 'params', 'attrdef' ]);

    for my $name (grep { ref($args{params}->{$_}) eq "HASH" } keys %{ $args{params} }) {
        # If the param is a multi relation, make the value as a list
        if (defined $args{attrdef}->{$name} &&
            $args{attrdef}->{$name}->{type} eq 'relation' &&
            $args{attrdef}->{$name}->{relation} =~ m/^(single_multi|multi)$/) {

            my @values = values %{ delete $args{params}->{$name} };
            my $rel_attrdef = $args{attrdef}->{$name}->{attributes}->{attributes};
            if (defined $rel_attrdef) {
                @values = map { $self->relationsHashToList(params => $_, attrdef => $rel_attrdef) } @values;
            }
            $args{params}->{$name} = \@values;
        }
    }
    return $args{params};
}


=pod
=begin classdoc

Check if the given attr trigger the reload ofattr def
by setting it to an undef value.

=end classdoc
=cut

sub relationsListToHash {
    my $self = shift;
    my %args = @_;
    my $class = ref($self) || $self;

    General::checkParams(args => \%args, required => [ 'params', 'attrdef' ]);

    for my $name (grep { ref($args{params}->{$_}) eq "ARRAY" } keys %{ $args{params} }) {
        # If the param is a multi relation, make the value as a list
        if (defined $args{attrdef}->{$name} &&
            $args{attrdef}->{$name}->{type} eq 'relation' &&
            $args{attrdef}->{$name}->{relation} =~ m/^(single_multi|multi)$/) {

            # Firstly handle the list values
            my @values = @{ delete $args{params}->{$name} };
            my $rel_attrdef = $args{attrdef}->{$name}->{attributes}->{attributes};
            if (defined $rel_attrdef) {
                @values = map { $self->relationsListToHash(params => $_, attrdef => $rel_attrdef) } @values;
            }

            # And move the list to a hash
            my $index = 0;
            my %hash = map { $name . "_" . $index++ => $_ } @values;
            $args{params}->{$name} = \%hash;
        }
    }
    return $args{params};
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
