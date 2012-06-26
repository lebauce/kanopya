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

use strict;
use warnings;
use General;
use Data::Dumper;
use BaseDB;
use XML::Simple;
use Entity::ServiceProvider;
use Indicator;
use TimeData::RRDTimeData;
use Clustermetric;

use Log::Log4perl "get_logger";
my $log = get_logger("aggregator");

# Constructor

sub new {
    my $class = shift;
    my %args = @_;
    my $self = {};
    bless $self, $class;

    # Load conf
    my $conf = XMLin("/opt/kanopya/conf/monitor.conf");
    $self->{_time_step} = $conf->{time_step};

    # Get Administrator
    my ($login, $password) = ($conf->{user}{name}, $conf->{user}{password});
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
    my $time_span;

    my $service_provider = Entity::ServiceProvider->get(id => $args{service_provider_id});
    my @clustermetrics = $service_provider->clustermetrics;
    my $collector = $service_provider->getManager(manager_type => "collector_manager");

    for my $clustermetric (@clustermetrics) {
        my $clustermetric_indicator = $collector->getIndicator(id => $clustermetric->clustermetric_indicator_id);
        my $clustermetric_time_span = $clustermetric->clustermetric_window_time;
        my $indicator_oid           = $clustermetric_indicator->indicator_oid;

        $indicators->{$indicator_oid} = $clustermetric_indicator;

        if (! defined $time_span) {
            $time_span = $clustermetric_time_span
        } else {
            if ($time_span != $clustermetric_time_span) {
                $log->info("WARNING !!! ALL TIME SPAN MUST BE EQUALS IN FIRST VERSION");
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
            my $service_provider_id = $service_provider->getAttr(name => 'service_provider_id');

            eval {
                $service_provider->getManager(manager_type => "collector_manager");
            };

            if (not $@){
                $log->info('*** Aggregator collecting for service provider '. $service_provider_id.' ***');

                # Construct input of the collector retriever
                $DB::single = 1;
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
            if (! defined $metrics->{$indicator->indicator_name}) {
                $log->debug("Indicator " . $indicator->indicator_name .
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
    my @clustermetrics = $service_provider->clustermetrics;
    my $collector = $service_provider->getManager(manager_type => "collector_manager");

    my $clustermetric_indicator;
    my $indicator_oid;

    # Loop on all the clustermetrics
    for my $clustermetric (@clustermetrics) {

        # Array that will store all the values needed to compute $clustermetric val
        my @dataStored = (); 

        # Loop on all the host_name of the $clustermetric
        for my $host_name (keys %$values) {
            $clustermetric_indicator = $collector->getIndicator(id => $clustermetric->clustermetric_indicator_id);
            $indicator_oid = $clustermetric_indicator->indicator_oid;

            # If indicator value is undef, do not store it in the array
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
             $log->info("*** [WARNING] No datas received for clustermetric " . $clustermetric->getId);
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

    $self->{_admin}->addMessage(from    => 'Aggregator', 
                                level   => 'info', 
                                content => "Kanopya Aggregator started."
    );

    while ($$running) {
        my $start_time = time();
        $self->update();
        my $update_duration = time() - $start_time;
        $log->info( "Manage duration : $update_duration seconds" );

        if ($update_duration > $self->{_time_step}) {
            $log->warn("aggregator duration > aggregator time step (conf)");
        } else {
            sleep($self->{_time_step} - $update_duration);
        }
    }

    $self->{_admin}->addMessage(
        from    => 'Aggregator', 
        level   => 'warning', 
        content => "Kanopya Aggregator stopped"
    );
}

1;
