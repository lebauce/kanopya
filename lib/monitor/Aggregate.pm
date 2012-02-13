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
package Aggregate;

use strict;
use warnings;
use General;
#use Statistics::Descriptive;
use DescriptiveStatisticsFunction;
use TimeData::RRDTimeData;

use base 'BaseDB';


use constant ATTR_DEF => {
    cluster_id               =>  {pattern       => '^.*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 0},
    indicator_id             =>  {pattern       => '^.*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 0},
    statistics_function_name =>  {pattern       => '^(mean|variance|standard_deviation|max|min|coefficientOfVariation|kurtosis|firstValue)$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 0},
    window_time              =>  {pattern       => '^.*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 0},
};

sub getAttrDef { return ATTR_DEF; }

sub calculate{
    my $self = shift;
    my %args = @_;

    General::checkParams args => \%args, required => [
        'values',
    ];
    
    my $values  = $args{values};
    #my $stat = Statistics::Descriptive::Full->new();
    my $stat = DescriptiveStatisticsFunction->new();
    $stat->add_data($values);
    
    my $funcname = $self->getAttr(name => 'statistics_function_name');
    my $mean = $stat->$funcname();
    return $mean;

}


sub new {
    my $class = shift;
    my %args = @_;
    
    my $self = $class->SUPER::new(%args);
    
    
    my $aggregate_id = $self->getAttr(name=>'aggregate_id');
    my $name         = 'timeDB_'.$aggregate_id.'.rrd';
    my $time         = time();
    my %options      = (step => '60', start => $time);
    my %DS           = (
        name      => $aggregate_id,
        type      => 'GAUGE',
        heartbeat => '60',
        min       => '0',
        max       => 'U',
        rpn       => 'exp'
    );
        my %RRA = (function => 'LAST', XFF => '0.9', PDPnb => 1, CPDnb => 30);
        
        RRDTimeData::createTimeDataStore(name => $name , options => \%options , DS => \%DS, RRA => \%RRA);
    return $self;
}

=head2 toString

    desc: return a string representation of the entity

=cut

sub toString {
    my $self = shift;

    my $aggregate_id = $self->getAttr(name => 'aggregate_id');
    my $cluster_id   = $self->getAttr(name => 'cluster_id');
    my $indicator_id = $self->getAttr(name => 'indicator_id');
    my $sfn          = $self->getAttr(name => 'statistics_function_name');
    my $w_time       = $self->getAttr(name => 'window_time');

    return   'id = '              . $aggregate_id
           . ' ; cluster_id = '   . $cluster_id
           . ' ; indicator_id = ' . $indicator_id
           . ' ; function = '      . $sfn
           . ' ; w_time = '        . $w_time ."\n"
          ;
}



1;
