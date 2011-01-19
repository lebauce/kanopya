use lib qw(/opt/kanopya/lib/administrator /opt/kanopya/lib/common );

use Data::Dumper;

use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init({level=>'DEBUG', file=>'STDOUT', layout=>'%F %L %p %m%n'});

use Test::More 'no_plan';
use Administrator;

my $adm = Administrator->new( login =>'admin', password => 'admin' );
my $rules_manager = $adm->{manager}->{rules};


eval {
	$adm->{db}->txn_begin;

    # Clean db before test
    $rules_manager->deleteClusterRules( cluster_id => 1 );
	$rules_manager->deleteClusterOptimConditions( cluster_id => 1 );

	my $simple_condition = [ { var => "v1", value => "3", time_laps => 30, operator => "inf" } ];

	my $complex_condition_tree = [ 
									{ var => "v1", value => "3", time_laps => 30, operator => "inf" }, 
    	 			  				'&', 
     				       			[ 
     				       				{ var => "v2", value => "4", time_laps => 40, operator => "sup" },
     				       		  		'|',
     					  		  		{ var => "v3", value => "5", time_laps => 50, operator => "inf" },
     					  		  		'|',
     				  			  		[
		     				  			  	{ var => "v4", value => "6", time_laps => 60, operator => "inf" },
		     				  		  		'&',
		     				  		  		{ var => "v5", value => "7", time_laps => 70, operator => "sup" },
     				  		  			]
     								],
     								'&',
     								{ var => "v6", value => "8", time_laps => 80, operator => "inf" },
     			 		  		 ];

    $rules_manager->addClusterRule( cluster_id => 1,
	 			     condition_tree => $simple_condition,
				     action => "an_action" );

	$rules_manager->addClusterOptimConditions( cluster_id => 1,
	 			     condition_tree => $complex_condition_tree );
	 			     
    my $rules = $rules_manager->getClusterRules( cluster_id => 1 );
    isa_ok( $rules, 'ARRAY');
    ok( 1 == @$rules, "retrieved rule");
    is_deeply( $rules->[0]{condition_tree}, $simple_condition, "get same simple condition" );
    is( $rules->[0]{action}, "an_action", "get action");
    $rules_manager->deleteClusterRules( cluster_id => 1 );
    $rules = $rules_manager->getClusterRules( cluster_id => 1 );
	ok( 0 == @$rules, "delete rule");
	
	##########
    $rules_manager->addClusterRule( cluster_id => 1,
	 			     condition_tree => $complex_condition_tree,
				     action => "another_action" );
				     
	############
	my $conditions = $rules_manager->getClusterOptimConditions( cluster_id => 1 );		     
	isa_ok( $conditions, 'ARRAY');
    cmp_ok( scalar @$conditions, '>', 0, "retrieve optim condition");
    is_deeply( $conditions, $complex_condition_tree, "get same optim condition" );
    $rules_manager->deleteClusterOptimConditions( cluster_id => 1 );
    $conditions = $rules_manager->getClusterOptimConditions( cluster_id => 1 );
	ok( 0 == @$conditions, "delete optim condition"); 
	
	###########
	$rules = $rules_manager->getClusterRules( cluster_id => 1 );
    is_deeply( $rules->[0]{condition_tree}, $complex_condition_tree, "get same condition tree" );
     
	$rules_manager->addClusterRule( cluster_id => 1,
	 			     condition_tree => $simple_condition,
				     action => "an_action" );
	$rules = $rules_manager->getClusterRules( cluster_id => 1 );
	is( scalar @$rules, 2, "retrieve all cluster rules");
	$rules_manager->deleteClusterRules( cluster_id => 1 );
	$rules = $rules_manager->getClusterRules( cluster_id => 1 );
	is( scalar @$rules, 0, "delete all cluster rules");
				    			    
				     
    $adm->{db}->txn_rollback;
};
if($@) {
       my $error = $@;
       
       $adm->{db}->txn_rollback;
       print "$error";
       exit 233;
}

