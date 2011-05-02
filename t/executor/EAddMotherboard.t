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
eval {
#	$adm->{db}->txn_begin;
		
	note("Add Motherboard");	
	$adm->newOp(type => "AddMotherboard", priority => '100', params => { 
		motherboard_mac_address => '00:1c:c0:c0:1c:9a', 
		kernel_id => 1, 
		motherboard_serial_number => "Test sn",
		motherboard_model_id => 1,
		processor_model_id => 1});
	
	$adm->newOp(type => "AddMotherboard", priority => '200', params => { 
		motherboard_mac_address => '00:1c:c1:c1:c1:c1', 
		kernel_id => 1, 
		motherboard_serial_number => "Test2 sn",
		motherboard_model_id => 1,
		processor_model_id => 1});
	
	#BEGIN { $ENV{DBIC_TRACE} = 1 }
	
	@args = ();
	note ("Execution begin");
	my $exec = new_ok("Executor", \@args, $exectest);
	$exec->execnround(run => 2);
	note("Operation Execution is finish");
	
	note("Get The motherboard");
	@entities = $adm->getEntities(type => 'Motherboard', hash=> {motherboard_mac_address => '00:1c:c0:c0:1c:9a'});
	my $motherboard1 = $entities[0];
	@entities = $adm->getEntities(type => 'Motherboard', hash=> {motherboard_mac_address => '00:1c:c1:c1:c1:c1'});
	my $motherboard2 = $entities[0];

	note("Remove Motherboard");	
	$adm->newOp(type => "RemoveMotherboard", priority => '100', params => { motherboard_id => $motherboard1->getAttr(name=>'motherboard_id')});
	$adm->newOp(type => "RemoveMotherboard", priority => '200', params => { motherboard_id => $motherboard2->getAttr(name=>'motherboard_id')});
	
	note ("Execution begin");
	$exec->execnround(run => 2);
	note("Operation Execution is finish");

	eval {
		my $addmotherboard_op = $adm->getNextOp();
	};
	if ($@){
		is ($@->isa('Kanopya::Exception::Internal'), 1, "get Kanopya Exception No more operation in queue!");
		
		my $err = $@;
		
	}

#	$adm->{db}->txn_rollback;
};
if ($@){
	print "Exception catch, its type is : " . ref($@);
	print Dumper $@;
	if ($@->isa('Kanopya::Exception')) 
   	{
		print "Kanopya Exception\n";
   }
#	$adm->{db}->txn_rollback;
}


#pass($exectest);
#fail($admtest);

