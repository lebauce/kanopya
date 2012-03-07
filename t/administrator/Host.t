#!/usr/bin/perl -w
use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Kanopya::Exceptions;
use Entity::Hostmodel;
use Entity::Processormodel;
use Entity::Kernel;

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

    my $hostmodel;
	lives_ok {
		$hostmodel = Entity::Hostmodel->find(hash => {});
	} 'Get an existing host model';
    $db->txn_rollback;

    $db->txn_begin;

    my $kernel;
	lives_ok {
		$kernel = Entity::Kernel->find(hash => {});
	} 'Get an existing kernel';
    $db->txn_rollback;

    $db->txn_begin;

    my $processormodel;
	lives_ok {
		$processormodel = Entity::Processormodel->find(hash => {});
	} 'Get an existing kernel';
    $db->txn_rollback;

    $db->txn_begin;
    throws_ok { 
		Entity::Host->create(
		    host_mac_address   => '70:71tbc:6c:2d:b1',
		    kernel_id          => $kernel->getAttr(name => 'kernel_id'),
		    host_serial_number => 'serial',
		    hostmodel_id       => $hostmodel->getAttr(name => 'hostmodel_id'),
		    processormodel_id  => $processormodel->getAttr(name => 'processormodel_id'),
		);
	} 	'Kanopya::Exception::Internal::WrongValue',
		'bad attribute value';
	$db->txn_rollback;

	$db->txn_begin;
    throws_ok { 
		Entity::Host->create(
		    host_mac_address  => '70:71:bc:6c:2d:b1',
		    kernel_id         => $kernel->getAttr(name => 'kernel_id'),
		    hostmodel_id      => $hostmodel->getAttr(name => 'hostmodel_id'),
		    processormodel_id => $processormodel->getAttr(name => 'processormodel_id'),
		); 
	}	'Kanopya::Exception::Internal::IncorrectParam',
		'missing mandatory attribute';
	$db->txn_rollback;

	$db->txn_begin;
	lives_ok {
		Entity::Host->create(
			host_mac_address   => '00:00:00:00:00:00',
			kernel_id          => $kernel->getAttr(name => 'kernel_id'),
			host_serial_number => 'serial',
			hostmodel_id       => $hostmodel->getAttr(name => 'hostmodel_id'),
			processormodel_id  => $processormodel->getAttr(name => 'processormodel_id'),
			host_ram           => 1000000,
			host_core          => 1
		);
	} 'AddHost operation enqueue';
	
	lives_ok { $executor->oneRun(); } 'AddHost operation execution succeed';

	my ($host, $host_id);
	lives_ok { 
		$host = Entity::Host->getHost(hash => {host_mac_address => '00:00:00:00:00:00'});
	} 'retrieve Host via mac address';

	isa_ok($host, 'Entity::Host'); 	

	lives_ok { $host_id = $host->getAttr(name => 'host_id') } 'get Attribute host_id';
	
	isnt($host_id, undef, "host_id is defined ($host_id)");
	
	lives_ok { $host->activate; } 'ActivateHost operation enqueue';
	lives_ok { $executor->oneRun(); } 'ActivateHost operation execution succeed';

    $host = Entity::Host->get(id => $host_id);
    is ($host->getAttr(name => 'active'), 1, 'Host successfully activated');

    lives_ok { $host->deactivate; } 'DeactivateHost operation enqueue';
    lives_ok { $executor->oneRun(); } 'DeactivateHost operation execution succeed';

    $host = Entity::Host->get(id => $host_id);
    lives_ok {
       $host->addIface(
            iface_name     => 'eth0',
            iface_mac_addr => '14:DA:E9:DD:B5:62',
            iface_pxe      => 0,
       );
    } 'AddIface on host <$host_id>';

    is ($host->getAttr(name=>'active'), 0, 'Host successfully deactivated');

    lives_ok { $host->remove; } 'RemoveHost operation enqueue';

    lives_ok { $executor->oneRun(); } 'RemoveHost operation execution succeed';

    throws_ok { $host = Entity::Host->get(id => $host_id);} 
		'Kanopya::Exception::DB',
		"Host with id $host_id does not exist anymore";
    

    $db->txn_rollback;
};
if($@) {
	my $error = $@;
	print Dumper $error;
};

