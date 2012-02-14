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
package AggregateCondition;

use strict;
use warnings;
use TimeData::RRDTimeData;
use base 'BaseDB';

use constant ATTR_DEF => {
    aggregate_condition_id               =>  {pattern       => '^.*$',
                                 is_mandatory   => 0,
                                 is_extended    => 0,
                                 is_editable    => 0},
    aggregate_id             =>  {pattern       => '^.*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 1},
    comparator =>  {pattern       => '^(>|<|>=|<=|=)$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 1},
    threshold =>  {pattern       => '^.*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 1},
    state              =>  {pattern       => '(enabled|disabled)$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 1},
    time_limit         =>  {pattern       => '^.*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 1},
    last_eval          =>  {pattern       => '^.*$',
                                 is_mandatory   => 0,
                                 is_extended    => 0,
                                 is_editable    => 1},
};

sub getAttrDef { return ATTR_DEF; }


=head2 toString

    desc: return a string representation of the entity

=cut

sub toString {
    my $self = shift;

    my $aggregate_condition_id        = $self->getAttr(name => 'aggregate_condition_id');
    my $aggregate_id   = $self->getAttr(name => 'aggregate_id');
    my $comparator     = $self->getAttr(name => 'comparator');
    my $threshold      = $self->getAttr(name => 'threshold');
    my $state          = $self->getAttr(name => 'state');
    my $time_limit     = $self->getAttr(name => 'time_limit');
    my $last_eval      = $self->getAttr(name => 'last_eval');


    return   'aggregate_condition_id = '              . $aggregate_condition_id
           . ' ; aggregate_id = '   . $aggregate_id
           . ' ; comparator = ' . $comparator
           . ' ; threshold = '      . $threshold
           . ' ; state = '      . $state           
           . ' ; time_limit = '        . $time_limit 
           . ' ; last_eval = '        . $last_eval
           ."\n"
          ;
}

sub eval{
    my $self = shift;
    
    my $aggregate_id    = $self->getAttr(name => 'aggregate_id');
    my $comparator      = $self->getAttr(name => 'comparator');
    my $threshold       = $self->getAttr(name => 'threshold');

    #my %aggregatorHash = RRDTimeData::fetchTimeDataStore(name => $aggregate_id);
    #my @aggregatorValues = values(%aggregatorHash); 
    my $evalString = '0.5'.$comparator.$threshold; 
    if(eval $evalString){
        $self->setAttr(name => 'last_eval', value => 1);
        $self->save();
        return 1;
    }else{
        $self->setAttr(name => 'last_eval', value => 0);
        $self->save();
        return 0;
    }
    
}


1;
