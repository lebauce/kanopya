

use lib qw(/opt/kanopya/lib/orchestrator /opt/kanopya/lib/common);

use Model::MVAModel;

my $model = Model::MVAModel->new();


#my $workload_amount = 30;

print "enter amount: ";
my $workload_amount = <STDIN>;

print "Worload amount: $workload_amount\n";
{
    my $nb_tiers = 3;
    my %workload_class = ( visit_ratio => [1,0.5,2],
			   service_time => [0.01,0.05,0.01],
			   delay => [0.05,0.05,0.05],
			   think_time => 0.1 );
    my @AC = (1,1,2);
    my @LC = (20,15,3);
}
{
my $nb_tiers =1;
my %workload_class = ( visit_ratio => [1],
		       service_time => [0.001],
		       delay => [0],
		       think_time => 10 );
my @AC = (1);
my @LC = (150);

}
 
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

use Data::Dumper;
print Dumper \%QoS;
