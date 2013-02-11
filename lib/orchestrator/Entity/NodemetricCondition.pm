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

Condition on combination value

@see <package>Entity::Combination</package>
@see <package>Entity::Combination::ConstantCombination</package>
@see <package>Entity::Combination::NodemetricCombination</package>

=end classdoc

=cut

package Entity::NodemetricCondition;

use strict;
use warnings;
use base 'Entity';
use Entity::Combination;
require 'Entity/Rule/NodemetricRule.pm';
use Entity::Combination::ConstantCombination;
use Data::Dumper;
# logger
use Log::Log4perl "get_logger";
my $log = get_logger("");

use constant ATTR_DEF => {
    nodemetric_condition_label => {
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_extended     => 0,
        is_editable     => 1,
    },
    nodemetric_condition_service_provider_id => {
        pattern         => '^.*$',
        is_mandatory    => 1,
        is_extended     => 0,
        is_editable     => 1,
    },
    left_combination_id => {
        pattern         => '^.*$',
        is_mandatory    => 1,
        is_extended     => 0,
        is_editable     => 1,
    },
    nodemetric_condition_comparator => {
        pattern         => '^(>|<|>=|<=|==)$',
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
    nodemetric_condition_formula_string => {
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
            description => 'updateName',
            perm_holder => 'entity'
        },
        'getDependencies' => {
            'description' => 'return dependencies tree for this object',
            'perm_holder' => 'entity',
        },
    };
}

sub new {
    my $class = shift;
    my %args = @_;

    if ((! defined $args{right_combination_id}) && defined $args{nodemetric_condition_threshold}  ) {
        my $comb =  Entity::Combination::ConstantCombination->new (
            service_provider_id => $args{nodemetric_condition_service_provider_id},
            value => $args{nodemetric_condition_threshold}
        );
        delete $args{nodemetric_condition_threshold};
        $args{right_combination_id} = $comb->id;
    }

    if ((! defined $args{left_combination_id}) && defined $args{nodemetric_condition_threshold}  ) {
        my $comb =  Entity::Combination::ConstantCombination->new (
            service_provider_id => $args{nodemetric_condition_service_provider_id},
            value => $args{nodemetric_condition_threshold}
        );
        delete $args{nodemetric_condition_threshold};
        $args{left_combination_id} = $comb->id;
    }


    my $self = $class->SUPER::new(%args);

    my $toString = $self->toString();

    $self->setAttr (name=>'nodemetric_condition_formula_string', value => $toString);
    if(!defined $args{nodemetric_condition_label} || $args{nodemetric_condition_label} eq ''){
        $self->setAttr(name=>'nodemetric_condition_label', value => $toString);
    }
    $self->save();
    return $self;
}

sub label {
    my $self = shift;
    return $self->nodemetric_condition_label;
}

=head2 updateName

    desc: set entity's name to .toString() return value

=cut

sub updateName {
    my $self    = shift;

    $self->setAttr(name => 'nodemetric_condition_label', value => $self->toString);
    $self->save;
}

=head2 toString

    desc: return a string representation of the entity
            add unit only if right combi is a constant

=cut

sub toString {
    my $self = shift;

    # Not used yet due to bad Combination::computeUnit() behavior (see also AggregateCondition::toString())
    my $unit = '';
    if ((ref $self->right_combination) eq 'Entity::Combination::ConstantCombination') {
        my $left_unit = $self->left_combination->combination_unit;
        if ($left_unit && (($left_unit ne '?') || ($left_unit ne '-'))) {
            $unit = $left_unit;
        }
    }

    return  $self->left_combination->combination_formula_string.' '
           .$self->nodemetric_condition_comparator.' '
           .$self->right_combination->combination_formula_string;
};

sub evalOnOneNode{
    my $self = shift;
    my %args = @_;

    my $monitored_values_for_one_node = $args{monitored_values_for_one_node};

    my $comparator     = $self->getAttr(name => 'nodemetric_condition_comparator');

    my $left_combination  = $self->left_combination;
    my $right_combination = $self->right_combination;

    my $left_value = $left_combination->computeValueFromMonitoredValues(
                         monitored_values_for_one_node => $monitored_values_for_one_node
                     );

    my $right_value = $right_combination->computeValueFromMonitoredValues(
                          monitored_values_for_one_node => $monitored_values_for_one_node
                      );

    if((not defined $left_value) || (not defined $right_value)){
        return undef;
    } else {
        my $evalString = $left_value.$comparator.$right_value;

        $log->info("NM Condition formula: $evalString");

        if(eval $evalString){
            return 1;
        }else{
            return 0;
        }
    }
}


sub getDependentRules {
    my $self = shift;
    my @rules_from_same_service = Entity::Rule::NodemetricRule->search(
                                      hash => {
                                          nodemetric_rule_service_provider_id => $self->nodemetric_condition_service_provider_id
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

sub getDependencies {
    my $self = shift;

    my @rules = $self->getDependentRules;

    my %dependencies;
    for my $rule (@rules) {
        $dependencies{$rule->nodemetric_rule_label} = {};
    }
    return \%dependencies;
}

sub delete {
    my $self = shift;
    my @rules_from_same_service = Entity::Rule::NodemetricRule->search(hash => {nodemetric_rule_service_provider_id => $self->nodemetric_condition_service_provider_id});
    my $id = $self->getId;
    RULE:
    while(@rules_from_same_service) {
        my $rule = pop @rules_from_same_service;
        my @rule_dependant_condition_ids = $rule->getDependentConditionIds;
        for my $condition_id (@rule_dependant_condition_ids) {
            if ($id == $condition_id) {
                $rule->delete();
                next RULE;
            }
        }
    }
    my $comb_left  = $self->left_combination;
    my $comb_right = $self->right_combination;
    $self->SUPER::delete();
    $comb_left->deleteIfConstant();
    $comb_right->deleteIfConstant();
}

sub getDependentIndicatorIds {
    my $self = shift;
    return ($self->left_combination->getDependentIndicatorIds(), $self->right_combination->getDependentIndicatorIds());
}

sub update {
    my ($self, %args) = @_;
    my $service_provider_id = $args{nodemetric_condition_service_provider_id} ?
                                  $args{nodemetric_condition_service_provider_id} :
                                  $self->nodemetric_condition_service_provider_id ;


    my $two_attributes = 0;
    if (defined $args{nodemetric_condition_threshold}) { $two_attributes++; }
    if (defined $args{left_combination_id}) { $two_attributes++; }
    if (defined $args{right_combination_id}) { $two_attributes++; }

    if ( $two_attributes == 0) {
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
            value => $args{nodemetric_condition_threshold}
        );
        delete $args{nodemetric_condition_threshold};
        $args{left_combination_id} = $new_left_combination->id;
    }
    elsif (! defined $args{right_combination_id}) {
        my $new_right_combination =  Entity::Combination::ConstantCombination->new (
            service_provider_id => $service_provider_id,
            value => $args{nodemetric_condition_threshold}
        );
        delete $args{nodemetric_condition_threshold};
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
                dest_service_provider_id => $attrs->{nodemetric_condition_service_provider_id}
            )->id;
        }
        return %$attrs;
    };

    $self->_importToRelated(
        dest_obj_id         => $args{'dest_service_provider_id'},
        relationship        => 'nodemetric_condition_service_provider',
        label_attr_name     => 'nodemetric_condition_label',
        attrs_clone_handler => $attrs_cloner
    );
}


=pod

=begin classdoc

Compute and update the instance formula_string attribute and call the update of the formula_string
attribute of the objects which depend on the instance.

=end classdoc

=cut


sub updateFormulaString {
    my $self = shift;

    $self->setAttr (name=>'nodemetric_condition_formula_string', value => $self->toString());
    $self->save ();

    my @rules = $self->getDependentRules;

    for my $rule (@rules) {
        $rule->updateFormulaString;
    }
}

1;
