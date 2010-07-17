use Data::Dumper;
use Log::Log4perl qw(:easy);
use Test::More 'no_plan';
use Error qw(:try);

use lib qw(../Lib ../../Administrator/Lib);

my $admtest = "AdminTest";
my $exectest = "ExecTest";

note("Use Tests");
use_ok(Administrator);
use_ok(Executor);

note("Load Administrator tests");
Log::Log4perl->easy_init({level=>'DEBUG', file=>'STDOUT', layout=>'%F %L %p %m%n'});
my @args = ("login",'thom', "password", 'pass');
my $adm = new_ok(Administrator => \@args, $admtest);

note("Operation Addition test");
my $addmotherboard_op;
try {
	$addmotherboard_op = $adm->newOp(type => "AddMotherboard", priority => '100', params => { mac_address => '00:1c:c0:c0:1c:9a', kernel_id => 2});
}
catch Error::Simple with {
	my $ex = shift;
	die "Catch error in Operation instanciation : $ex";
};
#my $op3 = $adm->getNextOp( );
#print $op3->getValue( 'type' ), "    ", $op3->getValue( 'operation_id' );

@args = ();
my $exec = new_ok("Executor", \@args, $exectest);
$exec->execnround(run => 1);

$addmotherboard_op->delete();

#pass($exectest);
#fail($admtest);

