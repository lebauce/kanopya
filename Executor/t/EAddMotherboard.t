use Data::Dumper;
use Log::Log4perl "get_logger";
use Test::More 'no_plan';

use lib qw(../Lib ../../Administrator/Lib ../../Common/Lib);


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


eval {
	my $adm = Administrator->new( %args);
	note("Operation Addition test");
	$addmotherboard_op = $adm->newOp(type => "AddMotherboard", priority => '100', params => { mac_address => '00:1c:c0:c0:1c:9a', kernel_id => 2, c_storage_id => 1});
	@args = ();
	my $exec = new_ok("Executor", \@args, $exectest);
	$exec->execnround(run => 1);
note("Operation Execution is finish");
	$addmotherboard_op->delete();
};
if ($@){
	print "Exception catch, its type is : " . ref($@);
	print Dumper $@;
	if ($@->isa('Mcs::Exception')) 
   	{
		print "Mcs Exception\n";
   }
   $addmotherboard_op->delete();
}


#pass($exectest);
#fail($admtest);

