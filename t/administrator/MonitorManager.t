use lib qw(/opt/kanopya/lib/administrator /opt/kanopya/lib/common );

use Data::Dumper;

use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init({level=>'DEBUG', file=>'STDOUT', layout=>'%F %L %p %m%n'});

use Test::More 'no_plan';
use Administrator;



Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
my $adm = Administrator->new();
my $monitor_manager = $adm->{manager}->{monitor};


eval {
     $adm->{db}->txn_begin;

     #my $sets = $monitor_manager->getIndicatorSets();
     #my $sets = $monitor_manager->getAllSets();
    
    #$monitor_manager->collectSet( cluster_id => 1, set_name => 'mem' );
    
     my $sets = $monitor_manager->getCollectedSets( cluster_id => 1 );

	print Dumper $sets;
	
	
#	my $set = $monitor_manager->getSetDesc( set_name => 'cpu' );
#	print Dumper $set;

	#my $graph = $monitor_manager->getGraphSettings( cluster_id => 1, set_name => 'cpuu');
	my $graph = $monitor_manager->getClusterGraphSettings( cluster_id => 1 );
	print "############################\n", Dumper $graph;

     $adm->{db}->txn_rollback;
};
if($@) {
       my $error = $@;
       print "$error";
       $adm->{db}->txn_rollback;
       
       exit 233;
}

