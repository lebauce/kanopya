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

Aggregator used RRDTimeData to store data and expose methods to retrieve stored data (service and node level)

@see <package>Entity::Combination::NodeMetricCombination</package>
@see <package>Entity::ClusterMetric</package>
@see <package>Entity::TimeData::RRDTimeData</package>
@see <package>Entity::Manager::CollectorManager</package>

=end classdoc

=cut

package Aggregator;

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

use Log::Log4perl "get_logger";
my $log = get_logger("");

# Flag to activate/deactivate nodes metrics values storage
# TODO conf by service provider or collector manager (?)
my $STORE_NODEMETRIC = 1;

use constant ATTR_DEF => {};

sub getAttrDef { return ATTR_DEF; }

sub getMethods {
  return {
    'updateAggregatorConf'  => {
      'description' => 'Update aggregator conf',
      'perm_holder' => 'entity'
    },
    'getAggregatorConf'  => {
      'description' => 'Get aggregator conf',
      'perm_holder' => 'entity'
    }
  }
}

=pod
=begin classdoc

Load aggregator configuration and do the BaseDB authentication.

@constructor

=end classdoc
=cut

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;

    my $conf = getAggregatorConf();

    my ($login, $password) = ($conf->{user_name}, $conf->{user_password});
    BaseDB->authenticate(login => $login, password => $password);

    return $self;
};

=pod
=begin classdoc

Build the list of Indicators used by a service provider.
Indicators can be used by ClusterMetric and by NodeMetricCombination linked to the service provider

@param service_provider The manipulated service provider
@optionnal include_nodemetric Include Indicators used by NodeMetricCombination.
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
                      hash => {service_provider_id => $args{service_provider}->id}
                  );
        for my $nodemetriccombination (@nmc) {
            for my $indicator_id ($nodemetriccombination->getDependentIndicatorIds()) {
                my $indicator = Entity::Indicator->get(id => $indicator_id);
                $indicators->{$indicator->indicator_oid} = $indicator;
            }
        }
    }

    # Get indicators used by cluster metrics
    for my $clustermetric ($args{service_provider}->clustermetrics) {
        my $clustermetric_time_span = $clustermetric->clustermetric_window_time;
        my $indicator = $clustermetric->getIndicator();
        $indicators->{$indicator->indicator_oid} = $indicator;

        if (! defined $time_span) {
            $time_span = $clustermetric_time_span;
        }
        elsif ($time_span != $clustermetric_time_span) {
                #$log->info("WARNING !!! ALL TIME SPAN MUST BE EQUALS IN FIRST VERSION");
        }

        $time_span = ($clustermetric_time_span > $time_span) ? $clustermetric_time_span : $time_span;
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

    my @service_providers = Entity::ServiceProvider->search(hash => { });

    CLUSTER:
    for my $service_provider (@service_providers) {
        eval {
            eval {
                $service_provider->getManager(manager_type => "CollectorManager");
            };
            if (not $@){
                next CLUSTER if (0 == $service_provider->nodes);

                $log->info('Aggregator collecting for service provider '.  $service_provider->id);

                # Get all indicators used by the service
                my $wanted_indicators = $self->_getUsedIndicators(
                                                       service_provider     => $service_provider,
                                                       include_nodemetric   => $STORE_NODEMETRIC
                                                   );

                # Call the retriever to get monitoring data
                my $timestamp        = time();
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

                # Store nodes metrics values
                if ($STORE_NODEMETRIC) {
                    $self->_storeNodeMetricsValues(
                        indicators          => $wanted_indicators->{indicators},
                        values              => $monitored_values,
                        timestamp           => $timestamp
                    );
                }

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

sub _storeNodeMetricsValues {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => ['indicators', 'values', 'timestamp']);

    while (my ($node_name, $indicators_values) = each %{$args{values}}) {
        while (my ($indicators_oid, $value) = each %$indicators_values) {
            my $metric_uid = $args{indicators}->{$indicators_oid}->id . '_' . $node_name;
            RRDTimeData::createTimeDataStore(name => $metric_uid, skip_if_exists => 1);
            RRDTimeData::updateTimeDataStore(
                clustermetric_id => $metric_uid,
                time             => $args{timestamp},
                value            => $value,
            );
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
    my $service_provider_id = $args{service_provider_id};

    foreach my $indicator (values %$asked_indicators) {
        while (my ($node_name, $metrics) = each(%$received)) {
            my $msg = "Indicator " . $indicator->indicator_name . "(" . $indicator->indicator_oid . ") " .
                      "was not retrieved by collector for node $node_name";

            my $alert;
            eval {
                $alert = Alert->find(hash => {
                             alert_message => $msg,
                             entity_id     => $service_provider_id
                         });
            };

            if (! defined $metrics->{$indicator->indicator_oid}) {
                $log->debug($msg);

                if ((! defined $alert) || ($alert->alert_active == 0) ) {
                    Alert->new(
                        entity_id       => $service_provider_id,
                        alert_message   => $msg,
                        alert_signature => $msg.' '.time()
                    );
                }
            }
            elsif (defined $alert && $alert->alert_active == 1) {
                $alert->mark_resolved;
            }
        }
    }

    return 1;
}

=head2 _computeCombinationAndFeedTimeDB

    Class : Public

    Desc : Parse the hash table received from Retriever (input), compute
    clustermetric values and store them in DB

    Args : values : hash table from the Retriever

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
            );
            if (!defined $statValue) {
                $log->info("*** [WARNING] No statvalue computed for clustermetric " . $clustermetric_id);
            }
        } else {
            # This case is current and produce lot of log
            # TODO better handling (and user feedback) of missing data
            $log->debug("*** [WARNING] No datas received for clustermetric " . $clustermetric_id);
            RRDTimeData::updateTimeDataStore(
                clustermetric_id => $clustermetric_id,
                time             => $args{timestamp},
                value            => undef,
            );
        }
    }
}


=head2 run

    Class : Public

    Desc : Retrieve indicator values for all the clustermetrics, compute the
    aggregation statistics function and store them in TimeDb
    every time_step (configuration)

=cut

sub run {
    my $self = shift;
    my $running = shift;

    Message->send(
        from    => 'Aggregator',
        level   => 'info',
        content => "Kanopya Aggregator started."
    );

    while ($$running) {
        my $start_time = time();
        $self->update();
        my $update_duration = time() - $start_time;
        $log->info( "Manage duration : $update_duration seconds" );

        my $conf      = getAggregatorConf();
        my $time_step = $conf->{time_step};

        if ($update_duration > $time_step) {
            $log->warn("aggregator duration > aggregator time step (conf)");
        } else {
            sleep($time_step - $update_duration);
        }
    }

    Message->send(
        from    => 'Aggregator',
        level   => 'warning',
        content => "Kanopya Aggregator stopped"
    );
}

=head2 updateAggregatorConf

    Class : Public
    Desc : update values in the aggregator.conf file
    Args: $collect_frequency and/or $storage_duration

=cut

sub updateAggregatorConf {
    my ($class, %args) = @_;

    if ((not defined $args{collect_frequency}) && (not defined $args{storage_duration})) {
        throw Kanopya::Exception::Internal(
            error => 'A collect frequency and/or a storage duration must be provided for update'
        );
    }

    #get aggregator configuration
    my $configuration = Kanopya::Config::get('aggregator');

    if (defined $args{collect_frequency}) {
        $configuration->{time_step} = $args{collect_frequency};
        Kanopya::Config::set(subsystem => 'aggregator', config => $configuration);
    }
    if (defined $args{storage_duration}) {
        $configuration->{storage_duration}->{duration} = $args{storage_duration};
        Kanopya::Config::set(subsystem => 'aggregator', config => $configuration);
    }
}

=head2 getAggregatorConf

    Class : Public
    Desc : get public values from aggregator.conf file

=cut

sub getAggregatorConf {
    my $conf = Kanopya::Config::get('aggregator');
    return {
        time_step           => $conf->{time_step},
        storage_duration    => $conf->{storage_duration}{duration},
        user_name           => $conf->{user}{name},
        user_password       => $conf->{user}{password},
    }
}

1;
