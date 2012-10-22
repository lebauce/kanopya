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
use Data::Dumper;
use DescriptiveStatisticsFunction;
use TimeData::RRDTimeData;
use Indicator;
require 'AggregateCombination.pm';

use base 'BaseDB';

# logger
use Log::Log4perl "get_logger";
my $log = get_logger("");

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
    clustermetric_statistics_function_name =>  {pattern       => '^(mean|variance|std|max|min|kurtosis|skewness|dataOut|sum|count)$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 0},
    clustermetric_window_time              =>  {pattern       => '^.*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 0},
};

sub getAttrDef { return ATTR_DEF; }

sub methods {
  return {
    'regenTimeDataStores'  => {
      'description' => 'Delete and create again all data stores',
      'perm_holder' => 'entity'
    },
    'resizeTimeDataStores'  => {
      'description' => 'Resize all data stores',
      'perm_holder' => 'entity'
    },
    'getDependencies' => {
        'description' => 'return dependencies tree for this object',
        'perm_holder' => 'entity',
    },
  }
}

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
                                            end          => $args{stop_time}
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

=head2 regenTimeDataStores

    Class: Public
    Desc: delete and create again every time data store for the clustermetrics
    Args: none
    Return: none

=cut

sub regenTimeDataStores {

    my @clustermetrics = Clustermetric->search(hash => { });

    foreach my $clustermetric (@clustermetrics) {
        #delete previous rrd
        RRDTimeData::deleteTimeDataStore(name => $clustermetric->clustermetric_id);
        #create new rrd
        RRDTimeData::createTimeDataStore(name => $clustermetric->clustermetric_id);
    }
}

=head2 resizeTimeDataStores

    Class: Public
    Desc: resize every time data store for the clustermetrics
    Args: storage_duration in seconds
    Return: none

=cut

sub resizeTimeDataStores {
    my ($class, %args) = @_;
    General::checkParams(args => \%args, required => ['storage_duration']);

    my @clustermetrics = Clustermetric->search(hash => { });
    foreach my $clustermetric (@clustermetrics) {
        RRDTimeData::resizeTimeDataStore(storage_duration => $args{storage_duration}, clustermetric_id => $clustermetric->clustermetric_id);
    }
}

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new(%args);

    # Create RRD DB
    my $clustermetric_id = $self->getAttr(name=>'clustermetric_id');
    RRDTimeData::createTimeDataStore(name => $clustermetric_id);

    # Ask the collector manager to collect the related indicator
    my $service_provider = $self->clustermetric_service_provider;
    my $collector = $service_provider->getManager(manager_type => "collector_manager");
    $collector->collectIndicator(indicator_id        => $self->clustermetric_indicator_id,
                                 service_provider_id => $service_provider->getId);

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
    my ($self, %args) = @_;
    my $depth;
    if(defined $args{depth}) {
        $depth = $args{depth};
    }
    else {
        $depth = -1;
    }

    if($depth == 0) {
        return $self->getAttr(name => 'clustermetric_label');
    }
    else{

        my $service_provider = $self->clustermetric_service_provider;
        my $collector = $service_provider->getManager(manager_type => "collector_manager");
        my $indicator = $collector->getIndicator(id => $self->clustermetric_indicator_id);

        return $self->clustermetric_statistics_function_name .
               '(' . $indicator->toString() . ')';
    }
}

sub getUnit {
    my ($self, %args) = @_;

    my $stat_func = $self->clustermetric_statistics_function_name;
    my $keep_unit = grep { $_ eq $stat_func } qw(mean variance std max min sum);
    if (!$keep_unit) {
        return '-';
    }

    my $service_provider = $self->clustermetric_service_provider;
    my $collector = $service_provider->getManager(manager_type => "collector_manager");
    my $indicator_unit = $collector->getIndicator(id => $self->clustermetric_indicator_id)->getAttr(name => 'indicator_unit') || '?';

    return $indicator_unit;
}

sub getDependencies {
    my $self = shift;

    my @aggregate_combinations_from_same_service = AggregateCombination->search(hash => {aggregate_combination_service_provider_id => $self->clustermetric_service_provider_id});
    my $id = $self->getId;

    my %dependencies;
    LOOP:
    for my $aggregate_combination (@aggregate_combinations_from_same_service) {
        my @cluster_metric_ids = $aggregate_combination->dependantClusterMetricIds();

        for my $cluster_metric_id (@cluster_metric_ids) {
            if ($id == $cluster_metric_id) {
                $dependencies{$aggregate_combination->aggregate_combination_label} = $aggregate_combination->getDependencies;
                next LOOP;
            }
        }
    }

    return \%dependencies;
}

sub delete {
    my $self = shift;

    my @aggregate_combinations_from_same_service = AggregateCombination->search(hash => {aggregate_combination_service_provider_id => $self->clustermetric_service_provider_id});
    my $id = $self->getId;

    LOOP:
    while (@aggregate_combinations_from_same_service) {
        my $aggregate_combination = pop @aggregate_combinations_from_same_service;
        my @cluster_metric_ids = $aggregate_combination->dependantClusterMetricIds();

        for my $cluster_metric_id (@cluster_metric_ids) {
            if ($id == $cluster_metric_id) {
                $aggregate_combination->delete();
                next LOOP;
            }
        }
    }
    return $self->SUPER::delete();
}

1;
