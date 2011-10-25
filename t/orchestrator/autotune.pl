use lib qw(/opt/kanopya/lib/administrator /opt/kanopya/lib/monitor /opt/kanopya/lib/orchestrator /opt/kanopya/lib/common);
use Test::More 'no_plan';
use Test::Deep;
#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init();
use Log::Log4perl "get_logger";
Log::Log4perl->init('/opt/kanopya/conf/orchestrator-log.conf');
my $log = get_logger("orchestrator");
 
use Controller;
use Data::Dumper;

my $controller = Controller->new();

{    
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
}
{
   my $workload = {
       workload_class => {
              visit_ratio => [1],
              service_time => [0.1],
              delay => [0],
              think_time => 5, 
       },
       workload_amount => 1000
    };
    
    my $cluster_conf = { 
       nb_nodes => 2,
       mpl      => 400,
    };
    
    my $curr_perf = {
       latency    => 44.3006,
       abort_rate => 0.71140224,
       throughput => 16226.98303874598,
    };

}

 
        
{
my $workload = {
       workload_class => {
              visit_ratio => [1,0.5],
              #service_time => [0.1],
              #delay => [0],
              think_time => 10, 
       },
       workload_amount => 100
    };
    
    my $algo_conf = {
        nb_steps            => 100,
        init_step_size      => 5,
        init_point_position => 1,
    };
    
    my $infra_conf = {       
        M        => 2,
        AC       => [1,1],
        LC       => [20,15], 
    };
    
    my $curr_perf = {
        latency    =>  0.029,
        abort_rate => 0.8004629,
        throughput => 1994.2167,
    };
    
    my $expected_params = {   
          S => [
                0.0234375,
                0.0111255645751953
               ],
          D => [
                0,
                1.0000011920929
               ]          
    };
}    
    
    
    my $workload = {
       workload_class => {
              visit_ratio => [1,1],
              #service_time => [0.1],
              #delay => [0],
              think_time => 5, 
       },
       workload_amount => 2000
    };
    
    my $algo_conf = {
        nb_steps            => 40,
        init_step_size      => 5,
        init_point_position => 1,
    };
    
    my $infra_conf = {       
        M        => 2,
        AC       => [2,2],
        LC       => [250,250], 
    };
    
    my $curr_perf = {
        latency    =>  0.01,
        abort_rate => 0.8,
        throughput => 40000,
    };
    
my $best_params = $controller->modelTuning( algo_conf => $algo_conf, workload => $workload, infra_conf => $infra_conf, curr_perf => $curr_perf );
print Dumper $best_params; 

my %verify = (
          'workload_amount' => 2000,
          'workload_class' => {
                                'visit_ratio' => [
                                                   1,1
                                                 ],
                                #'service_time' => $best_params->{S},
                                #'delay' => $best_params->{D},
                                                                'service_time' => [
                                                    '0.00390625',
                                                    '0.453125'
                                                  ],
                                'delay' => [
                                             '0',
                                             '4.0078125'
                                           ],
                                
                                'think_time' => 5
                              },
          'configuration' => $infra_conf
        );

print Dumper \%verify;
use Model::MVAModel;
my $model = Model::MVAModel->new();
my %QoS = $model->calculate(%verify);
use Data::Dumper;
print Dumper \%QoS;
