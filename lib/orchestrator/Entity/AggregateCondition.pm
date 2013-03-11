#    Copyright © 2012 Hedera Technology SAS
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

=pod

=begin classdoc

Condition on aggregate combination (left operand) and agreggate combination or threshold (right operand)

@see <package>Entity::Combination::AggregateCombination</package>
@see <package>Entity::Combination::ConstantCombination</package>

=end classdoc

=cut

package Entity::AggregateCondition;

use strict;
use warnings;
use TimeData::RRDTimeData;
use Entity::Combination::AggregateCombination;
require 'Entity/Rule/AggregateRule.pm';
use base 'Entity';
use Data::Dumper;
# logger
use Log::Log4perl "get_logger";
my $log = get_logger("");

use constant ATTR_DEF => {
    aggregate_condition_id => {
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_extended     => 0,
        is_editable     => 0,
    },
    aggregate_condition_label => {
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_extended     => 0,
        is_editable     => 1,
    },
    aggregate_condition_formula_string => {
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_extended     => 0,
        is_editable     => 1,
    },
    aggregate_condition_service_provider_id => {
        pattern         => '^.*$',
        is_mandatory    => 1,
        is_extended     => 0,
        is_editable     => 0,
    },
    left_combination_id => {
        pattern         => '^.*$',
        is_mandatory    => 1,
        is_extended     => 0,
        is_editable     => 1,
    },
    right_combination_id => {
        pattern         => '^.*$',
        is_mandatory    => 1,
        is_extended     => 0,
        is_editable     => 1,
    },
    comparator => {
        pattern         => '^(>|<|>=|<=|==)$',
        is_mandatory    => 1,
        is_extended     => 0,
        is_editable     => 1,
    },
    time_limit => {
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_extended     => 0,
        is_editable     => 1,
    },
    last_eval => {
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_extended     => 0,
        is_editable     => 1,
    },
};

sub getAttrDef { return ATTR_DEF; }

sub methods {
    return {
        'updateName'    => {
            'description'   => 'updateName',
            'perm_holder'   => 'entity'
        },
        'getDependencies' => {
            'description' => 'return dependencies tree for this object',
            'perm_holder' => 'entity',
        },
    };
}


=pod

=begin classdoc

@constructor

Create a new instance of the class.
Transforms thresholds into ConstantCombinations
Update formula_string with toString() methods and the label if not provided in attribute.

@return a class instance

=end classdoc

=cut

sub new {
    my $class = shift;
    my %args = @_;

    if ((! defined $args{right_combination_id}) && defined $args{threshold}  ) {
        my $comb = Entity::Combination::ConstantCombination->new (
            service_provider_id => $args{aggregate_condition_service_provider_id},
            value => $args{threshold}
        );
        delete $args{threshold};
        $args{right_combination_id} = $comb->id;
    }

    if ((! defined $args{left_combination_id}) && defined $args{threshold}  ) {
        my $comb = Entity::Combination::ConstantCombination->new (
            service_provider_id => $args{aggregate_condition_service_provider_id},
            value => $args{threshold}
        );
        delete $args{threshold};
        $args{left_combination_id} = $comb->id;
    }

    my $self = $class->SUPER::new(%args);
    my $toString = $self->toString();
    $self->setAttr (name=>'aggregate_condition_formula_string', value => $toString);
    if ((! defined $args{aggregate_condition_label}) || $args{aggregate_condition_label} eq '') {
        $self->setAttr (name=>'aggregate_condition_label', value => $toString);
    }
    $self->save ();
    return $self;
}

sub label {
    my $self = shift;
    return $self->aggregate_condition_label;
}


=pod

=begin classdoc

set label to human readable version of the formula

=end classdoc

=cut

sub updateName {
    my $self    = shift;

    $self->setAttr(name => 'aggregate_condition_label', value => $self->toString);
    $self->save;
}


=pod

=begin classdoc

Transform formula to human readable String

@return human readable String of the formula

=end classdoc

=cut

sub toString {
    my $self = shift;

    # Not used yet due to bad Combination::computeUnit() behavior (see also NodemetricCondition::toString())
    my $unit = '';
    if ((ref $self->right_combination) eq 'Entity::Combination::ConstantCombination') {
        my $left_unit = $self->left_combination->combination_unit;
        if ($left_unit && (($left_unit ne '?') || ($left_unit ne '-'))) {
            $unit = $left_unit;
        }
    }

    return  $self->left_combination->combination_formula_string.' '
           .$self->comparator.' '
           .$self->right_combination->combination_formula_string;
}


=pod

=begin classdoc

Evaluate the condition. Call evaluation of both dependant combinations then evaluate the condition

@return scalar 1 if condition is true
               0 if condition is false

=end classdoc

=cut

sub evaluate{
    my ($self, %args) = @_;

    my $comparator  = $self->getAttr(name => 'comparator');

    # Evaluate both conditions
    my $left_value  = $self->left_combination->evaluate(%args);
    my $right_value = $self->right_combination->evaluate(%args);

    if (defined $left_value && defined $right_value) {
        my $evalString = $left_value.$comparator.$right_value;

        $log->debug("AggregateCondition evaluated: $evalString");

        if (eval $evalString) {
            $log->debug($evalString."=> true");
            $self->setAttr(name => 'last_eval', value => 1);
            $self->save();
            return 1;
        }
        else {
            $log->debug($evalString."=> false");
            $self->setAttr(name => 'last_eval', value => 0);
            $self->save();
            return 0;
        }
    }

    # At lease one of both condition is undefinded
    $log->warn('No data received from DB for '.($self->left_combination)." or ".($self->right_combination));
    $self->setAttr(name => 'last_eval', value => undef);
    $self->save();
    return undef;
}


=pod

=begin classdoc

Find all the rules which depends on the AggregateCondition

@return array of rules

=end classdoc

=cut

sub getDependentRules {
    my $self = shift;
    my @rules_from_same_service = Entity::Rule::AggregateRule->search(
                                      hash => {
                                          service_provider_id => $self->aggregate_condition_service_provider_id
                                      }
                                  );

    my @rules;
    my $id = $self->id;
    RULE:
    for my $rule (@rules_from_same_service) {
        my @rule_dependant_condition_ids = $rule->getDependentConditionIds;
        for my $condition_id (@rule_dependant_condition_ids) {
            if ($id == $condition_id) {
                push @rules, $rule;
                next RULE;
            }
        }
    }
    return @rules;
}


=pod

=begin classdoc

Find all the rules which depends on the AggregateCondition

@return hashref of rule_names

=end classdoc

=cut

sub getDependencies {
    my $self = shift;

    my @rules = $self->getDependentRules;

    my %dependencies;
    for my $rule (@rules) {
        $dependencies{$rule->rule_name} = {};
    }
    return \%dependencies;
}


=pod

=begin classdoc

Delete instance and delete dependant object on cascade.

=end classdoc

=cut

sub delete {
    my $self = shift;
    my @rules_from_same_service = Entity::Rule::AggregateRule->search(hash => {service_provider_id => $self->aggregate_condition_service_provider_id});

    my $id = $self->getId;
    LOOP:
    while (@rules_from_same_service) {
        my $rule = pop @rules_from_same_service;
        my @rule_dependant_condition_ids = $rule->getDependentConditionIds;
        for my $condition_id (@rule_dependant_condition_ids) {
            if ($id == $condition_id) {
                $rule->delete();
                next LOOP;
            }
        }
    }
    my $comb_left  = $self->left_combination;
    my $comb_right = $self->right_combination;
    $self->SUPER::delete();
    $comb_left->deleteIfConstant();
    $comb_right->deleteIfConstant();
}


=pod

=begin classdoc

Update instance attributes. Manage update of related objects and formula_string.

=end classdoc

=cut

sub update {
    my ($self, %args) = @_;

    my $service_provider_id = $args{aggregate_condition_service_provider_id} ?
                                  $args{aggregate_condition_service_provider_id} :
                                  $self->aggregate_condition_service_provider_id ;

    my $two_attributes = 0;
    if (defined $args{threshold}) { $two_attributes++; }
    if (defined $args{left_combination_id}) { $two_attributes++; }
    if (defined $args{right_combination_id}) { $two_attributes++; }

    if ($two_attributes == 0) {
        my $rep = $self->SUPER::update (%args);
        $rep->updateFormulaString;
        return $rep;
    }

    if ( $two_attributes != 2) {
        my $error = 'When updating nodemetric condition, have to specify two attributes between '.
                    'nodemetric_condition_threshold, left_combination_id and right_combination';
        throw Kanopya::Exception::Internal::WrongValue(error => $error);
    }

    my $old_left_combination = $self->left_combination;
    my $old_right_combination = $self->right_combination;

    if (! defined $args{left_combination_id}) {
        my $new_left_combination =  Entity::Combination::ConstantCombination->new (
            service_provider_id => $service_provider_id,
            value => $args{threshold}
        );
        delete $args{threshold};
        $args{left_combination_id} = $new_left_combination->id;
    }
    elsif (! defined $args{right_combination_id}) {
        my $new_right_combination =  Entity::Combination::ConstantCombination->new (
            service_provider_id => $service_provider_id,
            value => $args{threshold}
        );
        delete $args{threshold};
        $args{right_combination_id} = $new_right_combination->id;
    }
    else {
        # do nothing, update will just replace both ids with right and left combination ids
    }

    my $rep = $self->SUPER::update (%args);
    $rep->updateFormulaString;
    $old_left_combination->deleteIfConstant();
    $old_right_combination->deleteIfConstant();
    return $rep;
}

=pod

=begin classdoc

Clones the condition and all related objects.
Links clones to the specified service provider. Only clones objects that do not exist in service provider.

@param dest_service_provider_id id of the service provider where to import the clone

@return clone object

=end classdoc

=cut

sub clone {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => ['dest_service_provider_id']);

    my $attrs_cloner = sub {
        my %args = @_;
        my $attrs = $args{attrs};
        for my $operand ('left_combination', 'right_combination') {
            $attrs->{ $operand . '_id' } = $self->$operand->clone(
                dest_service_provider_id => $attrs->{aggregate_condition_service_provider_id}
            )->id;
        }
        $attrs->{last_eval} = undef;
        return %$attrs;
    };

    $self->_importToRelated(
        dest_obj_id         => $args{'dest_service_provider_id'},
        relationship        => 'aggregate_condition_service_provider',
        label_attr_name     => 'aggregate_condition_label',
        attrs_clone_handler => $attrs_cloner
    );
}


=pod

=begin classdoc

Update formula string and call update formula string of dependant objects.

=end classdoc

=cut

sub updateFormulaString {
    my $self = shift;

    $self->setAttr (name=>'aggregate_condition_formula_string', value => $self->toString());
    $self->save ();

    my @rules = $self->getDependentRules;

    for my $rule (@rules) {
        $rule->updateFormulaString;
    }
}

1;
