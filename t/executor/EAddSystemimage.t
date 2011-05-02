use Data::Dumper;
use Log::Log4perl "get_logger";
use Test::More 'no_plan';

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

my $createsystemimage_op;

my $adm = Administrator->new(%args);
eval {
		
	note("Operation Addition test");
	$adm->newOp(type => "AddSystemimage", 
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
		is ($@->isa('Kanopya::Exception::Internal'), 1, "get Kanopya Exception No more operation in queue!");
		my $err = $@;
	}

};
if ($@){
	print "Exception catch, its type is : " . ref($@);
	print Dumper $@;
	if ($@->isa('Kanopya::Exception')) 
   	{
		print "Kanopya Exception\n";
   }
	
}



