use Data::Dumper;
use Log::Log4perl "get_logger";
use Test::More 'no_plan';

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

my $op;

my $adm = Administrator->new( %args);
eval {
	BEGIN { $ENV{DBIC_TRACE} = 1 }	
	@args = ();

	note ("Execute the addition");
	my $exec = new_ok("Executor", \@args, $exectest);
	$exec->execnround(run => 1);


};
if ($@){
	print "Exception catch, its type is : " . ref($@);
	print Dumper $@;
	if ($@->isa('Kanopya::Exception')) 
   	{
		print "Kanopya Exception\n";
   }
}


#pass($exectest);
#fail($admtest);

