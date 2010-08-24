use Log::Log4perl "get_logger";
use Test::More 'no_plan';
use lib qw(/workspace/mcs/Administrator/Lib /workspace/mcs/Common/Lib /workspace/mcs/Executor/Lib);
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'FATAL', file=>'STDOUT', layout=>'%F %L %p %m%n'});

my $admtest = "AdminTest";
my $exectest = "ExecTest";

note("Use Tests");
use_ok(Administrator);
use_ok(Executor);
use_ok(McsExceptions);

my %args = (login =>'xebech', password => 'pass');
my $adm = Administrator->new( %args);

$adm->{db}->txn_begin;

note("Operation::AddComponentToCluster parameters existence checking");

eval { $adm->newOp(type => "AddComponentToCluster", priority => '100', params => {}); };
is(ref $@, 'Mcs::Exception::Internal::IncorrectParam', ref($@)." thrown when no parameters");	

eval { $adm->newOp(type => "AddComponentToCluster", priority => '100', 
	params => { cluster_id => 1 }); };
is(ref $@, 'Mcs::Exception::Internal::IncorrectParam', ref($@)." thrown when only one parameter (cluster_id)");	

eval { $adm->newOp(type => "AddComponentToCluster", priority => '100', 
	params => { cluster_id => 1, component_id => 1 });
};
is(ref $@, 'Mcs::Exception::Internal::IncorrectParam', ref($@).' thrown when only two parameters (cluster_id and component_id)');

eval { $adm->newOp(type => "AddComponentToCluster", priority => '100', 
	params => { cluster_id => 1, component_id => 1, component_template_id => 1 });
};
isnt(ref $@, 'Mcs::Exception::Internal::IncorrectParam', 'No Mcs::Exception::Internal::IncorrectParam thrown with all required parameters (cluster_id, component_id and component_template_id)');	

note("Operation::AddComponentToCluster parameters value checking");
eval { $adm->newOp(type => "AddComponentToCluster", priority => '100', 
	params => { cluster_id => -1, component_id => 1, component_template_id => 1 });
};
is(ref $@, 'Mcs::Exception::Internal::WrongValue', ref($@).' thrown when wrong parameter cluster_id (-1)');

eval { $adm->newOp(type => "AddComponentToCluster", priority => '100', 
	params => { cluster_id => 1, component_id => -1, component_template_id => 1 });
};
is(ref $@, 'Mcs::Exception::Internal::WrongValue', ref($@).' thrown when wrong parameter component_id (-1)');

eval { $adm->newOp(type => "AddComponentToCluster", priority => '100', 
	params => { cluster_id => 1, component_id => 1, component_template_id => -1 });
};
is(ref $@, 'Mcs::Exception::Internal::WrongValue',  ref($@).' thrown when wrong parameter component_template_id (-1)');

eval { $adm->newOp(type => "AddComponentToCluster", priority => '100', 
	params => { cluster_id => 1, component_id => 1, component_template_id => 1 });
};
isnt(ref $@, 'Mcs::Exception::Internal::WrongValue', 'No Mcs::Exception::Internal::WrongValue thrown when all parameters found in database');

eval { $adm->newOp(type => "AddComponentToCluster", priority => '100', 
	params => { cluster_id => 1, component_id => 1, component_template_id => 1 });
};
is(ref $@, 'Mcs::Exception::Internal', ref($@).' thrown when cluster already has this component');

$adm->{db}->txn_rollback;



	
#	@args = ();
#	note ("Execution begin");
#	my $exec = new_ok("Executor", \@args, $exectest);
#	$exec->execnround(run => 2);
#	note("Operation Execution is finish");


#pass($exectest);
#fail($admtest);

