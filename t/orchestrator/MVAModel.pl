use Test::More 'no_plan';
use Test::Deep;
use Log::Log4perl "get_logger";

Log::Log4perl->init('/opt/kanopya/conf/orchestrator-log.conf');

BEGIN {
    use_ok ('Model::MVAModel');
    use_ok ('Model::MVAModel_v2');
    use_ok ('Model::MVAModel_v3');
    use_ok ('Model::MVAModel_v4'); 
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
    
print "latency=$QoS{latency}, abort_rate=$QoS{abort_rate}, throughput=$QoS{throughput}\n";

cmp_deeply(\%QoS,
{
          'throughput' => '48152.6722962806',
          'latency' => '0.060875',
          'abort_rate' => '0.66161849084335'
    
},'scenario 1 for MVAModel checked');



#$workload_amount = 3610;
{
$workload_amount = 6000;
$nb_tiers = 2;
%workload_class = ( 
               visit_ratio => [1,1],
               #service_time => [0.000263214111328125,0.00146484375], #0.0203094482421875
               #delay => [0,0.08416748046875],
               service_time => [0.00262039038352668, 0.00146484375], #0.0203094482421875
               delay => [0,0.012451171875],
               think_time => 10 );
@AC = (1,1);
@LC = (7000,7000);
}

my $workload_amount = 1000;
my $nb_tiers = 2;
my %workload_class = ( 
               visit_ratio  => [1,0.13],
               service_time => [0.001670911,0.00000001],#service_time => [0.00166666666],
               delay        => [0,0.001],
               think_time   => 0.568964 ); #0.568964
               #1.13894621165562/2);
my @AC = (2,1);
my @LC = (100000,29500);

my $workload_amount = 2000;
my $nb_tiers = 1;
my %workload_class = ( 
               visit_ratio  => [1,0.13],
               service_time => ['0.00180133283734321', 0],
               delay        => [0,1.01730963587761],
               think_time => 0.55 );
my @AC = (2,1);
my @LC = (100000,29500);




#my $workload_amount = 1000;
#my $nb_tiers = 3;
#my %workload_class = ( 
#               visit_ratio  => [1,0.5,0.20],
#               service_time => [0.002,0.009,0.001],#service_time => [0.00166666666],
#               delay        => [0,0.000000001,0.000000001],
#               think_time => 0.568964);
#               #1.13894621165562/2);
#my @AC = (1,1,1);
#my @LC = (100000,29500,60000);
#
#my $workload_amount = 1000;
#my $nb_tiers = 3;
#my %workload_class = ( 
#               visit_ratio  => [1,0.5,0.2],
#               service_time => [0.002,0.009,0.001],#service_time => [0.00166666666],
#               delay        => [0,0.0,0.0], #[0,0.003,0.07],
#               think_time => 0.568964);
#               #1.13894621165562/2);
#my @AC = (1,1,1);
#my @LC = (100000,29500,60000);


$model = Model::MVAModel_v4->new();

%QoS = $model->calculate(
    configuration   => { M => $nb_tiers, AC => \@AC, LC => \@LC},
    workload_class  => \%workload_class,
    workload_amount => $workload_amount );

    
print "latency=$QoS{latency}\n";
print "abort_rate=$QoS{abort_rate}\n";
print "throughput=$QoS{throughput}\n";
print "La=@{$QoS{La}}\n";
print "Ql=@{$QoS{Ql}}\n";
print "Ta=@{$QoS{Ta}}\n";
print "Tr=@{$QoS{Tr}}\n";
print "R=@{$QoS{R}}\n";

print "La_diff=".(${$QoS{La}}[0]-${$QoS{La}}[1])."\n";
print Dumper \%Qos;


