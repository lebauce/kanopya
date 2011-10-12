use lib qw(/opt/kanopya/lib/administrator /opt/kanopya/lib/monitor /opt/kanopya/lib/orchestrator /opt/kanopya/lib/common);

use Test::More 'no_plan';
use Test::Exception;

use Log::Log4perl;
Log::Log4perl->init('/opt/kanopya/conf/orchestrator-log.conf');

BEGIN {
    use_ok ('Actuator'); 
}

my $actuator = Actuator->new();

# 1 tier infra
my $infra = [ { cluster => 1, conf => { nb_nodes => 3, mpl => 100 } } ];

dies_ok {
    $actuator->changeInfraConf(
        infra => $infra,
        target_conf => { AC => [2, 2], LC => [100, 100] },
    );
} 'Assert on not corresponding nb tiers';


