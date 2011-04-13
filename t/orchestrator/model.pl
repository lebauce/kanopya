

use lib qw(/opt/kanopya/lib/orchestrator /opt/kanopya/lib/common);

use Model::MVAModel;

my $model = Model::MVAModel->new();


#my $workload_amount = 30;

print "enter amount: ";
my $workload_amount = <STDIN>;

print "Worload amount: $workload_amount\n";

my $nb_tiers = 1;
my %workload_class = ( visit_ratio => [1],
		       service_time => [0.011],
		       delay => [0],
		       think_time => 2 );
my $mpl = 1500;
my @AC = (1);
my @LC = ($mpl);

my %QoS = $model->calculate(  
    configuration => { M => $nb_tiers, AC => \@AC, LC => \@LC},
    workload_class => \%workload_class,
    workload_amount => $workload_amount );

use Data::Dumper;
print Dumper \%QoS;
