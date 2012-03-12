use lib qw(/opt/kanopya/lib/administrator /opt/kanopya/lib/monitor /opt/kanopya/lib/orchestrator /opt/kanopya/lib/common);

use Log::Log4perl;
Log::Log4perl->init('/opt/kanopya/conf/orchestrator-log.conf');

use Entity::ServiceProvider::Inside::Cluster;
use Actuator;
use Administrator;
Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );


my $cluster_name = 'Kanopya';

my $actuator = Actuator->new();

my $cluster = Entity::ServiceProvider::Inside::Cluster->getCluster(hash => {'cluster_name' => $cluster_name});

print "CLUSTER $cluster_name: $cluster\n";

$actuator->changeClusterConf(
    current_conf => { nb_nodes => 2},
    target_conf => { nb_nodes => 1},
    cluster => $cluster
);

