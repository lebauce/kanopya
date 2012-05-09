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
# logger
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

# 


=head2 _contructRetrieverOutput

    Desc : This function build the variable to be given to a Data Collector
    args: cluster_id, 
    return : \%rep (containing the indicator list and the timespan requested)

=cut

sub _contructRetrieverOutput {
    my $self = shift;
    my %args = @_;


    #my @clustermetrics = Clustermetric->search(hash => {clustermetrics_clustermetrics_cluster_id => });

    my $service_provider_id                 = $args{service_provider_id};
    my $clustermetric_cluster_id   = 0;
    my $clustermetric_indicator_id = 0;
    
    my $cluster                = undef;
    my $hosts                  = undef;
    my $rep                    = undef;
    my $host_id                = undef;
    my $indicator              = undef; 
    my $indicators_name        = undef;
    my @indicators_array       = undef;
    my $clustermetric_time_span    = undef;
    my $time_span              = undef;




        my @clustermetrics = Clustermetric->search(
            hash => {
                clustermetric_service_provider_id => $service_provider_id
            }
        );

        for my $clustermetric (@clustermetrics){

            $clustermetric_indicator_id = $clustermetric->getAttr(name => 'clustermetric_indicator_id');
            $clustermetric_time_span    = $clustermetric->getAttr(name => 'clustermetric_window_time');

            $indicator = Indicator->get('id' => $clustermetric_indicator_id);

            $indicators_name->{$indicator->getAttr(name=>'indicator_oid')} = undef;


            if(! defined $time_span)
            {
                $time_span = $clustermetric_time_span
            } else
            {
                if($time_span != $clustermetric_time_span)
                {
                    $log->info("WARNING !!! ALL TIME SPAN MUST BE EQUALS IN FIRST VERSION");
                    print("WARNING !!! ALL TIME SPAN MUST BE EQUALS IN FIRST VERSION ($time_span != $clustermetric_time_span)\n");
                }
            }
            $time_span = ($clustermetric_time_span > $time_span)?$clustermetric_time_span:$time_span;

    }
    @indicators_array = keys(%$indicators_name);
    $rep->{indicators} = \@indicators_array;
    $rep->{time_span}  = $time_span;
    return $rep;
};

=head2 update

    Desc : This function containt the main aggregator loop. For every service provider that has a collector manager,  it build a valid input, retrieve the data, check them, and then store them in a TimeDB after having compute the clustermetric combinations.
    args: service_provider_id, 
    return : \%rep (containing the indicator list and the timespan requested)

=cut

sub update() {
    my $self = shift;

    my @service_providers = Entity::ServiceProvider->search(hash => {});

    CLUSTER:
    for my $service_provider (@service_providers){
        eval{
            my $service_provider_id = $service_provider->getAttr(name => 'service_provider_id');

            #FILTER CLUSTERS WITH MONITORING PROVIDER
            eval{
                $service_provider->getConnector(category => 'MonitoringService');
            };
            if($@){
                print '*** Aggregator skip service provider '.$service_provider_id.' because it has no MonitoringService Connector ***'."\n";
            }else{
                print '*** Aggregator collecting for service provider '.$service_provider_id.' ***'."\n";

                # Construct input of the SCOM retriever
                my $host_indicator_for_retriever = $self->_contructRetrieverOutput(service_provider_id => $service_provider_id );
                print Dumper $host_indicator_for_retriever;

                # Call the retriever to get SCOM data
                my $monitored_values = $service_provider->getNodesMetrics(%$host_indicator_for_retriever);
                print Dumper $monitored_values; 

                # Verify answers received from SCOM to detect metrics anomalies
                my $checker = $self->_checkNodesMetrics(asked_indicators=>$host_indicator_for_retriever->{indicators}, received=>$monitored_values);

                # Parse retriever return, compute clustermetric values and store in DB
                if($checker == 1){
                    $self->_computeCombinationAndFeedTimeDB(values=>$monitored_values, cluster_id => $service_provider_id);
                } 
            } #END EVAL
        1;
        } or do{
            print "Skip to next service provider due to error $@\n";
            $log->error($@);
            next CLUSTER;
        }
    } #end for $externalCluster
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
    
    foreach my $indicator_name (@$asked_indicators) {
        my $count = 0;
            while( my ($node_name,$metrics) = each(%$received) ) {
                if(defined $metrics->{$indicator_name}) {
                $count++;
            } else {
                $log->debug("Metric $indicator_name undefined from node $node_name");
            }
        }
        if($count eq 0){
            return 0;
            $log->info("*** [WARNING] $indicator_name given by no node !");
        } elsif(($count / $num_of_nodes) le 0.75) {
            $log->info("*** [WARNING] $indicator_name given by less than 75% of nodes ($count / $num_of_nodes)!");
            return 1;
        } else {
            return 1;
        }
    }
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

    # Array of all clustermetrics
    my @clustermetrics = Clustermetric->search(            hash => {
                clustermetric_service_provider_id => $cluster_id
            });

    my $clustermetric_indicator_id;
    my $indicator;
    my $indicators_name; 

    # Loop on all the clustermetrics
    for my $clustermetric (@clustermetrics){

        #TODO : To be modified when using ServerSets

        # Array that will store all the values needed to compute $clustermetric val
        my @dataStored = (); 

        # Loop on all the host_name of the $clustermetric

        for my $host_name (keys %$values){
            
            $clustermetric_indicator_id = $clustermetric->getAttr(name => 'clustermetric_indicator_id');
            $indicator = Indicator->get('id' => $clustermetric_indicator_id);

            # Parse $values to store needed value in @dataStored 
            my $the_value = $values->{$host_name}
                                   ->{$indicator->getAttr(name=>'indicator_oid')};
            if(defined $the_value){
                push(@dataStored,$the_value);
            }
            else {
                $log->debug("Missing Value of indicator ".($indicator->getAttr(name=>'indicator_oid'))." for host $host_name");
            }

        }

        #Compute the $clustermetric value from all @dataStored values
        if(0 < (scalar @dataStored)){
            my $statValue = $clustermetric->compute(values => \@dataStored);

            if(defined $statValue){
                #Store in DB and time stamp
                my $time = time();
                RRDTimeData::updateTimeDataStore(
                    clustermetric_id => $clustermetric->getAttr(name=>'clustermetric_id'), 
                    time          => $time, 
                    value         => $statValue,
                    );
            } else {

                $log->info("*** [WARNING] No statvalue computed for clustermetric ".($clustermetric->getAttr(name=>'clustermetric_id')));
            }
        } else {
             $log->info("*** [WARNING] No datas received for clustermetric ".($clustermetric->getAttr(name=>'clustermetric_id')));
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

    while ( $$running ) {

        my $start_time = time();

        $self->update();

        my $update_duration = time() - $start_time;
        $log->info( "Manage duration : $update_duration seconds" );
        if ( $update_duration > $self->{_time_step} ) {
            $log->warn("aggregator duration > aggregator time step (conf)");
        } else {
            sleep( $self->{_time_step} - $update_duration );
        }

    }

    $self->{_admin}->addMessage(
        from    => 'Aggregator', 
        level   => 'warning', 
        content => "Kanopya Aggregator stopped"
        );
}

#=head2 run
#    
#    Class : Public
#    
#    Desc : Recreate all the DB for all the existing clustermetric
#    
#=cut
#
#sub create_clustermetrics_db{
#    my $self = shift;
#    my @clustermetrics = Clustermetric->search(hash => {});
#    for my $clustermetric (@clustermetrics){
#        my $clustermetric_id = $clustermetric->getAttr(name=>'clustermetric_id');        
#        RRDTimeData::createTimeDataStore(name => $clustermetric_id);
#    }
#}


#=head2 computeAggregates
#    
#    Class : Public
#    
#    Desc : [DEPRECTATED] Compute all the clustermetrics according to the retrieved values received from Retriever
#    
#=cut
#
# 
#sub _computeAggregates{
#    my $self = shift;
#    my %args = @_;
#
#    print "THIS METHOD SEEMS DEPRECATED, please use _computeCombinationAndUpdateTimeDB";
#    $log->info("THIS METHOD SEEMS DEPRECATED, please use _computeCombinationAndUpdateTimeDB"); 
#    General::checkParams(args => \%args, required => ['indicators']);
#    my $indicators = $args{indicators};
#    my $rep = {};
#    my $clustermetric_cluster_id   = 0;
#    my $clustermetric_indicator_id = 0;
#    my $cluster                = undef;
#    my $hosts                  = undef;
#    my $host_id                = undef;
#    my $indicator_value        = undef;
#    my @values                 = ();
#
#    # Array to loop on all the clustermetrics
#    my @clustermetrics = Clustermetric->search(hash => {});
#    for my $clustermetric (@clustermetrics){
#        
#        @values = ();
#        
#        
#        $clustermetric_cluster_id   = $clustermetric->getAttr(name => 'clustermetric_service_provider_id');
#        $clustermetric_indicator_id = $clustermetric->getAttr(name => 'clustermetric_indicator_id');
#        $cluster = Entity::ServiceProvider::Inside::Cluster->get('id' => $clustermetric_cluster_id);
#        $hosts   = $cluster->getHosts();
#        
#        for my $host (values(%$hosts)){
#            $host_id = $host->getAttr(name => 'host_id');
#            $indicator_value = $indicators->{$host_id}->{$clustermetric_indicator_id};
#            
#            push(@values,$indicator_value);
#        }
#        $rep->{$clustermetric->getAttr(name => 'clustermetric_id')} = $clustermetric->compute(values => \@values);
#    }
#    return $rep;
#};

1;
