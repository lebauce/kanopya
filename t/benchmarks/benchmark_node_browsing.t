#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan', 'no_diag';
use Test::Exception;
use Test::Pod;
use Data::Dumper;
use Kanopya::Database;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({ level=>'DEBUG', file=>'/tmp/benchmark_node_browsing.log', layout=>'%F %L %p %m%n' });
my $log = get_logger("");

lives_ok {
    use StateManager;
    use Entity::ServiceProvider::Cluster;
    use Entity::Poolip;
    use Ip;

} 'All uses';

use Kanopya::Tools::Execution;  
use Kanopya::Tools::Register;
use Kanopya::Tools::Retrieve;
use Kanopya::Tools::Create;
use Kanopya::Tools::Profiler;

my $profiler = Kanopya::Tools::Profiler->new(schema => Kanopya::Database::schema);


Kanopya::Database::beginTransaction;

my $serviceload = 1;
my $nodeload = 1;

my $kanopya = Entity::ServiceProvider::Cluster->find(hash => { cluster_name => 'Kanopya' });

my @hosts = $kanopya->getHosts();
my $adminiface = $hosts[0]->getAdminIface;

sub registerCluster {
    my ($self, %args) = @_;

    my $cluster = Kanopya::Tools::Create->createCluster(cluster_conf => {
                      cluster_name         => "Cluster" . $serviceload, 
                      cluster_basehostname => "default" . $serviceload
                  });

    addNode(cluster => $cluster, number => $nodeload);

    $serviceload++;
}

sub addNode {
    my (%args) = @_;

    # Register a host for the new service
    my $host = Kanopya::Tools::Register->registerHost(board => {
                   ram  => 1073741824,
                   core => 4,
               });

    # Make the host node for the new service
    $args{cluster}->registerNode(
        host     => $host,
        number   => $args{number},
        hostname => 'hostname' . $args{cluster}->cluster_name . 'node' . $args{number}
    );

    $host->setState(state => 'up');
    $host->setNodeState(state => 'in');

    # Add an iface with the same conf as the kanopya master node
    my $iface = $host->addIface(iface_name => 'eth0');

    my @netconfs = $adminiface->netconfs;
    my $poolip   = Entity::Poolip->new(poolip_name       => 'poolip_' . $args{cluster}->cluster_name . 'node' . $args{number},
                                       poolip_first_addr => '10.0.0.1',
                                       poolip_size       => 1,
                                       network_id        => $adminiface->getPoolip->network->id);

    $iface->populateRelations(relations => { netconf_ifaces => \@netconfs });
    my $ip = Ip->new(ip_addr => $adminiface->getIPAddr, poolip_id => $poolip->id);
    $ip->setAttr(name  => 'iface_id', value => $iface->id, save => 1);

}

sub browseNodes {
    my ($self, %args) = @_;

    $profiler->start(print_queries => 0);

    my @clusters = Entity::ServiceProvider::Cluster->search(hash => {});
    for my $cluster (@clusters) {
        $cluster->getHosts();
    }

    $profiler->stop();
}

sub browseNodesWithPrefetch {
    my ($self, %args) = @_;

    $profiler->start(print_queries => 0);

    my @clusters = Entity::ServiceProvider::Cluster->search(hash => {}, prefetch => [ 'nodes.host' ]);
    for my $cluster (@clusters) {
        $cluster->getHosts();
    }

    $profiler->stop();
}

sub benchmarkBrowseNodes {
    my ($self, %args) = @_;

    print "Benchmarking the browsing fo all nodes for $serviceload service, $nodeload nodes each :\n";
    print "Without prefetch :\n";
    browseNodes();

    print "With prefetch :\n";
    browseNodesWithPrefetch();
}

eval{
    # Firstly create simple one node services
    my $t;
    while ($serviceload <= 10) {
        benchmarkBrowseNodes();

        registerCluster();
    }

    while ($nodeload <= 100) {
        benchmarkBrowseNodes();

        # Add 10 nodes to each services
        for my $cluster (Entity::ServiceProvider::Cluster->search(hash => {})) {
            for my $index (1 .. 10) {
                addNode(cluster => $cluster, number => ($nodeload + $index));
            }
        }
        $nodeload += 10;
    }
    benchmarkBrowseNodes();

    Kanopya::Database::rollbackTransaction;
};
if ($@) {
    my $error = $@;
    print $error."\n";

    Kanopya::Database::rollbackTransaction;

    fail('Exception occurs');
}

1;
