use Test::More 'no_plan';
use Test::Deep;
use Log::Log4perl "get_logger";

Log::Log4perl->init('/opt/kanopya/conf/orchestrator-log.conf');

BEGIN {
    use_ok ('Model::MVAModel'); 
}
my $model = Model::MVAModel->new();

my $workload_amount = 1000;
my $nb_tiers = 5;
my %workload_class = ( visit_ratio => [1,0.8,8,0.3,6],
               service_time => [0.001,0.005,0.003,0.004,0.005],
               delay => [0,0.001,0.001,0.007,0.001],
               think_time => 7 );
my @AC = (3,2,5,4,1);
my @LC = (150,200,50,120,100);

my %QoS = $model->calculate(  
    configuration => { M => $nb_tiers, AC => \@AC, LC => \@LC},
    workload_class => \%workload_class,
    workload_amount => $workload_amount );
    

cmp_deeply(\%QoS,
{
          'throughput' => '48152.6722962806',
          'latency' => '0.060875',
          'abort_rate' => '0.66161849084335'
    
},'scenario 1 for MVAModel checked');

$workload_amount = 2000;
$nb_tiers = 2;
%workload_class = ( 
               visit_ratio => [1,0.5],
               service_time => [0.05,0.05],
               delay => [0,0.01],
               think_time => 5 );
@AC = (2,2);
@LC = (500,500);

%QoS = $model->calculate(
    configuration => { M => $nb_tiers, AC => \@AC, LC => \@LC},
    workload_class => \%workload_class,
    workload_amount => $workload_amount );
    
print "latency=$QoS{latency}, abort_rate=$QoS{abort_rate}, throughput=$QoS{throughput}\n";    
print Dumper \%Qos;



