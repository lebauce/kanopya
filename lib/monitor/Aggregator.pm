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
use Entity::ServiceProvider::Inside::Cluster;
use XML::Simple;
use Entity::ServiceProvider::Outside::Scom;
use Indicator;
use TimeData::RRDTimeData;
use Aggregate;
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

=head2 getHostAndIndicatorHash
    
    Class : Public
    
    Desc : Generate hash table of hosts to monitor and the indicator id to the Retriever
    
=cut
sub _getHostAndIndicatorHash {
    my $self = shift;
    my @aggregates = Aggregate->search(hash => {});
    
    my $aggregate_cluster_id   = 0;
    my $aggregate_indicator_id = 0;
    
    my $cluster                = undef;
    my $hosts                  = undef;
    my $rep                    = undef;
    my $host_id                = undef;
    
    for my $aggregate (@aggregates){
        $aggregate_cluster_id   = $aggregate->getAttr(name => 'cluster_id');
        $aggregate_indicator_id = $aggregate->getAttr(name => 'indicator_id');
        
        $cluster = Entity::ServiceProvider::Inside::Cluster->get('id' => $aggregate_cluster_id);
        $hosts = $cluster->getHosts();
        
        for my $host (values(%$hosts)){
            $host_id = $host->getAttr(name => 'host_id');
                        
            push(
                @{$rep->{$host_id}->{$aggregate_indicator_id}},
                $aggregate->getAttr(name => 'window_time')
            );
        }
    }
    return $rep;
};


=head2 getHostAndIndicatorHash
    
    Class : Public
    
    Desc : Generate hash table of hosts to monitor and the indicator id to the Retriever
    
=cut
sub _contructRetrieverOutput {
    my $self = shift;
    my @aggregates = Aggregate->search(hash => {});
    
    my $aggregate_cluster_id   = 0;
    my $aggregate_indicator_id = 0;
    
    my $cluster                = undef;
    my $hosts                  = undef;
    my $rep                    = undef;
    my $host_id                = undef;
    my $indicator              = undef; 
    my $indicators_name             = undef;
    my @indicators_array       = undef;
    my $aggregate_time_span    = undef;
    my $time_span              = undef;
    # HARCODE hosts name
    my $hosts_names = $self->_getHostNamesFromIDs();
    $rep->{nodes} = $hosts_names;
    
    
    for my $aggregate (@aggregates){
        $aggregate_indicator_id = $aggregate->getAttr(name => 'indicator_id');
        $aggregate_time_span = $aggregate->getAttr(name => 'window_time');
        
        $indicator = Indicator->get('id' => $aggregate_indicator_id);
        
        $indicators_name->{$indicator->getAttr(name=>'indicator_oid')} = undef;
        
        
        if(! defined $time_span)
        {
            $time_span = $aggregate_time_span
        } else
        {
            if($time_span != $aggregate_time_span)
            {
                $log->info("WARNING !!! ALL TIME SPAN MUST BE EQUALS IN FIRST VERSION");
                print("WARNING !!! ALL TIME SPAN MUST BE EQUALS IN FIRST VERSION ($time_span vs $aggregate_time_span)\n");
            }
        }
        $time_span = ($aggregate_time_span > $time_span)?$aggregate_time_span:$time_span;
        
    }
    @indicators_array = keys(%$indicators_name);
    $rep->{indicators} = \@indicators_array;
    $rep->{time_span}  = $time_span;
    return $rep;
};

sub _getHostNamesFromIDs{
    return ['WKANOPYA.hedera.forest', 'WIN-09DSUKS61DT.hedera.forest'];
}




sub update() {
    my $self = shift;
    
    # Construct input of the SCOM retriever
    my $host_indicator_for_retriever = $self->_contructRetrieverOutput();
    print Dumper $host_indicator_for_retriever;
    
    # Call the retriever to get SCOM data
    my $monitored_values = Entity::ServiceProvider::Outside::Scom->retrieveData(%$host_indicator_for_retriever);
    print Dumper $monitored_values; 
    
    # Parse retriever return, compute aggregate values and store in DB 
    $self->_calculateAggregateValuesAndUpdateTimeDB(values=>$monitored_values);
    
    print Dumper $monitored_values;
}


=head2 run
    
    Class : Public
    
    Desc : Parse the hash table received from Retriever (input), compute 
    aggregate values and store them in DB
    
    Args : values : hash table from the Retriever
=cut

sub _calculateAggregateValuesAndUpdateTimeDB{
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['values']);
    my $values = $args{values};
    # Array of all aggregates
    my @aggregates = Aggregate->search(hash => {});
    
    my $aggregate_indicator_id;
    my $indicator;
    my $indicators_name; 
    
    # Loop on all the aggregates
    for my $aggregate (@aggregates){
        
        my $host_names = $self->_getHostNamesFromIDs(); #get all hosts name
        #TODO : To be modified when using ServerSets
        
        # Array that will store all the values needed to compute $aggregate val
        my @dataStored = (); 

        # Loop on all the host_name of the $aggregate
        for my $host_name (@$host_names){
            
            $aggregate_indicator_id = $aggregate->getAttr(name => 'indicator_id');
            $indicator = Indicator->get('id' => $aggregate_indicator_id);

            # Parse $values to store needed value in @dataStored 
            my $the_value = $values->{$host_name}
                                   ->{$indicator->getAttr(name=>'indicator_oid')};
            push(@dataStored,$the_value); 
        }
        
        #Compute the $aggregate value from all @dataStored values
        my $statValue = $aggregate->calculate(values => \@dataStored);
        
        #Store in DB and time stamp
        my $time = time();
        RRDTimeData::updateTimeDataStore(
            aggregator_id => $aggregate->getAttr(name=>'aggregate_id'), 
            time          => $time, 
            value         => $statValue,
            );
        
    }
}


=head2 run
    
    Class : Public
    
    Desc : Retrieve indicator values for all the aggregates, compute the 
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

=head2 run
    
    Class : Public
    
    Desc : Recreate all the DB for all the existing aggregate
    
=cut

sub create_aggregates_db{
    my $self = shift;
    my @aggregates = Aggregate->search(hash => {});
    for my $aggregate (@aggregates){
        my $aggregate_id = $aggregate->getAttr(name=>'aggregate_id');
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
    }
}


=head2 computeAggregates
    
    Class : Public
    
    Desc : [DEPRECTATED] Compute all the aggregates according to the retrieved values received from Retriever
    
=cut

 
sub _computeAggregates{
    my $self = shift;
    my %args = @_;

    print "THIS METHOD SEEMS DEPRECATED, please use _calculateAggregateValuesAndUpdateTimeDB";
    $log->info("THIS METHOD SEEMS DEPRECATED, please use _calculateAggregateValuesAndUpdateTimeDB"); 
    General::checkParams(args => \%args, required => ['indicators']);
    my $indicators = $args{indicators};
    my $rep = {};
    my $aggregate_cluster_id   = 0;
    my $aggregate_indicator_id = 0;
    my $cluster                = undef;
    my $hosts                  = undef;
    my $host_id                = undef;
    my $indicator_value        = undef;
    my @values                 = ();

    # Array to loop on all the aggregates
    my @aggregates = Aggregate->search(hash => {});
    for my $aggregate (@aggregates){
        
        @values = ();
        
        
        $aggregate_cluster_id   = $aggregate->getAttr(name => 'cluster_id');
        $aggregate_indicator_id = $aggregate->getAttr(name => 'indicator_id');
        $cluster = Entity::ServiceProvider::Inside::Cluster->get('id' => $aggregate_cluster_id);
        $hosts   = $cluster->getHosts();
        
        for my $host (values(%$hosts)){
            $host_id = $host->getAttr(name => 'host_id');
            $indicator_value = $indicators->{$host_id}->{$aggregate_indicator_id};
            
            push(@values,$indicator_value);
        }
        $rep->{$aggregate->getAttr(name => 'aggregate_id')} = $aggregate->calculate(values => \@values);
    }
    return $rep;
};
1;
