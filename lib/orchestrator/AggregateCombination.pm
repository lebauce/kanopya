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
package AggregateCombination;

use strict;
use warnings;
use base 'BaseDB';
use Aggregate;
use TimeData::RRDTimeData;


use constant ATTR_DEF => {
    aggregate_combination_id      =>  {pattern       => '^.*$',
                                 is_mandatory   => 0,
                                 is_extended    => 0,
                                 is_editable    => 0},
    aggregate_combination_formula =>  {pattern       => '^.*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 1},
};

sub getAttrDef { return ATTR_DEF; }


=head2 toString

    desc: return a string representation of the entity

=cut

sub toString {
    my $self = shift;
    #my $aggregate_combination_id       = $self->getAttr(name => 'aggregate_combination_id');
    #my $aggregate_combination_formula  = $self->getAttr(name => 'aggregate_combination_formula');

    my $formula = $self->getAttr(name => 'aggregate_combination_formula');
    
    #Split aggregate_rule id from $formula
    my @array = split(/(id\d+)/,$formula);
    #replace each rule id by its evaluation
    for my $element (@array) {
        if( $element =~ m/id\d+/)
        {
            #Remove "id" from the begining of $element, get the corresponding aggregator and get the lastValueFromDB
            $element = Aggregate->get('id'=>substr($element,2))->toString();
        }
     }
     
    return "@array";

}

sub calculate{
    my $self = shift;
    
    my $formula = $self->getAttr(name => 'aggregate_combination_formula');
    
    #Split aggregate_rule id from $formula
    my @array = split(/(id\d+)/,$formula);
    #replace each rule id by its evaluation
    for my $element (@array) {
        if( $element =~ m/id\d+/)
        {
            #Remove "id" from the begining of $element, get the corresponding aggregator and get the lastValueFromDB
            $element = Aggregate->get('id'=>substr($element,2))->getLastValueFromDB();
        }
     }
     
    my $res = -1;
    my $arrayString = '$res = '."@array"; 
    
    #Evaluate the logic formula
    eval $arrayString;
    #print "$arrayString \n";
    return $res;
}


1;
