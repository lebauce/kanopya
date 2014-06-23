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

* service level, i.e. in Clustermetric
* node level, i.e in NodemetricCombination

using the linked collector manager (which could be an external monitoring tool or the kanopya collector).

Then Aggregator will:

1. check data (raising Alert if missing data)
2. store values for each indicator for each nodes
3. compute and store ClusterMetric

@see <package>Entity::Metric::Combination::NodemetricCombination</package>
@see <package>Entity::Metric::Clustermetric</package>
@see <package>Manager::CollectorManager</package>

=end classdoc
=cut

package Aggregator;
use base Daemon;

use strict;
use warnings;

use General;
use Data::Dumper;
use XML::Simple;
use Clone qw(clone);
use Entity::ServiceProvider;
use Entity::Indicator;
use Entity::Metric::Combination::NodemetricCombination;
use Entity::Metric::Clustermetric;
use Entity::Metric::Nodemetric;
use Entity::Indicator;
use Node;
use Kanopya::Config;
use Message;
use Alert;

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

=end classdoc
=cut

sub oneRun {
    my ($self) = @_;

    # Get the start time
    my $start_time = time();

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
        my @nmc = Entity::Metric::Combination::NodemetricCombination->search(
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
            my $collector_manager = undef;
            eval {
                $collector_manager = $service_provider->getManager(manager_type => 'CollectorManager');
            };
            if (not $@){
                next CLUSTER if ( 0 == $service_provider->nodes);
                my $start,
                my $timeinfo = "duration: ";
                $log->info('Aggregator collecting for service provider '.  $service_provider->id);

                # Get all indicators used by the service
                $start = time();
                my $wanted_indicators = $self->_getUsedIndicators(
                                            service_provider     => $service_provider,
                                            include_nodemetric   => 1
                                        );
                $timeinfo .= "Retrieve Indicators: ".(time() - $start).", ";

                # Call the retriever to get monitoring data
                $start = time();
                my $timestamp = time();
                my $monitored_values = $service_provider->getNodesMetrics(
                                           indicators => $wanted_indicators->{indicators},
                                           time_span  => $wanted_indicators->{time_span}
                                       );
                $timeinfo .= "Request data: ".(time() - $start).", ";

                # Verify answers received from collector manager to detect metrics anomalies
                $start = time();
                my $checker = $self->_checkNodesMetrics(
                                  service_provider_id => $service_provider->id,
                                  asked_indicators    => $wanted_indicators->{indicators},
                                  received            => $monitored_values
                              );
                $timeinfo .= "Anomalies detection: ".(time() - $start).", ";

                # Nodes metrics values cache
                $start = time();

                $self->_storeNodeMetricsValues(monitored_values  => $monitored_values,
                                               collector_manager => $collector_manager,
                                               timestamp         => $timestamp);


                $timeinfo .= "Nodes data storage: ".(time() - $start).", ";

                # Parse retriever return, compute clustermetric values and store in DB
                if ($checker == 1) {
                    $start = time();
                    $self->_computeCombinationAndFeedTimeDB(values           => $monitored_values,
                                                            timestamp        => $timestamp,
                                                            service_provider => $service_provider);

                    $timeinfo .= "Cluster metric compute: ".(time() - $start);
                }
                $log->info($timeinfo);
                1;
            }

        };
        if ($@) {
            $log->error("An error occurred : " . $@);
            next CLUSTER;
        }
    }
}


=pod
=begin classdoc

Store the node metric monitored data in local cache.

@param monitored_values hash table {node => oid => value} indicating the received monitoring value
@param timestamp timestamp indicating the update time
@param collector_manager collector manager instance

=end classdoc
=cut

sub _storeNodeMetricsValues {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'monitored_values', 'collector_manager', 'timestamp' ]);

    # Clone monitoring value to check nodemetrics
    my $nodes_oid = clone($args{monitored_values});
    while(my ($name,$hash_oid) = each (%$nodes_oid)) {
        for my $oid (keys %$hash_oid) {
            $hash_oid->{$oid} = undef;
        }
    }

    my @node_hostnames = keys %{ $args{monitored_values} };
    my @nodemetrics = Entity::Metric::Nodemetric->search(
                          hash => { 'nodemetric_node.node_hostname' => \@node_hostnames }
                      );

    for my $nodemetric (@nodemetrics) {
        eval {
            my $hostname = $nodemetric->nodemetric_node->node_hostname;
            my $indicator_oid = $nodemetric->nodemetric_indicator->indicator->indicator_oid;

            if (! exists $args{monitored_values} ->{$hostname}->{$indicator_oid}) {
                throw Kanopya::Exception::Internal::Inconsistency(
                          error => "No monitoring data found for node \"$hostname\" " .
                                   "and indicator \"$indicator_oid\""
                      );
            }

            $nodes_oid->{$hostname}->{$indicator_oid} = 1;
            $nodemetric->updateData(
                time             => $args{timestamp},
                value            => $args{monitored_values} ->{$hostname}->{$indicator_oid},
                time_step        => $self->{config}->{time_step},
                storage_duration => $self->{config}->{storage_duration}
            );
        };
        if ($@) {
            $log->warn($@);
        }
    }

    $self->_manageMissingNodemetrics(nodemetric_num => scalar @nodemetrics,
                                     nodes_oid => $nodes_oid,
                                     monitored_values => $args{monitored_values},
                                     timestamp => $args{timestamp},
                                     collector_manager => $args{collector_manager});
}



=pod
=begin classdoc

Check if all expected Nodemetrics instance exists w.r.t. received monitored values.
If a nodemetric instance is missing the method will create and update it.

@param nodemetric_num number of found nodemetrics
@param nodes_oid hash table { node => oid => 1 or undef} indicating of the corresponding
                 nodemetric has been found
@param monitored_values hash table {node => oid => value} indicating the received monitoring value
@param timestamp timestamp indicating the update time
@param collector_manager collector manager instance

=end classdoc
=cut

sub  _manageMissingNodemetrics {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'nodemetric_num', 'nodes_oid', 'monitored_values',
                                       'timestamp', 'collector_manager' ]);

    # Count total number of values received. Must be equal to total number of
    # nodemetric in DB.
    # If a nodemetric is missing, aggregator will create it in order to store the value

    my $exp_nm_num = 0;
    for my $name (keys %{ $args{nodes_oid} }) {
        $exp_nm_num += scalar keys %{$args{nodes_oid}->{$name}};
    }

    if ($exp_nm_num eq scalar $args{nodemetric_num}) {
        return;
    }

    while(my ($name,$hash_oid) = each (%{ $args{nodes_oid} })) {
        while(my ($oid,$v) = each (%$hash_oid)) {
            if (! defined $v) {

                my $node = Node->find(hash => {'node_hostname' => $name});

                my $indicator = Entity::Indicator->find(hash => { 'indicator_oid' => $oid });
                my $col_indicator = Entity::CollectorIndicator->find(hash => {
                                        indicator_id => $indicator->id,
                                        collector_manager_id => $args{collector_manager}->id
                                    });

                $log->debug('Nodemetric creation for <' . $name . '> < ' . $oid . '>');
                print('Nodemetric creation for <' . $name . '> < ' . $oid . '>' . "\n");
                my $nodemetric = Entity::Metric::Nodemetric->new(
                                     nodemetric_node_id => $node->id,
                                     nodemetric_indicator_id => $col_indicator->id,
                                 );

                $nodemetric->updateData(
                    time             => $args{timestamp},
                    value            => $args{monitored_values}->{$name}->{$oid},
                    time_step        => $self->{config}->{time_step},
                    storage_duration => $self->{config}->{storage_duration}
                );
            }
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

        eval {
            my $statValue = undef;

            # Compute the $clustermetric value from all @dataStored values
            if (0 < (scalar @dataStored)) {
                $statValue = $clustermetric->compute(values => \@dataStored);

                if (! defined $statValue) {
                    $log->info("No statvalue computed for clustermetric " . $clustermetric->id);
                }
            }
            else {
                # This case is current and produce lot of log
                # TODO better handling (and user feedback) of missing data
                $log->debug("No datas received for clustermetric " . $clustermetric->id);
            }

            $clustermetric->updateData(
                time             => $args{timestamp},
                value            => $statValue,
                time_step        => $self->{config}->{time_step},
                storage_duration => $self->{config}->{storage_duration}
            );

        };
        if ($@) {
            # Handle error when create rrd then directly update with a time < creation time
            $log->warn($@);
        }
    }
}


=pod

=begin classdoc

Delete and create again every time data store for the clustermetrics

=end classdoc

=cut

sub regenTimeDataStores {
    my ($self, %args) = @_;

    foreach my $clustermetric (Entity::Metric::Clustermetric->search()) {
        $clustermetric->resetData();
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

    foreach my $clustermetric (Entity::Metric::Clustermetric->search()) {
    }
}

1;
