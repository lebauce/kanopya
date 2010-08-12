use Data::Dumper;
use Log::Log4perl "get_logger";
use Test::More 'no_plan';
use lib qw (/workspace/mcs/Administrator/Lib /workspace/mcs/Common/Lib /workspace/mcs/Executor/Lib);

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

my $createsystemimage_op;

my $adm = Administrator->new(%args);
eval {
	$adm->{db}->txn_begin;
	
	note("Operation Addition test");
	$adm->newOp(type => "CreateSystemimage", 
				priority => '100', 
				params => { systemimage_name => 'mon_systemimage', 
							systemimage_desc => 'et blablabla et blablabla', 
							distribution_id => 1
	});
	@args = ();
	note ("Execution begin");
	my $exec = new_ok("Executor", \@args, $exectest);
	$exec->execnround(run => 1);
	note("Operation Execution is finish");
	eval {
		my $createsystemimage_op = $adm->getNextOp();
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

