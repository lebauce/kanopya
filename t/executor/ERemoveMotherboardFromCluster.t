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
use_ok(Kanopya::Exceptions);

note("Load Administrator tests");
my %args = (login =>'xebech', password => 'pass');

my $addmotherboard_op;

my $adm = Administrator->new( %args);
@args = ();
my $exec = new_ok("Executor", \@args, $exectest);
eval {
	BEGIN { $ENV{DBIC_TRACE} = 1 }	

	note("Get the Cluster");
	my @entities = $adm->getEntities(type => 'Cluster', hash=> {cluster_name => 'BenchWeb', cluster_desc => 'Benchmark cluster'});
	my $cluster = $entities[0];
	
	note("Get the Motherboard");
	my @entities2 = $adm->getEntities(type => 'Motherboard', hash=> {motherboard_mac_address => '00:1c:c0:c0:1c:9a'});
	my $motherboard = $entities2[0];
	
	note("Get the Motherboard");
	my @entities3 = $adm->getEntities(type => 'Motherboard', hash=> {motherboard_mac_address => '00:aa:aa:ac:1c:aa'});
	my $motherboard2 = $entities3[0];

	
	note("Create operation to remove the motherboard from the cluster");
	$adm->newOp(type		=> "RemoveMotherboardFromCluster",
				priority	=> '100',
				params		=> {cluster_id => $cluster->getAttr(name => "cluster_id"), 
								motherboard_id => $motherboard->getAttr(name => "motherboard_id")});
	
	$adm->newOp(type		=> "RemoveMotherboardFromCluster",
				priority	=> '100',
				params		=> {cluster_id => $cluster->getAttr(name => "cluster_id"), 
								motherboard_id => $motherboard2->getAttr(name => "motherboard_id")});
	note("Exec the removing");
	$exec->execnround(run => 2);
	
#	note("Remove Cluster");
#	$adm->newOp(type		=> "RemoveCluster",
#				priority	=> '100',
#				params		=> {cluster_id => $cluster->getAttr(name => "cluster_id")});
	note("Remove Motherboard");
		$adm->newOp(type => "RemoveMotherboard", priority => '100', 
					params => { motherboard_id => $motherboard->getAttr(name=>'motherboard_id')});
	
		note("Remove Motherboard2");
		$adm->newOp(type => "RemoveMotherboard", priority => '100', 
					params => { motherboard_id => $motherboard2->getAttr(name=>'motherboard_id')});
	note("Execute motherboard and cluster removing");
	$exec->execnround(run => 2);

};
if ($@){
	print "Exception catch, its type is : " . ref($@);
	print Dumper $@;
	if ($@->isa('Kanopya::Exception')) 
   	{
		print "Kanopya Exception\n";
   }
}
else {
	eval {
		my $addmotherboard_op = $adm->getNextOp();
	};
	if ($@){
		is ($@->isa('Kanopya::Exception::Internal'), 1, "get Kanopya Exception No more operation in queue!");
		
		my $err = $@;
	}
}


#pass($exectest);
#fail($admtest);

