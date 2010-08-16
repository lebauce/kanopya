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
my %args = (login =>'xebech', password => 'pass');

my $addmotherboard_op;

my $adm = Administrator->new( %args);
eval {
#	$adm->{db}->txn_begin;
	
	note("Create Motherboard");
	$adm->newOp(type => "AddMotherboard", 
				priority => '100',
				params => { 
							motherboard_mac_address => '00:1c:c0:c0:1c:9a', 
							kernel_id => 1, 
							motherboard_serial_number => "Test sn",
							motherboard_model_id => 1,
							processor_model_id => 1});
#	my $pub_net =$adm->newPublicIP(ip_address => '192.168.0.1', ip_mask => '255.255.255.0');
	note("Create Cluster");
	$adm->newOp(type		=> "AddCluster",
				priority	=> '100',
				params		=> {cluster_name => 'test', 
								cluster_desc => 'test cluster',
								cluster_min_node		=> 1,
								cluster_max_node		=> 1,
								cluster_priority		=> 500,
								systemimage_id			=> 1,
								kernel_id				=> 1,
								active					=> 0});
	@args = ();

	note ("Execute the addition");
	my $exec = new_ok("Executor", \@args, $exectest);
	$exec->execnround(run => 2);
	note("Motherboard and cluster addition is finished");
	
	note("Get the Cluster");
	my @entities = $adm->getEntities(type => 'Cluster', hash=> {cluster_name => 'test', cluster_desc => 'test cluster'});
	my $cluster = $entities[0];
	
	note("Get the Motherboard");
	@entities = $adm->getEntities(type => 'Motherboard', hash=> {motherboard_mac_address => '00:1c:c0:c0:1c:9a'});
	my $motherboard = $entities[0];
	
	note("Create operation to migrate the motherboard into the cluster");
	$adm->newOp(type		=> "AddMotherboardInCluster",
				priority	=> '100',
				params		=> {cluster_id => $cluster->getAttr(name => "cluster_id"), 
								motherboard_id => $motherboard->getAttr(name => "motherboard_id")});

	note("Exec the migration");
	$exec->execnround(run => 1);
	
	note("Create operation to remove the motherboard from the cluster");
	$adm->newOp(type		=> "RemoveMotherboardFromCluster",
				priority	=> '100',
				params		=> {cluster_id => $cluster->getAttr(name => "cluster_id"), 
								motherboard_id => $motherboard->getAttr(name => "motherboard_id")});
	
	note("Exec the removing");
	$exec->execnround(run => 1);
	
	note("Remove Cluster");
	$adm->newOp(type		=> "RemoveCluster",
				priority	=> '100',
				params		=> {cluster_id => $cluster->getAttr(name => "cluster_id")});
	note("Remove Motherboard");
		$adm->newOp(type => "RemoveMotherboard", priority => '100', 
					params => { node_id => $motherboard->getAttr(name=>'motherboard_id')});
	
	note("Execute motherboard and cluster removing");
	$exec->execnround(run => 2);
	
	
	eval {
		my $addmotherboard_op = $adm->getNextOp();
	};
	if ($@){
		is ($@->isa('Mcs::Exception::Internal'), 1, "get Mcs Exception No more operation in queue!");
		
		my $err = $@;
	}

};
if ($@){
	print "Exception catch, its type is : " . ref($@);
	print Dumper $@;
	if ($@->isa('Mcs::Exception')) 
   	{
		print "Mcs Exception\n";
   }
}


#pass($exectest);
#fail($admtest);

