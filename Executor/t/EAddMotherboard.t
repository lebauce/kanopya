use Data::Dumper;
use Log::Log4perl qw(:easy);
use Test::More 'no_plan';

use lib qw(../Lib ../../Administrator/Lib ../../Common/Lib);

my $admtest = "AdminTest";
my $exectest = "ExecTest";

note("Use Tests");
use_ok(Administrator);
use_ok(Executor);
use_ok(McsExceptions);

note("Load Administrator tests");
Log::Log4perl->easy_init({level=>'DEBUG', file=>'STDOUT', layout=>'%F %L %p %m%n'});
my @args = ("login",'xebech', "password", 'pass');
my $adm = new_ok(Administrator => \@args, $admtest);
my $addmotherboard_op;
note("Operation Addition test");

eval {
	$addmotherboard_op = $adm->newOp(type => "AddMotherboard", priority => '100', params => { mac_address => '00:1c:c0:c0:1c:9a', kernel_id => 2, c_storage_id => 1});
	@args = ();
	my $exec = new_ok("Executor", \@args, $exectest);
	$exec->execnround(run => 1);

	$addmotherboard_op->delete();
};
if ($@){
	print STDERR "Exception Catch";
	if ($@->isa('Mcs::Exception')) 
   	{
   		print STDERR "MCS Exception catch";
		$addmotherboard_op->delete();
      	print Dumper $@;
   }
}


#pass($exectest);
#fail($admtest);

