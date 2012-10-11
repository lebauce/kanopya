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
package Aggregator;

use base 'BaseDB';

use strict;
use warnings;
use General;
use Data::Dumper;
use XML::Simple;
use Entity::ServiceProvider;
use Indicator;
use TimeData::RRDTimeData;
use Clustermetric;
use Kanopya::Config;
use Message;

use Log::Log4perl "get_logger";
my $log = get_logger("");

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

# Constructor
sub new {
    my $class = shift;
    my %args = @_;
    my $self = {};
    bless $self, $class;

    # Get Administrator
    my $conf               = getAggregatorConf();
    my ($login, $password) = ($conf->{user_name}, $conf->{user_password});
    Administrator::authenticate( login => $login, password => $password );
    $self->{_admin} = Administrator->new();

    return $self;
};

=head2 _contructRetrieverOutput

    Desc : This function build the variable to be given to a Data Collector
    args: cluster_id,
    return : \%rep (containing the indicator list and the timespan requested)

=cut

sub _contructRetrieverOutput {
    my $self = shift;
    my %args = @_;

    my $indicators = { };
    my $time_span = 0;

    my $service_provider = Entity::ServiceProvider->get(id => $args{service_provider_id});
    my @clustermetrics = $service_provider->clustermetrics;

    for my $clustermetric (@clustermetrics) {
        my $clustermetric_time_span = $clustermetric->clustermetric_window_time;
        my $indicator = $clustermetric->getIndicator();
        $indicators->{$indicator->indicator_oid} = $indicator;
        if (! defined $time_span) {
            $time_span = $clustermetric_time_span;
        } else {
            if ($time_span != $clustermetric_time_span) {
                #$log->info("WARNING !!! ALL TIME SPAN MUST BE EQUALS IN FIRST VERSION");
            }
        }

        $time_span = ($clustermetric_time_span > $time_span) ?
                         $clustermetric_time_span : $time_span;
    }

    return {
        indicators => $indicators,
        time_span  => $time_span
    };
};

=head2 update

    Desc : This function containt the main aggregator loop. For every service
           provider that has a collector manager,  it build a valid input,
           retrieve the data, check them, and then store them in a TimeDB after
           having compute the clustermetric combinations.
    args: service_provider_id,
    return : \%rep (containing the indicator list and the timespan requested)

=cut

sub update() {
    my $self = shift;

    my @service_providers = Entity::ServiceProvider->search(hash => { });

    CLUSTER:
    for my $service_provider (@service_providers) {
        eval {
            my $service_provider_id = $service_provider->id;

            eval {
                $service_provider->getManager(manager_type => "collector_manager");
            };

            if (not $@){
                $log->info('*** Aggregator collecting for service provider '. $service_provider_id.' ***');

                # Construct input of the collector retriever
                my $host_indicator_for_retriever = $self->_contructRetrieverOutput(
                                                       service_provider_id => $service_provider_id
                                                   );

                # Call the retriever to get monitoring data
                my $monitored_values = $service_provider->getNodesMetrics(
                                           indicators => $host_indicator_for_retriever->{indicators},
                                           time_span  => $host_indicator_for_retriever->{time_span}
                                       );

                # Verify answers received from SCOM to detect metrics anomalies
                my $checker = $self->_checkNodesMetrics(
                                  asked_indicators => $host_indicator_for_retriever->{indicators},
                                  received => $monitored_values
                              );

                # Parse retriever return, compute clustermetric values and store in DB
                if ($checker == 1) {
                    $self->_computeCombinationAndFeedTimeDB(
                        values     => $monitored_values,
                        cluster_id => $service_provider_id
                    );
                }
                1;
            }
        } or do {
            $log->error("An error occurred : " . $@);
            next CLUSTER;
        }
    }
}

sub _checkNodesMetrics{
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [
        'asked_indicators',
        'received',
    ]);

    my $asked_indicators = $args{asked_indicators};
    my $received         = $args{received};

    my $num_of_nodes     = scalar (keys %$received);

    foreach my $indicator (values %$asked_indicators) {
        while ( my ($node_name, $metrics) = each(%$received) ) {
            if (! defined $metrics->{$indicator->indicator_oid}) {
                $log->debug("Indicator " . $indicator->indicator_name . '(' . $indicator->indicator_oid . ')' .
                            " was not retrieved by collector for node $node_name");
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

    General::checkParams(args => \%args, required => ['values']);
    my $values     = $args{values};
    my $cluster_id = $args{cluster_id};

    my $service_provider = Entity::ServiceProvider->get('id' => $cluster_id);
    my @clustermetrics   = $service_provider->clustermetrics;

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

        # Compute the $clustermetric value from all @dataStored values
        if (0 < (scalar @dataStored)) {
            my $statValue = $clustermetric->compute(values => \@dataStored);

            if(defined $statValue){
                # Store in DB and time stamp
                RRDTimeData::updateTimeDataStore(
                    clustermetric_id => $clustermetric->getId,
                    time             => time(),
                    value            => $statValue,
                );
            } else {
                $log->info("*** [WARNING] No statvalue computed for clustermetric " . $clustermetric->getId);
            }
        } else {
            # This case is current and produce lot of log
            # TODO better handling (and user feedback) of missing data
            $log->debug("*** [WARNING] No datas received for clustermetric " . $clustermetric->getId);
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
