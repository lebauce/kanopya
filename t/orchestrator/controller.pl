use lib qw(/opt/kanopya/lib/administrator /opt/kanopya/lib/monitor /opt/kanopya/lib/orchestrator /opt/kanopya/lib/common);

#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init();
use Log::Log4perl "get_logger";
Log::Log4perl->init('/opt/kanopya/conf/orchestrator-log.conf');
my $log = get_logger("orchestrator");

use Controller;
use Entity::Cluster;
use Administrator;
use Data::Dumper;

Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
my $adm = Administrator->new();

eval{
    $adm->{db}->txn_begin;
    my $cluster = Entity::Cluster->new(cluster_name => "foobar", 
                 cluster_min_node => "1", 
                 cluster_max_node => "30", 
                 cluster_priority => "100", 
                 systemimage_id => "1",
                 cluster_nameserver => '127.0.0.1',
                 cluster_si_access_mode => 'ro',
                 cluster_si_location => 'diskless',
                 cluster_domainname => 'my.domain',
                 cluster_si_shared => '1',
                 );
    my $running = 1;
    
    
    my $controller = Controller->new();
    
    
     my $infra_conf   = {
             M        => 1,
             AC       => [2],
             LC       => [1000],
        };
            
    for $i (1..10)
    {
        my $workload   = getWorkloadHC($i); 
        print Dumper $workload;
        my $curr_perf  = getMonitoredPerfMetricsHC();
        print Dumper $curr_perf;
        
        my $optim_param = $controller->manageCluster( 
            cluster => $cluster, 
            workload => $workload, 
            curr_perf => $curr_perf, 
            infra_conf => $infra_conf 
            );
        print "a\n";    
        print Dumper $optim_param;
        print "b\n";
    }
    
    #$controller->run( \$running );
    
    
    
    $adm->{db}->txn_rollback;
};
if($@) {
       my $error = $@;
       print "$error";
       $adm->{db}->txn_rollback;
       
       exit 233;
}


sub getWorkloadHC
{   my $counter = shift;
    
    my $nb_tiers     = 1;
    my $visit_ratio  = [];
    my $delay        = [];
    my $service_time = [];
    my $think_time   = 5;
    
   
    my $workload_amount    = 1000 * (2**$counter);    
    print "[Test] Workload amount = $workload_amount\n";
    
    $counter++ if($counter < @workloads_tab - 1);
    
    for (0..$nb_tiers-1)
    {
        push(@$delay, 0.01);
        push(@$visit_ratio,1);
        push(@$service_time,0.02);
    }
    my $workload_class = { 
               visit_ratio  => $visit_ratio,
               service_time => undef, #Will be given by autotune algorithm
               delay        => undef, #Will be given by autotune algorithm
               think_time   => $think_time,
    };

    my $workload = {
         workload_class  => $workload_class,
         workload_amount => $workload_amount, 
    };
   return $workload;
}

sub getMonitoredPerfMetricsHC{
    my $curr_perf = {
      latency    => 0.01,
      abort_rate => 0.80,
      throughput => 40000,
    };
    return $curr_perf;
}