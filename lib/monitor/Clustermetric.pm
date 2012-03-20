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
package Clustermetric;

use strict;
use warnings;
use General;
use DescriptiveStatisticsFunction;
use TimeData::RRDTimeData;
use Indicator;

use base 'BaseDB';

# logger
use Log::Log4perl "get_logger";
my $log = get_logger("aggregator");

use constant ATTR_DEF => {
    clustermetric_service_provider_id          =>  {pattern       => '^.*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 0},
    clustermetric_label     =>  {pattern       => '^.*$',
                                 is_mandatory   => 0,
                                 is_extended    => 0,
                                 is_editable    => 1},
    clustermetric_indicator_id             =>  {pattern       => '^.*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 0},
    clustermetric_statistics_function_name =>  {pattern       => '^(mean|variance|standard_deviation|max|min|kurtosis|skewness|numOfDataOutOfRange|sum)$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 0},
    clustermetric_window_time              =>  {pattern       => '^.*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 0},
};

sub getAttrDef { return ATTR_DEF; }

sub compute{
    my $self = shift;
    my %args = @_;

    General::checkParams args => \%args, required => [
        'values',
    ];
    
    my $values  = $args{values};
    #my $stat = Statistics::Descriptive::Full->new();
    my $stat = DescriptiveStatisticsFunction->new();
    $stat->add_data($values);
    
    my $funcname = $self->getAttr(name => 'clustermetric_statistics_function_name');
    my $mean = $stat->$funcname();
    return $mean;
}


sub getValuesFromDB{
    my $self = shift;
    my %args = @_;
    General::checkParams args => \%args, required => ['start_time','stop_time'];
    
    my $id = $self->getAttr(name=>'clustermetric_id');
    
    my %rep = RRDTimeData::fetchTimeDataStore(
                                            name         => $id, 
                                            start        => $args{start_time},
                                            stop         => $args{stop_time}
                                          );
    return \%rep;
}
sub getLastValueFromDB{
    my $self = shift;
	my $id = $self->getAttr(name=>'clustermetric_id');
    my %last_value = RRDTimeData::getLastUpdatedValue(clustermetric_id => $id); 
    my @indicator = (values %last_value);
    return $indicator[0];
}


sub new {
    my $class = shift;
    my %args = @_;
    
    my $self = $class->SUPER::new(%args);
    
    $log->info("Warning when creating ClusterMetric it is useful to create a 
                corresponding ClusterMetricCombination");
                

    
    #Create RRD DB
    my $clustermetric_id = $self->getAttr(name=>'clustermetric_id');
    RRDTimeData::createTimeDataStore(name => $clustermetric_id);
    
    if(!defined $args{clustermetric_label} || $args{clustermetric_label} eq ''){
        $self->setAttr(name=>'clustermetric_label', value=>$self->toString());
        $self->save();
    }
    return $self;
}

=head2 toString

    desc: return a string representation of the entity

=cut

sub toString {
    my $self = shift;

    my $indicator_id = $self->getAttr(name => 'clustermetric_indicator_id');
    my $sfn          = $self->getAttr(name => 'clustermetric_statistics_function_name');

    return $sfn.'('.(Indicator->get('id' => $indicator_id)->getAttr(name=>'indicator_name')).')';
}



1;
