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
sub getHostAndIndicatorHash {
    my @aggregates = Aggregate->search(hash => {});
    
    my $aggregate_cluster_id   = 0;
    my $aggregate_indicator_id = 0;
    
    my $cluster              = undef;
    my $hosts                = undef;
    my $rep                  = undef;
    my $host_id              = undef;
    
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

=head2 computeAggregates
    
    Class : Public
    
    Desc : Compute all the aggregates according to the retrieved values received from Retriever
    
=cut

 
sub computeAggregates{
    my $self = shift;
    my %args = @_;

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

sub update() {
    print "launched !\n";
    $log->info("launched !");
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

1;
