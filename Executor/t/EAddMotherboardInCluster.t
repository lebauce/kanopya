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
@args = ();
my $exec = new_ok("Executor", \@args, $exectest);
eval {
	BEGIN { $ENV{DBIC_TRACE} = 1 }	
	note("Create Motherboard");
	$adm->newOp(type => "AddMotherboard", 
				priority => '100',
				params => { 
							motherboard_mac_address => '00:1c:c0:c0:1c:9a', 
							kernel_id => 1, 
							motherboard_serial_number => "Test sn",
							motherboard_model_id => 1,
							processor_model_id => 1});
$adm->newOp(type => "AddMotherboard", 
				priority => '100',
				params => { 
							motherboard_mac_address => '00:aa:aa:ac:1c:aa', 
							kernel_id => 1, 
							motherboard_serial_number => "Test sn2",
							motherboard_model_id => 1,
							processor_model_id => 1});

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

	note ("Execute the addition");
	$exec->execnround(run => 3);
	note("Motherboard and cluster addition is finished");
	
	note("Get the Cluster");
	my @entities = $adm->getEntities(type => 'Cluster', hash=> {cluster_name => 'test', cluster_desc => 'test cluster'});
	my $cluster = $entities[0];
	
	note("Get the Motherboard");
	my @entities2 = $adm->getEntities(type => 'Motherboard', hash=> {motherboard_mac_address => '00:1c:c0:c0:1c:9a'});
	my $motherboard = $entities2[0];

	note("Get the Motherboard2");
	my @entities3 = $adm->getEntities(type => 'Motherboard', hash=> {motherboard_mac_address => '00:aa:aa:ac:1c:aa'});
	my $motherboard2 = $entities3[0];

	
	note("Create operation to migrate the motherboard into the cluster");
	$adm->newOp(type		=> "AddMotherboardInCluster",
				priority	=> '100',
				params		=> {cluster_id => $cluster->getAttr(name => "cluster_id"), 
								motherboard_id => $motherboard->getAttr(name => "motherboard_id")});
	$adm->newOp(type		=> "AddMotherboardInCluster",
				priority	=> '100',
				params		=> {cluster_id => $cluster->getAttr(name => "cluster_id"), 
								motherboard_id => $motherboard2->getAttr(name => "motherboard_id")});

	note("Exec the migration");
	$exec->execnround(run => 2);
	


};
if ($@){
	print "Exception catch, its type is : " . ref($@);
	print Dumper $@;
	if ($@->isa('Mcs::Exception')) 
   	{
		print "Mcs Exception\n";
   }
}
else {
	eval {
		my $addmotherboard_op = $adm->getNextOp();
	};
	if ($@){
		is ($@->isa('Mcs::Exception::Internal'), 1, "get Mcs Exception No more operation in queue!");
		
		my $err = $@;
	}
}


#pass($exectest);
#fail($admtest);

