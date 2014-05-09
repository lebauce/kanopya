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
package Entity::Indicator;
use base Entity;

use strict;
use warnings;

use Entity::Metric::Clustermetric;
use Entity::Metric::Combination::NodemetricCombination;
use TimeData::RRDTimeData;

use Data::Dumper;
use Log::Log4perl "get_logger";
my $log = get_logger("");

use constant ATTR_DEF => {
    indicator_id => {
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_extended     => 0,
        is_editable     => 0
    },
    # The user friendly name of indicator (display)
    indicator_label => {
        pattern         => '^.*$',
        is_mandatory    => 1,
        is_extended     => 0,
        is_editable     => 1
    },
    # the data source name of the indicator (used by collector)
    indicator_name => {
        pattern         => '^.*$',
        is_mandatory    => 1,
        is_extended     => 0,
        is_editable     => 1
    },
    indicator_oid  => {
        pattern         => '^.*$',
        is_mandatory    => 1,
        is_extended     => 0,
        is_editable     => 1
    },
    indicator_min => {
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_extended     => 0,
        is_editable     => 1
    },
    indicator_max => {
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_extended     => 0,
        is_editable     => 1
    },
    indicator_color => {
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_extended     => 0,
        is_editable     => 1},
    indicatorset_id => {
        pattern          => '^.*$',
        is_mandatory    => 1,
        is_extended     => 0,
        is_editable     => 1
    },
    indicator_unit => {
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_extended     => 0,
        is_editable     => 1
    },
};

sub getAttrDef { return ATTR_DEF; }

sub methods {
    return {
        toString  => {
            description => 'toString',
        },
        getDependencies => {
            description => 'return dependencies tree for this object',
        },
    };
}

sub toString {
    my $self = shift;

    return $self->indicator_label;
}

sub getDependencies {
    my $self = shift;
    my %dependencies;

    my @related_collector_indicators = $self->collector_indicators;


    # Service
    for my $collector_indicator (@related_collector_indicators) {

        # Node related hierarchy
        #TODO : Compaptibility with KIM service_provider_name (with function getName) !
        # Variables used more than once

        my $collector_indicator_id  = $collector_indicator->id;

        my @dependent_clustermetric = Entity::Metric::Clustermetric->search(
                                          hash => {
                                              clustermetric_indicator_id => $collector_indicator_id,
                                          }
                                      );

        for my $clustermetric (@dependent_clustermetric){
            #TODO general getName() to be compaptible with KIM
            my $service_provider_name = $clustermetric->clustermetric_service_provider->externalcluster_name;
            $dependencies{$service_provider_name}->{'service scope'}
                                                 ->{$clustermetric->clustermetric_label} = $clustermetric->getDependencies;
        }

        # Service related hierarchy
        my @combs = Entity::Metric::Combination::NodemetricCombination->search(hash => {});
        NODEMETRIC_COMBINATION:
        for my $nm_combi (@combs) {
            #TODO general getName() to be compaptible with KIM
            my $service_provider_name = $nm_combi->service_provider->externalcluster_name;
            my @collector_indicator_ids = $nm_combi->getDependentCollectorIndicatorIds();
            for my $nm_indicator_id (@collector_indicator_ids) {
                if ($collector_indicator_id == $nm_indicator_id) {
                    $dependencies{$service_provider_name}->{'node scope'}
                        ->{$nm_combi->nodemetric_combination_label} = $nm_combi->getDependencies;
                    next NODEMETRIC_COMBINATION;
                }
            }
        }
    }
    return \%dependencies;
}



sub delete {
    my $self = shift;


    my @related_collector_indicators = $self->collector_indicators;

    # Service
    while (@related_collector_indicators) {
        my $collector_indicator = pop @related_collector_indicators;

        # Node related hierarchy
        # Variables used more than once

        $log->debug("start processing ".$collector_indicator->id);

        my @dependent_clustermetric = $collector_indicator->clustermetrics;

        while (@dependent_clustermetric){
            (pop @dependent_clustermetric)->delete();
        }

        # Service related hierarchy
        $log->info("Entering nodemetric loop");

        my @combs = Entity::Metric::Combination::NodemetricCombination->search();
        NODEMETRIC_COMBINATION:
        while (@combs) {
            my $nm_combi  = pop @combs;
            my @collector_indicator_ids = $nm_combi->getDependentCollectorIndicatorIds();
            for my $nm_indicator_id (@collector_indicator_ids) {
                $log->debug($collector_indicator->id.' vs '.$nm_indicator_id);
                if ($collector_indicator->id == $nm_indicator_id) {
                    $nm_combi->delete();
                    next NODEMETRIC_COMBINATION;
                }
            }
        }

        my @service_provider_managers = $collector_indicator->collector_manager->service_provider_managers;
        for my $spm (@service_provider_managers) {
            my @nodes = $spm->service_provider->nodes;
            for my $node (@nodes) {
                my $rrd_name = $self->id.'_'.$node->node_hostname;
                $log->info('delete '.$rrd_name);
                TimeData::RRDTimeData::deleteTimeDataStore(name => $rrd_name);
            }
        }

        $collector_indicator->delete();
    }
    return $self->SUPER::delete();
}

1;
