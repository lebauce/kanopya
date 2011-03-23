

use lib qw(/opt/kanopya/lib/orchestrator /opt/kanopya/lib/common);

use Model::MVAModel;

my $model = Model::MVAModel->new();


my $workload_amount = 2;
my $nb_tiers = 3;
my %workload_class = ( visit_ratio => [1,2,3],
		       service_time => [2,2,2],
		       delay => [1,1,1],
		       think_time => 1 );
my $mpl = 10;
my @AC = (1,1,1);
my @LC = ($mpl, $mpl, $mpl);

my %QoS = $model->calculate(  configuration => { M => $nb_tiers, AC => \@AC, LC => \@LC},
			      workload_class => \%workload_class,
			      workload_amount => $workload_amount );

use Data::Dumper;
print Dumper \%QoS;
