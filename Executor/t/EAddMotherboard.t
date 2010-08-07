use Data::Dumper;
use Log::Log4perl "get_logger";
use Test::More 'no_plan';
use lib qw (/workspace/mcs/Administrator/Lib /workspace/mcs/Common/Lib /workspace/mcs/Executor/Lib);

Log::Log4perl->init('../Conf/log.conf');
my $log = get_logger("executor");

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
	$adm->{db}->txn_begin;
	
	note("Operation Addition test");
	$adm->newOp(type => "AddMotherboard", priority => '100', params => { motherboard_mac_address => '00:1c:c0:c0:1c:9a', kernel_id => 2, motherboard_sn => "Test sn"});
	$adm->newOp(type => "AddMotherboard", priority => '200', params => { motherboard_mac_address => '00:1c:c1:c1:c1:c1', kernel_id => 1, motherboard_sn => "Test2 sn"});
	@args = ();
	note ("Execution begin");
	my $exec = new_ok("Executor", \@args, $exectest);
	$exec->execnround(run => 2);
	note("Operation Execution is finish");
	eval {
		my $addmotherboard_op = $adm->getNextOp();
	};
	if ($@){
		is ($@->isa('Mcs::Exception::Internal'), 1, "get Mcs Exception No more operation in queue!");
		
		my $err = $@;
		
	}

	$adm->{db}->txn_rollback;
};
if ($@){
	print "Exception catch, its type is : " . ref($@);
	print Dumper $@;
	if ($@->isa('Mcs::Exception')) 
   	{
		print "Mcs Exception\n";
   }
	$adm->{db}->txn_rollback;
}


#pass($exectest);
#fail($admtest);

