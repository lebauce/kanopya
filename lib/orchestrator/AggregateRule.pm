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
package AggregateRule;

use strict;
use warnings;
use TimeData::RRDTimeData;
use base 'BaseDB';
use AggregateCondition;
use Data::Dumper;

use constant ATTR_DEF => {
    aggregate_rule_id        =>  {pattern       => '^.*$',
                                 is_mandatory   => 0,
                                 is_extended    => 0,
                                 is_editable    => 0},
    aggregate_rule_formula   =>  {pattern       => '^.*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 1},
    aggregate_rule_last_eval =>  {pattern       => '^(0|1)$',
                                 is_mandatory   => 0,
                                 is_extended    => 0,
                                 is_editable    => 1},
    aggregate_rule_timestamp =>  {pattern       => '^.*$',
                                 is_mandatory   => 0,
                                 is_extended    => 0,
                                 is_editable    => 1},
    aggregate_rule_state     =>  {pattern       => '(enabled|disabled)$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 1},
    aggregate_rule_action_id =>  {pattern       => '^.*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 1},
};

sub getAttrDef { return ATTR_DEF; }

sub toString(){
    my $self = shift;
    
    my $formula = $self->getAttr(name => 'aggregate_rule_formula');
    my @array = split(/(id\d+)/,$formula);
    for my $element (@array) {
        
        if( $element =~ m/id(\d+)/)
        {
            $element = AggregateCondition->get('id'=>substr($element,2))->toString();
        }
     }
     return "@array";
}


sub eval {
    my $self = shift;
    
    my $formula = $self->getAttr(name => 'aggregate_rule_formula');
    
    #Split aggregate_rule id from $formula
    my @array = split(/(id\d+)/,$formula);
    
    #replace each rule id by its evaluation
    for my $element (@array) {
        
        if( $element =~ m/id(\d+)/)
        {
            $element = AggregateCondition->get('id'=>substr($element,2))->eval();
        }
     }
     
    my $res = -1;
    my $arrayString = '$res = '."@array"; 
    
    #Evaluate the logic formula
    eval $arrayString;
    my $store = ($res)?1:0;
    print "$arrayString => $store ($res)\n";
     
    $self->setAttr(name => 'aggregate_rule_last_eval',value=>$store);
    $self->setAttr(name => 'aggregate_rule_timestamp',value=>time());
    $self->save();
    return $res;
        
#    eval $arrayString;
#    
#    print "$arrayString  => $res\n";
    
    #my $parser = Parse::BooleanLogic->new( operators => ['AND', 'OR', 'NOT'] );
    
    #my $tree = $parser->as_array($formula);
    
#    print Dumper $tree;
#    
#    my $solver = sub {
#        my ($condition, $some) = @_;
#            my $ac = ;
#            return $ac->eval();
#    };
#    my $res = $parser->solve( $tree, $solver, undef);
#    $self->setAttr(name => 'aggregate_rule_last_eval',value=>$res);
#    $self->setAttr(name => 'aggregate_rule_timestamp',value=>time());
#    $self->save();
#    return $res;
    
}


#=head2 toString
#
#    desc: return a string representation of the entity
#
#=cut

#sub toString {
#    my $self = shift;
#
#    my $aggregate_condition_id        = $self->getAttr(name => 'aggregate_condition_id');
#    my $aggregate_id   = $self->getAttr(name => 'aggregate_id');
#    my $comparator     = $self->getAttr(name => 'comparator');
#    my $threshold      = $self->getAttr(name => 'threshold');
#    my $state          = $self->getAttr(name => 'state');
#    my $time_limit     = $self->getAttr(name => 'time_limit');
#    my $last_eval      = $self->getAttr(name => 'last_eval');
#
#
#    return   'aggregate_condition_id = '              . $aggregate_condition_id
#           . ' ; aggregate_id = '   . $aggregate_id
#           . ' ; comparator = ' . $comparator
#           . ' ; threshold = '      . $threshold
#           . ' ; state = '      . $state           
#           . ' ; time_limit = '        . $time_limit 
#           . ' ; last_eval = '        . $last_eval
#           ."\n"
#          ;
#}



1;
