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
package NodemetricCondition;

use strict;
use warnings;
use base 'BaseDB';
use Combination;
require 'NodemetricRule.pm';
use Combination::ConstantCombination;
use Data::Dumper;
# logger
use Log::Log4perl "get_logger";
my $log = get_logger("");

use constant ATTR_DEF => {
    nodemetric_condition_label     =>  {pattern       => '^.*$',
                                 is_mandatory   => 0,
                                 is_extended    => 0,
                                 is_editable    => 1},
    nodemetric_condition_service_provider_id =>  {pattern       => '^.*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 1},
    left_combination_id     =>  {pattern       => '^.*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 1},
    nodemetric_condition_comparator =>  {pattern       => '^(>|<|>=|<=|==)$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 1},
    right_combination_id     =>  {pattern       => '^.*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 1},
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
        my $comb =  Combination::ConstantCombination->new (
            service_provider_id => $args{nodemetric_condition_service_provider_id},
            value => $args{nodemetric_condition_threshold}
        );
        delete $args{nodemetric_condition_threshold};
        $args{right_combination_id} = $comb->id;
    }

    if ((! defined $args{left_combination_id}) && defined $args{nodemetric_condition_threshold}  ) {
        my $comb =  Combination::ConstantCombination->new (
            service_provider_id => $args{nodemetric_condition_service_provider_id},
            value => $args{nodemetric_condition_threshold}
        );
        delete $args{nodemetric_condition_threshold};
        $args{left_combination_id} = $comb->id;
    }


    my $self = $class->SUPER::new(%args);

    if(!defined $args{nodemetric_condition_label} || $args{nodemetric_condition_label} eq ''){
        $self->setAttr(name=>'nodemetric_condition_label', value => $self->toString());
        $self->save();
    }

    return $self;
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
        return $self->getAttr(name => 'nodemetric_condition_label');
    }
    else{
        my $combination_id = $self->getAttr(name => 'left_combination_id');
        my $comparator     = $self->getAttr(name => 'nodemetric_condition_comparator');
        my $threshold      = $self->getAttr(name => 'nodemetric_condition_threshold');

        return Combination->get('id'=>$combination_id)->toString(depth => $depth - 1).$comparator.$threshold;
    }
};

sub evalOnOneNode{
    my $self = shift;
    my %args = @_;

    my $monitored_values_for_one_node = $args{monitored_values_for_one_node};

    my $combination_id = $self->getAttr(name => 'left_combination_id');
    my $comparator     = $self->getAttr(name => 'nodemetric_condition_comparator');
    my $threshold      = $self->getAttr(name => 'nodemetric_condition_threshold');

    my $combination    = Combination->get('id' => $combination_id);
    my $value          = $combination->computeValueFromMonitoredValues(
                                           monitored_values_for_one_node => $monitored_values_for_one_node
                                       );
    if(not defined $value ){
        return undef;
    } else {
        my $evalString = $value.$comparator.$threshold;

        $log->info("NM Condition formula: $evalString");

        if(eval $evalString){
            return 1;
        }else{
            return 0;
        }
    }
}

sub getDependencies {
    my $self = shift;
    my @rules_from_same_service = NodemetricRule->search(hash => {nodemetric_rule_service_provider_id => $self->nodemetric_condition_service_provider_id});

    my %dependencies;
    my $id = $self->getId;

    LOOP:
    for my $rule (@rules_from_same_service) {
        my @rule_dependant_condition_ids = $rule->getDependantConditionIds;
        for my $condition_id (@rule_dependant_condition_ids) {
            if ($id == $condition_id) {
                $dependencies{$rule->nodemetric_rule_label} = {};
                next LOOP;
            }
        }
    }
    return \%dependencies;
}

sub delete {
    my $self = shift;
    $log->info('Entering deletion system');

    my @rules_from_same_service = NodemetricRule->search(hash => {nodemetric_rule_service_provider_id => $self->nodemetric_condition_service_provider_id});
    my $id = $self->getId;
    RULE:
    while(@rules_from_same_service) {
        my $rule = pop @rules_from_same_service;
        my @rule_dependant_condition_ids = $rule->getDependantConditionIds;
        for my $condition_id (@rule_dependant_condition_ids) {
            if ($id == $condition_id) {
                $rule->delete();
                next RULE;
            }
        }
    }
    return $self->SUPER::delete();
}

sub getDependantIndicatorIds {
    my $self = shift;
    my $combination = $self->left_combination;
    return $combination->getDependantIndicatorIds();
}


1;
