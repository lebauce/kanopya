#!/usr/bin/perl -w
use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Kanopya::Exceptions;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'/tmp/test.log', layout=>'%F %L %p %m%n'});
use Data::Dumper;

use_ok('Executor');
use_ok ('Administrator');
use_ok('Entity::Host');

eval {
#    BEGIN { $ENV{DBIC_TRACE} = 1 }
    Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
    my $adm = Administrator->new;
    my $db = $adm->{db};
 
	my @args = ();
	my $executor = new_ok("Executor", \@args, "Instantiate an executor");
 
    $db->txn_begin;
    throws_ok { 
		Entity::Host->create(
		    host_mac_address => '70:71tbc:6c:2d:b1',
		    kernel_id => 44,
		    host_serial_number => "Wrong Mac",
		    hostmodel_id => 7,
		    processormodel_id => 26 
		);
	} 	'Kanopya::Exception::Internal::WrongValue',
		'bad attribute value';
	$db->txn_rollback;

	$db->txn_begin;
    throws_ok { 
		Entity::Host->create(
		    host_mac_address => '70:71:bc:6c:2d:b1',
		    kernel_id => 44,
		    hostmodel_id => 7,
		    processormodel_id => 26
		); 
	}	'Kanopya::Exception::Internal::IncorrectParam',
		'missing mandatory attribute';
	$db->txn_rollback;

	lives_ok {
		Entity::Host->create(
			host_mac_address => '00:00:00:00:00:00',
			kernel_id => 44,
			host_serial_number => "Second Host",
			hostmodel_id => 7,
			processormodel_id => 26
		);
	} 'AddHost operation enqueue';
	
	lives_ok { $executor->execnround(run => 1); } 'AddHost operation execution succeed';

	my $host;
	lives_ok { 
		$host = Entity::Host->getHost(hash => {host_mac_address => '00:00:00:00:00'});
	} 'retrieve Host via mac address';
	
	lives_ok { $host->activate; } 'ActivateHost operation enqueue';
	
	lives_ok { $executor->execnround(run => 1); } 'ActivateHost operation execution succeed';
    

   
#~ 
#~ 
#~ $executor->execnround(run => 1);
#~ 
#~ # We could not get exception in execnrun, because all exceptions are catched by oneRun
#~ #    $clone_m1->activate();
#~ #    throws_ok { $executor->execnround(run => 1) } 'Kanopya::Exception::Internal',
#~ #    "Activate a second time same host";
	#~ note( "Test Host activation");
    #~ my $clone_m1 = 
    #~ $clone_m1->activate();
    #~ $executor->execnround(run => 1);
    #~ 
    #~ 
    #~ $clone_m1 = Entity::Host->get(id => $clone_m1->getAttr(name=>'host_id'));
    #~ $clone_m1->deactivate();
    #~ $executor->execnround(run => 1);
    #~ $clone_m1 = Entity::Host->get(id => $clone_m1->getAttr(name=>'host_id'));
    #~ is ($clone_m1->getAttr(name=>'active'), 0, "Deactivate Host");
#~ 
#~ 
    #~ $clone_m1->remove();
    #~ $executor->execnround(run => 1);
    #~ throws_ok { $clone_m1 = Entity::Host->get(id => $clone_m1->getAttr(name=>'host_id'))} 'Kanopya::Exception::Internal',
    #~ "Try to get a deleted host";
#~ 
    #~ note("Test Host.pm pod");
    #~ pod_file_ok( '/opt/kanopya/lib/administrator/Entity/Host.pm', 'stuff docs are valid POD' );

};
if($@) {
	my $error = $@;
	print Dumper $error;
};

