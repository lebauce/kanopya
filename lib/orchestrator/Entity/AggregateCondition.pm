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
package Entity::AggregateCondition;

use strict;
use warnings;
use TimeData::RRDTimeData;
use Entity::Combination::AggregateCombination;
require 'Entity/AggregateRule.pm';
use base 'Entity';
use Data::Dumper;
# logger
use Log::Log4perl "get_logger";
my $log = get_logger("");

use constant ATTR_DEF => {
    aggregate_condition_id       =>  {pattern       => '^.*$',
                                 is_mandatory   => 0,
                                 is_extended    => 0,
                                 is_editable    => 0},
    aggregate_condition_label     =>  {pattern       => '^.*$',
                                 is_mandatory   => 0,
                                 is_extended    => 0,
                                 is_editable    => 1},
    aggregate_condition_service_provider_id =>  {pattern       => '^.*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 0},
    left_combination_id     =>  {pattern       => '^.*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 1},
    right_combination_id     =>  {pattern       => '^.*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 1},
    comparator =>  {pattern       => '^(>|<|>=|<=|==)$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 1},
    state              =>  {pattern       => '(enabled|disabled)$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 1},
    time_limit         =>  {pattern       => '^.*$',
                                 is_mandatory   => 0,
                                 is_extended    => 0,
                                 is_editable    => 1},
    last_eval          =>  {pattern       => '^.*$',
                                 is_mandatory   => 0,
                                 is_extended    => 0,
                                 is_editable    => 1},
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

    if(!defined $args{aggregate_condition_label} || $args{aggregate_condition_label} eq ''){
        $self->setAttr(name=>'aggregate_condition_label', value => $self->toString());
        $self->save();
    }
    return $self;
}

=head2 updateName

    desc: set entity's name to .toString() return value

=cut

sub updateName {
    my $self    = shift;

    $self->setAttr(name => 'aggregate_condition_label', value => $self->toString);
    $self->save;
}

=head2 toString

    desc: return a string representation of the entity

=cut

sub toString {
    my ($self, %args) = @_;
    my $depth;
    if(defined $args{depth}) {
        $depth = $args{depth};
    }
    else {
        $depth = -1;
    }

    if($depth == 0) {
        return $self->getAttr(name => 'aggregate_condition_label');
    }
    else{
        return $self->left_combination->toString(depth => $depth - 1).$self->comparator.$self->right_combination->toString(depth => $depth - 1);
    }
}

sub eval{
    my $self = shift;

    my $comparator  = $self->getAttr(name => 'comparator');
    my $left_value  = $self->left_combination->computeLastValue();
    my $right_value = $self->right_combination->computeLastValue();

    if(defined $left_value && defined $right_value){
        my $evalString = $left_value.$comparator.$right_value;
        $log->info("CM Combination formula: $evalString");

        if(eval $evalString){
            $log->info($evalString."=> true");
            $self->setAttr(name => 'last_eval', value => 1);
            $self->save();
            return 1;
        }else{
            $log->info($evalString."=> false");
            $self->setAttr(name => 'last_eval', value => 0);
            $self->save();
            return 0;
        }
    }else{
        $log->warn('No data received from DB for '.($self->left_combination)." or ".($self->right_combination));
        $self->setAttr(name => 'last_eval', value => undef);
        $self->save();
        return undef;
    }
}

sub getDependencies {
    my $self = shift;
    my @rules_from_same_service = Entity::AggregateRule->search(hash => {aggregate_rule_service_provider_id => $self->aggregate_condition_service_provider_id});

    my %dependencies;
    my $id = $self->getId;
    for my $rule (@rules_from_same_service) {
        my @rule_dependant_condition_ids = $rule->getDependantConditionIds;
        for my $condition_id (@rule_dependant_condition_ids) {
            if ($id == $condition_id) {
                $dependencies{$rule->aggregate_rule_label} = {};
            }
        }
    }
    return \%dependencies;
}

sub delete {
    my $self = shift;
    my @rules_from_same_service = Entity::AggregateRule->search(hash => {aggregate_rule_service_provider_id => $self->aggregate_condition_service_provider_id});

    my $id = $self->getId;
    LOOP:
    while (@rules_from_same_service) {
        my $rule = pop @rules_from_same_service;
        my @rule_dependant_condition_ids = $rule->getDependantConditionIds;
        for my $condition_id (@rule_dependant_condition_ids) {
            if ($id == $condition_id) {
                $rule->delete();
                next LOOP;
            }
        }
    }
    return $self->SUPER::delete();
}

sub update {
    my ($self, %args) = @_;

    my $left_combi = $self->left_combination;
    my $right_combi = $self->right_combination;

    if ((! defined $args{right_combination_id}) && defined $args{threshold}) {
        my $comb = Entity::Combination::ConstantCombination->new (
            service_provider_id => $args{aggregate_condition_service_provider_id},
            value => $args{threshold},
        );
        delete $args{threshold};
        $args{right_combination_id} = $comb->id;
    }

    if ((! defined $args{left_combination_id}) && defined $args{threshold}) {
        my $comb = Entity::Combination::ConstantCombination->new (
            service_provider_id => $args{aggregate_condition_service_provider_id},
            value => $args{threshold},
        );
        delete $args{threshold};
        $args{left_combination_id} = $comb->id;
    }

    my $rep = $self->SUPER::update(%args);
    $left_combi->deleteIfConstant();
    $right_combi->deleteIfConstant();
    return $rep;
}
1;
