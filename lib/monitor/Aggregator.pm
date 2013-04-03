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

=pod
=begin classdoc

Main task of Aggregator is to compute and store cluster metrics
(i.e aggregation of indicator values for all nodes) at regular time.

Optionnaly, Aggregator can store indicator values for each individual nodes
for optimisation when we need intensive access to these data (graphing, analysis,...).
This option avoids frequent requests on the collector manager (monitoring tool relief),
accelerates data access, but needs more storage space.

For each service provider, Aggregator retrieves values for indicators used at both level:
- service level, i.e. in ClusterMetric
- node level, i.e in NodeMetricCombination
using the linked collector manager (which could be an external monitoring tool or the kanopya collector).
Then Aggregator will:
- check data (raising Alert if missing data)
- store values for each indicator for each nodes
- compute and store ClusterMetric

Aggregator uses RRDTimeData to store data at service level
and uses DataCache to (possibly) store data at node level.

@see <package>Entity::Combination::NodeMetricCombination</package>
@see <package>Entity::ClusterMetric</package>
@see <package>Entity::TimeData::RRDTimeData</package>
@see <package>Entity::Manager::CollectorManager</package>

=end classdoc
=cut

package Aggregator;
use base Daemon;

use strict;
use warnings;

use General;
use Data::Dumper;
use XML::Simple;
use Entity::ServiceProvider;
use Entity::Indicator;
use TimeData::RRDTimeData;
use Entity::Clustermetric;
use Kanopya::Config;
use Message;
use Alert;
use DataCache;

use Log::Log4perl "get_logger";
my $log = get_logger("");

use constant ATTR_DEF => {};

sub getAttrDef { return ATTR_DEF; }


=pod
=begin classdoc

Load aggregator configuration and do the BaseDB authentication.

@constructor

=end classdoc
=cut

sub new {
    my ($class, %args) = @_;

    General::checkParams(args => \%args, optional => { 'service_providers' => [] });

    my $self = $class->SUPER::new(confkey => 'aggregator');

    $self->{service_providers} = [];
    for my $service_provider_id (@{ $args{service_providers} }) {
        push @{ $self->{service_providers} }, Entity::ServiceProvider->get(id => $service_provider_id);
    }

    return $self;
}


=pod
=begin classdoc

Check the elapsed time of the main loop.

@constructor

=end classdoc
=cut

sub oneRun {
    my ($self) = @_;

    # Firstly check is configuration changed, and udpate time data is required
    if (defined $self->{last_time_step} and
        $self->{last_time_step} != $self->{config}->{time_step}) {
        $log->info("Configuration <time_step> has changed, regenerating time data stores.");

        $self->regenTimeDataStores();
    }
    if (defined $self->{last_storage_duration} and
        $self->{last_storage_duration} != $self->{config}->{storage_duration}) {
        $log->info("Configuration <storage_duration> has changed, resizing time data stores.");

        $self->resizeTimeDataStores(storage_duration     => $self->{config}->{storage_duration},
                                    old_storage_duration => $self->{last_storage_duration});
    }

    # Get the start time
    my $start_time = time();

    # Update metrics
    $self->update();

    # Get the end time
    my $update_duration = time() - $start_time;
    $log->info("Manage duration : $update_duration seconds");

    if ($update_duration > $self->{config}->{time_step}) {
        $log->warn("Aggregator duration > aggregator time step ($self->{config}->{time_step})");
    }
    else {
        sleep($self->{config}->{time_step} - $update_duration);
    }

    $self->{last_time_step}        = $self->{config}->{time_step};
    $self->{last_storage_duration} = $self->{config}->{storage_duration};
}


=pod
=begin classdoc

Build the list of Indicators used by a service provider.
Indicators can be used by ClusterMetric and by NodeMetricCombination linked to the service provider

@param service_provider The manipulated service provider
@optional include_nodemetric Include Indicators used by NodeMetricCombination.
    Default is only Indicators used by ClusterMetrics

@return An hash ref with 2 keys:
    'indicators': map indicator_oid with indicator instance
    'time_span' : max time_span used by clustermetrics

=end classdoc
=cut

sub _getUsedIndicators {
    my ($self, %args) = @_;

    my $indicators = { };
    my $time_span  = 0;

    # Get indicators used by node metric combinations
    if ($args{include_nodemetric}) {
        my @nmc = Entity::Combination::NodemetricCombination->search(
                      hash => {service_provider_id => $args{service_provider}->id},
                  );

        for my $nodemetriccombination (@nmc) {
            for my $indicator_id ($nodemetriccombination->getDependentIndicatorIds()) {
                my $indicator = Entity::Indicator->get(id => $indicator_id);
                $indicators->{$indicator->indicator_oid} = $indicator;
            }
        }
    }

    my $collector_indicators;
    # Get indicators used by cluster metrics

    my @cms = $args{service_provider}->searchRelated(hash     => {},
                                                     filters  => [ 'clustermetrics' ],
                                                     prefetch => [ 'clustermetric_indicator.indicator' ]);

    for my $clustermetric (@cms) {
        my $clustermetric_time_span = $clustermetric->clustermetric_window_time;

        my $indicator = $clustermetric->clustermetric_indicator;
        $collector_indicators->{$indicator->id} = $indicator;
        if (! defined $time_span) {
            $time_span = $clustermetric_time_span;
        }
        elsif ($time_span != $clustermetric_time_span) {
                #$log->info("WARNING !!! ALL TIME SPAN MUST BE EQUALS IN FIRST VERSION");
        }

        $time_span = ($clustermetric_time_span > $time_span) ? $clustermetric_time_span : $time_span;
    }

    for my $collector_indicator (values %{$collector_indicators}) {
         my $indicator = $collector_indicator->indicator;
         $indicators->{$indicator->indicator_oid} = $indicator;
    }

    return {
        indicators => $indicators,
        time_span  => $time_span
    };
};


=pod
=begin classdoc

Main aggregator loop. For every service provider that has a collector manager, get required Indicators,
retrieves the data for all nodes, check them, and then store them in a TimeDB
after having computed the clustermetric combinations.

=end classdoc
=cut

sub update {
    my $self = shift;

    my @service_providers;
    if (scalar @{ $self->{service_providers} }) {
        @service_providers = @{ $self->{service_providers} };
    }
    else {
        @service_providers = Entity::ServiceProvider->search(hash => {
                                 service_provider_type_id => { not => undef }
                             });
    }

    CLUSTER:
    for my $service_provider (@service_providers) {
        eval {
            eval {
                $service_provider->getManager(manager_type => "CollectorManager");
            };
            if (not $@){
                next CLUSTER if ( 0 == $service_provider->nodes);
                $log->info('Aggregator collecting for service provider '.  $service_provider->id);

                # Get all indicators used by the service
                my $wanted_indicators = $self->_getUsedIndicators(
                                            service_provider     => $service_provider,
                                            include_nodemetric   => 1
                                        );

                # Call the retriever to get monitoring data
                my $timestamp = time();
                my $monitored_values = $service_provider->getNodesMetrics(
                                           indicators => $wanted_indicators->{indicators},
                                           time_span  => $wanted_indicators->{time_span}
                                       );

                # Verify answers received from collector manager to detect metrics anomalies
                my $checker = $self->_checkNodesMetrics(
                                  service_provider_id => $service_provider->id,
                                  asked_indicators    => $wanted_indicators->{indicators},
                                  received            => $monitored_values
                              );

                # Nodes metrics values cache
                DataCache::storeNodeMetricsValues(
                    indicators       => $wanted_indicators->{indicators},
                    values           => $monitored_values,
                    timestamp        => $timestamp,
                    time_step        => $self->{config}->{time_step},
                    storage_duration => $self->{config}->{storage_duration}
                );

                # Parse retriever return, compute clustermetric values and store in DB
                if ($checker == 1) {
                    $self->_computeCombinationAndFeedTimeDB(
                        values           => $monitored_values,
                        timestamp        => $timestamp,
                        service_provider => $service_provider
                    );
                }
                1;
            }
        };
        if ($@) {
            $log->error("An error occurred : " . $@);
            next CLUSTER;
        }
    }
}

sub _checkNodesMetrics {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ 'asked_indicators', 'received', 'service_provider_id' ]);

    my $asked_indicators    = $args{asked_indicators};
    my $received            = $args{received};

    foreach my $indicator (values %$asked_indicators) {
        while (my ($node_name, $metrics) = each(%$received)) {
            my $msg = "Indicator " . $indicator->indicator_name . " (" . $indicator->indicator_oid . ") " .
                      "was not retrieved from collector for node $node_name";

            if (! defined $metrics->{$indicator->indicator_oid}) {
                Alert->throw(trigger_entity => $indicator,
                             alert_message  => $msg,
                             entity_id      => $args{service_provider_id});

            }
            else {
                Alert->resolve(trigger_entity => $indicator,
                               alert_message  => $msg,
                               entity_id      => $args{service_provider_id});
            }
        }
    }
    return 1;
}


=pod
=begin classdoc

Parse the hash table received from Retriever (input), compute clustermetric
values and store them in DB.

=end classdoc
=cut

sub _computeCombinationAndFeedTimeDB {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['values', 'timestamp']);

    my $values = $args{values};
    my @clustermetrics = $args{service_provider}->clustermetrics;

    # Loop on all the clustermetrics
    for my $clustermetric (@clustermetrics) {
        my $indicator_oid = $clustermetric->getIndicator()->indicator_oid;
        # Array that will store all the values needed to compute $clustermetric val
        my @dataStored = ();

        # Loop on all the host_name of the $clustermetric
        for my $host_name (keys %$values) {
            #if indicator value is undef, do not store it in the array
            if (defined $values->{$host_name}->{$indicator_oid}) {
                push @dataStored, $values->{$host_name}->{$indicator_oid};
            } else {
                $log->debug("Missing Value of indicator $indicator_oid for host $host_name");
            }
        }

        my $clustermetric_id = $clustermetric->id;
        # Compute the $clustermetric value from all @dataStored values
        if (0 < (scalar @dataStored)) {
            my $statValue = $clustermetric->compute(values => \@dataStored);

            # Store in DB and time stamp
            RRDTimeData::updateTimeDataStore(
                clustermetric_id => $clustermetric_id,
                time             => $args{timestamp},
                value            => $statValue,
                time_step        => $self->{config}->{time_step},
                storage_duration => $self->{config}->{storage_duration}
            );
            if (!defined $statValue) {
                $log->info("*** [WARNING] No statvalue computed for clustermetric " . $clustermetric_id);
            }
        }
        else {
            # This case is current and produce lot of log
            # TODO better handling (and user feedback) of missing data
            $log->debug("*** [WARNING] No datas received for clustermetric " . $clustermetric_id);

            RRDTimeData::updateTimeDataStore(
                clustermetric_id => $clustermetric_id,
                time             => $args{timestamp},
                value            => undef,
                time_step        => $self->{config}->{time_step},
                storage_duration => $self->{config}->{storage_duration}
            );
        }
    }
}


=pod

=begin classdoc

Delete and create again every time data store for the clustermetrics

=end classdoc

=cut

sub regenTimeDataStores {
    my $self = shift;
    my %args = @_;

    foreach my $clustermetric (Entity::Clustermetric->search()) {
        #delete previous rrd
        RRDTimeData::deleteTimeDataStore(name => $clustermetric->clustermetric_id);
        #create new rrd
        RRDTimeData::createTimeDataStore(name              => $clustermetric->clustermetric_id,
                                         collect_frequency => $self->{config}->{time_step},
                                         storage_duration  => $self->{config}->{storage_duration});
    }
}


=pod

=begin classdoc

Resize every time data store for the clustermetrics

@param storage_duration

=end classdoc

=cut

sub resizeTimeDataStores {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'storage_duration', 'old_storage_duration' ]);

    foreach my $clustermetric (Entity::Clustermetric->search()) {
        RRDTimeData::resizeTimeDataStore(clustermetric_id     => $clustermetric->clustermetric_id,
                                         storage_duration     => $args{storage_duration},
                                         old_storage_duration => $args{old_storage_duration},
                                         collect_frequency    => $self->{config}->{time_step});
    }
}

1;
