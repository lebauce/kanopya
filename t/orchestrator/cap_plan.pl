

use lib qw(/opt/kanopya/lib/orchestrator /opt/kanopya/lib/common);

use CapacityPlanning::IncrementalSearch;
use Model::MVAModel;
use Data::Dumper;

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

my $workload_amount = 1000;

$cap_plan->setSearchSpaceForTiers(search_spaces => \@search_spaces);

my %workload_class = ( 
                visit_ratio => [1,1,1],
                service_time => [1,1,1],
                delay => [0,0.5,0.5],
                think_time => 1 );

my $res = $cap_plan->calculate( workload_amount => $workload_amount, workload_class => \%workload_class );

print Dumper $res;

my $AC = $res->{AC};

my %verify = $model->calculate(  
    configuration => { M => $nb_tiers, AC => $AC, LC => $res->{LC}},
    workload_class => \%workload_class,
    workload_amount => $workload_amount ); 

print Dumper \%verify;

my $allIsOk = $verify->{latency} <= $max_latency && $verify->{abort_rate} <= $max_abort_rate;
    print "$verify{latency} <= $max_latency AND $verify{abort_rate} <= $max_abort_rate\n"; 


print "\n";
print "Check if there is no better infra\n";
print "\n";

for $i (0..$nb_tiers-1){
    my @AC_m = @$AC;    
    $AC_m[$i]--;
    #print Dumper \@AC_m; 
    %verify = $model->calculate(  
    configuration => { M => $nb_tiers, AC => \@AC_m, LC => $res->{LC}},
    workload_class => \%workload_class,
    workload_amount => $workload_amount );

    #print "$verify{latency} <= $max_latency AND $verify{abort_rate} <= $max_abort_rate\n"; 

    my $temp = !($verify{latency} <= $max_latency) && ($verify{abort_rate} <= $max_abort_rate);
    $allIsOk &&= $temp;
}

if ($allIsOk){
    print "Seems ok\n"
}else
{
    print "Seems not ok\n"
}