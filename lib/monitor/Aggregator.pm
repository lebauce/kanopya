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

sub new {
    my $class = shift;
    my %args = @_;
    my $self = {};
    bless $self, $class;
};

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
        #print "@values \n";
        $rep->{$aggregate->getAttr(name => 'aggregate_id')} = $aggregate->calculate(values => \@values);
    }
    return $rep;
};

1;
