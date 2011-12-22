use lib qw(/opt/kanopya/lib/orchestrator /opt/kanopya/lib/common);

use Administrator;
use DecisionMaker::HostSelector;
use Log::Log4perl  qw(:easy);

#Log::Log4perl->init('/opt/kanopya/conf/orchestrator-log.conf');
Log::Log4perl->easy_init($DEBUG);

Administrator::authenticate(    login => 'admin', password => 'K4n0pY4');

my $host_id = DecisionMaker::HostSelector->getHost( 
    cluster_id => 1,
    type => ['phys','virt'],
    core => 16,
    ram => 4,
    cloud_cluster_id => 1
);


print "=====> HOSTID = $host_id\n";