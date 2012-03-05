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
package NodemetricRule;

use strict;
use warnings;
use base 'BaseDB';

# logger
use Log::Log4perl "get_logger";
my $log = get_logger("orchestrator");

use constant ATTR_DEF => {
    nodemetric_rule_id        =>  {pattern       => '^.*$',
                                 is_mandatory   => 0,
                                 is_extended    => 0,
                                 is_editable    => 0},
    nodemetric_rule_formula   =>  {pattern       => '^.*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 1},
    nodemetric_rule_last_eval =>  {pattern       => '^(0|1)$',
                                 is_mandatory   => 0,
                                 is_extended    => 0,
                                 is_editable    => 1},
    nodemetric_rule_timestamp =>  {pattern       => '^.*$',
                                 is_mandatory   => 0,
                                 is_extended    => 0,
                                 is_editable    => 1},
    nodemetric_rule_state     =>  {pattern       => '(enabled|disabled|disabled_temp)$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 1},
    nodemetric_rule_action_id =>  {pattern       => '^.*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 1},
    nodemetric_rule_service_provider_id =>  {pattern       => '^.*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 1},
};

sub getAttrDef { return ATTR_DEF; }

#C/P of homonym method in AggregateRulePackage 
sub getDependantConditionIds {
    my $self = shift;
    my $formula = $self->getAttr(name => 'nodemetric_rule_formula');
    my @array = split(/(id\d+)/,$formula);
    
    my @conditionIds;
    
    for my $element (@array) {
        if( $element =~ m/id\d+/)
        {
            push @conditionIds, substr($element,2);
        }
    }
    return @conditionIds;
}


sub eval {
    my $self = shift;
    
    my $formula = $self->getAttr(name => 'nodemetric_rule_formula');
    
    #Split nodemetric_rule id from $formula
    my @array = split(/(id\d+)/,$formula);
    
    #replace each rule id by its evaluation
    for my $element (@array) {
        
        if( $element =~ m/id(\d+)/)
        {
            $element = NodemetricCondition->get('id'=>substr($element,2))->eval();
        }
     }
     
    my $res = -1;
    my $arrayString = '$res = '."@array"; 
    
    #Evaluate the logic formula
    eval $arrayString;
    my $store = ($res)?1:0;

    #print "Evaluated Rule : $arrayString => $store ($res)\n";
    #$log->info("Evaluated Rule : $arrayString => $store ($res)");
     
    $self->setAttr(name => 'nodemetric_rule_last_eval',value=>$store);
    $self->setAttr(name => 'nodemetric_rule_timestamp',value=>time());
    $self->save();
    return $res;
}
1;
