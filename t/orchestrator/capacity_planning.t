use Test::More 'no_plan';
use Test::Deep;
use Log::Log4perl "get_logger";

Log::Log4perl->init('/opt/kanopya/conf/orchestrator-log.conf');

BEGIN {
    use_ok ('Model::MVAModel');
    use_ok ('CapacityPlanning::IncrementalSearch');
}

my $model = Model::MVAModel->new();


my $cap_plan = CapacityPlanning::IncrementalSearch->new();
my $nb_tiers = 3;
my $max_latency = 20;
my $max_abort_rate = 0.3;

$cap_plan->setModel(model => $model);
$cap_plan->setConstraints(constraints => { max_latency => $max_latency, max_abort_rate => $max_abort_rate } );
$cap_plan->setNbTiers(tiers => $nb_tiers);

my @search_spaces = ();
my $mpl = 200; # USELESS FOR THE ALGORITHM

for (0..2)
{
   push @search_spaces, 
    {
        min_node => 0, 
        max_node => 100,
        min_mpl => $mpl,
        max_mpl => $mpl,
    };
}

print Dumper $search_spaces;
my $workload_amount = 1000;

$cap_plan->setSearchSpaceForTiers(search_spaces => \@search_spaces);

my %workload_class = ( visit_ratio => [1,1,1],
               service_time => [1,1,1],
               delay => [0,0.5,0.5],
               think_time => 1 );

my $res = $cap_plan->calculate( workload_amount => $workload_amount, workload_class => \%workload_class );

my @expected_AC = (48,27,40);

my $compare = ($res->{AC});

cmp_deeply($compare, \@expected_AC,'scenario 1 for CapacityPlanning checked');
