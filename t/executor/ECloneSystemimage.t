use Data::Dumper;
use Log::Log4perl "get_logger";
use Test::More 'no_plan';
use lib qw(/workspace/mcs/Administrator/Lib /workspace/mcs/Common/Lib /workspace/mcs/Executor/Lib);

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

my $adm = Administrator->new(%args);
eval {
	
	# create a new system image for the test	
	note("Systemimage creation operation");
	$adm->newOp(type => "AddSystemimage", 
				priority => '100', 
				params => { systemimage_name => 'sysimg_SOURCE', 
							systemimage_desc => 'sysimg source for clone test', 
							distribution_id => 1
	});
		
	@args = ();
	note ("Execution begin");
	my $exec = new_ok("Executor", \@args, $exectest);
	$exec->execnround(run => 1);
	note("Operation Execution is finish");
	
	note("getting last Systemimage");
	my @arr = $adm->getEntities(type => 'Systemimage', hash => {systemimage_name => 'sysimg_source'});
	
	my $sysimg_source = pop( @arr );
	isa_ok($sysimg_source, 'Entity::Systemimage', '$sysimg_source');
	
	my $sourceid = $sysimg_source->getAttr(name => 'systemimage_id');
	note("----------> ID of systemimage source: $sourceid <-----------");
	
	# clone the system image to another new systemimage 	
	note("Systemimage cloning operation");
	$adm->newOp(type => "CloneSystemimage", 
				priority => '100', 
				params => { systemimage_name => 'sysimg_CLONE', 
							systemimage_desc => 'cloned sysimg', 
							systemimage_id => $sourceid
	});
		
	@args = ();
	note ("Execution begin");
	my $exec = new_ok("Executor", \@args, $exectest);
	$exec->execnround(run => 1);
	note("Operation Execution is finish");
	
	# gettin
	note("getting clone Systemimage");
	my @arr = $adm->getEntities(type => 'Systemimage', hash => {systemimage_name => 'sysimg_CLONE'});
	
	my $sysimg_clone = pop( @arr );
	isa_ok($sysimg_clone, 'Entity::Systemimage', '$sysimg_clone');
	
	my $cloneid = $sysimg_clone->getAttr(name => 'systemimage_id');
	note("----------> ID of systemimage clone: $cloneid <-----------");
	
	
	
	note("Systemimages deletion operation");
	$adm->newOp(type => "RemoveSystemimage", 
				priority => '100', 
				params => { systemimage_id => $sourceid});
				
	$adm->newOp(type => "RemoveSystemimage", 
				priority => '100', 
				params => { systemimage_id => $cloneid});	
		
	@args = ();
	note ("Execution begin");
	my $exec = new_ok("Executor", \@args, $exectest);
	$exec->execnround(run => 2);
	note("Operation Execution is finish");
	
	eval {
		my $createsystemimage_op = $adm->getNextOp();
	};
	if ($@){
		is ($@->isa('Mcs::Exception::Internal'), 1, "get Mcs Exception No more operation in queue!");
		my $err = $@;
	}

};
if ($@){
	print "Exception catch, its type is : " . ref($@);
	if ($@->isa('Mcs::Exception')) 
   	{
		print "Mcs Exception\n";
   }
	
}



