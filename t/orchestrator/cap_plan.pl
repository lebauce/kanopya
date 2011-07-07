

use lib qw(/opt/kanopya/lib/orchestrator /opt/kanopya/lib/common);

use CapacityPlanning;
use Model::MVAModel;


my $model = Model::MVAModel->new();


my $cap_plan = CapacityPlanning->new();
$cap_plan->setModel(model => $model);
$cap_plan->setConstraints(constraints => { max_latency => 22, max_abort_rate => 0.3 } );
$cap_plan->setNbTiers(tiers => 3);

my %workload_class = ( visit_ratio => [1,1,1],
		       service_time => [1,1,1],
		       delay => [1,1,1],
		       think_time => 1 );

my $res = $cap_plan->calculate( workload_amount => 1000, workload_class => \%workload_class );

use Data::Dumper;
