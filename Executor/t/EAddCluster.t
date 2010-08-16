use Data::Dumper;
use Log::Log4perl "get_logger";
use Test::More 'no_plan';
use lib qw (/workspace/mcs/Administrator/Lib /workspace/mcs/Common/Lib /workspace/mcs/Executor/Lib);

#Log::Log4perl->init('../Conf/log.conf');
#my $log = get_logger("executor");
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'STDOUT', layout=>'%F %L %p %m%n'});

my $admtest = "AdminTest";
my $exectest = "ExecTest";

note("Use Tests");
use_ok(Administrator);
use_ok(Executor);
use_ok(McsExceptions);

note("Load Administrator tests");
my %
args = (login =>'xebech', password => 'pass');

my $addmotherboard_op;

my $adm = Administrator->new( %args);
eval {
	@args = ();
	note ("Execute cluster addition operation");
	my $exec = new_ok("Executor", \@args, $exectest);


#	$adm->{db}->txn_begin;
	
	note("Adding  Cluster 1");

	$adm->newOp(type		=> "AddCluster",
				priority	=> '100',
				params		=> {cluster_name => 'test1', 
								cluster_desc => 'test cluster 1',
								cluster_min_node		=> 1,
								cluster_max_node		=> 1,
								cluster_priority		=> 500,
								systemimage_id			=> 1,
								kernel_id				=> 1,
								active					=> 0});

	note("Adding  Cluster 2");
	$adm->newOp(type		=> "AddCluster",
				priority	=> '100',
				params		=> {cluster_name => 'test2', 
								cluster_desc => 'test cluster 2',
								cluster_min_node		=> 1,
								cluster_max_node		=> 1,
								cluster_priority		=> 500,
								systemimage_id			=> 1,
								kernel_id				=> 1,
								active					=> 0});
	
		
	#BEGIN { $ENV{DBIC_TRACE} = 1 }
	$exec->execnround(run => 2);
	note("Additions finished");

	note("Get the first Cluster");
	my @entities = $adm->getEntities(type => 'Cluster', hash=> {cluster_name => 'test1', cluster_desc => 'test cluster 1'});
	isa_ok( $entities[0], "Entity::Cluster", $admtest);
	
	my $clustid = $entities[0]->getAttr(name => 'cluster_id');
	is( $entities[0]->{_dbix}->in_storage , 1, $admtest ); 
	is( $entities[0]->getAttr( name => 'cluster_name' ), 'test1', $exectest );	
	
	note("Remove Cluster 1");
	$adm->newOp(type		=> "RemoveCluster",
			priority	=> '100',
			params		=> {cluster_id => $clustid});
	# Here Test number of entity returned
	
	note("Try to get deleted Cluster 1");
	@entities = $adm->getEntities(type => 'Cluster', hash=> {cluster_name => 'test', cluster_desc => 'test cluster 1'});
	my $hash = $entities[0];
	is (keys (%$hash), 0, $exectest);
	
	note("Get the second cluster");
	@entities = $adm->getEntities(type => 'Cluster', hash=> {cluster_name => 'test2', cluster_desc => 'test cluster 2'});
	$clustid = $entities[0]->getAttr(name => 'cluster_id');

	#BEGIN { $ENV{DBIC_TRACE} = 1 }
	$exec->execnround(run => 2);

	eval {
		my $addmotherboard_op = $adm->getNextOp();
	};
	if ($@){
				my $err = $@;
		
		is ($@->isa('Mcs::Exception::Internal'), 1, "get Mcs Exception No more operation in queue!");
	}

#	$adm->{db}->txn_rollback;
};
if ($@){
	print "Exception catch, its type is : " . ref($@);
	print Dumper $@;
	if ($@->isa('Mcs::Exception')) 
   	{
		print "Mcs Exception\n";
   }
#	$adm->{db}->txn_rollback;
}


