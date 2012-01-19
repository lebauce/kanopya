use lib qw(/opt/kanopya/lib/administrator /opt/kanopya/lib/monitor /opt/kanopya/lib/orchestrator /opt/kanopya/lib/common);
use Test::More 'no_plan';
use Test::Deep;
use Model::MVAModel;
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
              visit_ratio => [1,0.13],
              #service_time => [0.1],
              #delay => [0],
              think_time => 6.313
       },
       workload_amount => 226
    };
    
    my $algo_conf = {
        nb_steps            => 500,
        init_step_size      => 5,
        init_point_position => 1,
    };
    
    my $infra_conf = {       
        M        => 2,
        AC       => [1,1],
        LC       => [10000,10000], 
    };
    
    my $curr_perf = {
        latency    =>  0.00382,
        abort_rate => 0,
        throughput => 35.77,
    };
    
my $best_params = $controller->modelTuning( algo_conf => $algo_conf, workload => $workload, infra_conf => $infra_conf, curr_perf => $curr_perf );
print Dumper $best_params; 

$workload->{workload_class}->{service_time} = $best_params->{S};
$workload->{workload_class}->{delay}   = $best_params->{D};

my %verify = (
          'workload_amount' => $workload->{workload_amount},
          'workload_class' => $workload->{workload_class},
          'configuration' => $infra_conf
        );

print Dumper \%verify;


my $model = Model::MVAModel->new();
my %QoS = $model->calculate(%verify);
print Dumper \%QoS;

print "Waited values : \n";
print "latency = $curr_perf->{latency} \n";
print "throughput = $curr_perf->{throughput} \n";

$verify{workload_amount} = 2251;
#$verify{workload_class}{service_time}[0] *= 10;

print Dumper \%verify;
my %QoS = $model->calculate(%verify);
print Dumper \%QoS;

