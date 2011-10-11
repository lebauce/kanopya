use lib qw(/opt/kanopya/lib/administrator /opt/kanopya/lib/monitor /opt/kanopya/lib/orchestrator /opt/kanopya/lib/common);

#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init();
use Log::Log4perl "get_logger";
Log::Log4perl->init('/opt/kanopya/conf/orchestrator-log.conf');
my $log = get_logger("orchestrator");

use Controller;
use Data::Dumper;

my $controller = Controller->new();


my $workload = {
   workload_class => {
   		  visit_ratio => [1],
		  service_time => [0.1],
		  delay => [0.01],
		  think_time => 5, 
   },
   workload_amount => 100
};

my $cluster_conf = { 
   nb_nodes => 1,
   mpl => 1000,
};

my $curr_perf = {
   latency => 0.5,
   abort_rate => 0,
   throughput => 0,
};


my $best_params = $controller->modelTuning( workload => $workload, cluster_conf => $cluster_conf, curr_perf => $curr_perf );


print Dumper $best_params; 
    


