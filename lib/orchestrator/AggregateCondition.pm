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
use AggregateCombination;

use base 'BaseDB';
# logger
use Log::Log4perl "get_logger";
my $log = get_logger("orchestrator");

use constant ATTR_DEF => {
    aggregate_condition_id               =>  {pattern       => '^.*$',
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
    aggregate_combination_id     =>  {pattern       => '^.*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 1},
    comparator =>  {pattern       => '^(>|<|>=|<=|==)$',
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
                                 is_mandatory   => 0,
                                 is_extended    => 0,
                                 is_editable    => 1},
    last_eval          =>  {pattern       => '^.*$',
                                 is_mandatory   => 0,
                                 is_extended    => 0,
                                 is_editable    => 1},
};

sub getAttrDef { return ATTR_DEF; }

sub new {
    my $class = shift;
    my %args = @_;
    my $self = $class->SUPER::new(%args);
    
    if(!defined $args{aggregate_condition_label} || $args{aggregate_condition_label} eq ''){
        $self->setAttr(name=>'aggregate_condition_label', value => $self->toString());
        $self->save();
    }
    return $self;
}

=head2 toString

    desc: return a string representation of the entity

=cut

sub toString {
    my $self = shift;
    my $aggregate_combination_id   = $self->getAttr(name => 'aggregate_combination_id');
    my $comparator                 = $self->getAttr(name => 'comparator');
    my $threshold                  = $self->getAttr(name => 'threshold');
    
    return AggregateCombination->get('id'=>$aggregate_combination_id)->toString().$comparator.$threshold;
}

sub eval{
    my $self = shift;
    
    my $aggregate_combination_id    = $self->getAttr(name => 'aggregate_combination_id');
    my $comparator      = $self->getAttr(name => 'comparator');
    my $threshold       = $self->getAttr(name => 'threshold');

    my $agg_combination = AggregateCombination->get('id' => $aggregate_combination_id);
    my $value = $agg_combination->computeLastValue(); 
    if(defined $value){
        my $evalString = $value.$comparator.$threshold;
        if(eval $evalString){        
            #print $evalString."=> true\n";
            $log->info($evalString."=> true");        
            $self->setAttr(name => 'last_eval', value => 1);
            $self->save();
            return 1;
        }else{
            #print $evalString."=> false\n";
            $log->info($evalString."=> false");        
            $self->setAttr(name => 'last_eval', value => 0);
            $self->save();
            return 0;
        }
    }else{
        $log->warn("No data received from DB for $aggregate_combination_id");
        $self->setAttr(name => 'last_eval', value => undef);
        $self->save();
        return undef;
    }
}

sub getCombination{
    my ($self) = @_;
    return AggregateCombination->get('id' => $self->getAttr(name => 'aggregate_combination_id'));
}
1;
