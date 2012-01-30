#!/usr/bin/perl -w
use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Kanopya::Exceptions;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'/tmp/Host.t.log', layout=>'%F %L %p %m%n'});
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
	my $executor = new_ok('Executor', \@args, 'Instantiate an executor');
 
    $db->txn_begin;
    throws_ok { 
		Entity::Host->create(
		    host_mac_address => '70:71tbc:6c:2d:b1',
		    kernel_id => 44,
		    host_serial_number => 'serial',
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
			host_mac_address   => '00:00:00:00:00:00',
			kernel_id          => 44,
			host_serial_number => 'serial',
			hostmodel_id       => 7,
			processormodel_id  => 26,
			host_ram           => 1000000,
			host_core          => 1
		);
	} 'AddHost operation enqueue';
	
	lives_ok { $executor->execnround(run => 1); } 'AddHost operation execution succeed';

	my ($host, $host_id);
	lives_ok { 
		$host = Entity::Host->getHost(hash => {host_mac_address => '00:00:00:00:00:00'});
	} 'retrieve Host via mac address';
	
	isa_ok($host, 'Entity::Host'); 	
	
	lives_ok { $host_id = $host->getAttr(name=>'host_id')} 'get Attribute host_id';
	
	isnt($host_id, undef, "host_id is defined ($host_id)");
	
	lives_ok { $host->activate; } 'ActivateHost operation enqueue';
	lives_ok { $executor->execnround(run => 1); } 'ActivateHost operation execution succeed';
    $host = Entity::Host->get(id => $host_id);
    is ($host->getAttr(name=>'active'), 1, 'Host successfully activated');
        
    lives_ok { $host->deactivate; } 'DeactivateHost operation enqueue';
    lives_ok { $executor->execnround(run => 1); } 'DeactivateHost operation execution succeed';
    $host = Entity::Host->get(id => $host_id);
    is ($host->getAttr(name=>'active'), 0, 'Host successfully deactivated');
    
    lives_ok { $host->remove; } 'RemoveHost operation enqueue';
    lives_ok { $executor->execnround(run => 1); } 'RemoveHost operation execution succeed';
    
    throws_ok { $host = Entity::Host->get(id => $host_id);} 
		'Kanopya::Exception::DB',
		"Host with id $host_id does not exist anymore";
    



};
if($@) {
	my $error = $@;
	print Dumper $error;
};

