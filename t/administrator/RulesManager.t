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

     $rules_manager->deleteClusterRules( cluster_id => 1 );

     my $condition_tree = [ { var => "EE", value => "3", operator => "inf" }, '|', [ { var => "GG", value => "4", operator => "sup" }, '|', { var => "PP", value => "5", operator => "inf" } ] ];

     $rules_manager->addClusterRule( cluster_id => 1,
	 			     condition_tree => $condition_tree,
				     action => "do_action" );

     my $rules = $rules_manager->getClusterRules( cluster_id => 1 );

     is_deeply( $rules->[0]{condition_tree}, $condition_tree, "get same condition tree" );

     is( $rules->[0]{action}, "do_action", "get action");

     $rules_manager->deleteClusterRules( cluster_id => 1 );
     $rules = $rules_manager->getClusterRules( cluster_id => 1 );
     is_deeply( $rules, [], "delete rules");

     $adm->{db}->txn_rollback;
};
if($@) {
       my $error = $@;
       
       $adm->{db}->txn_rollback;
       print "$error";
       exit 233;
}

