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


my $test_instantiation = "Instantiation test";

eval {
#    BEGIN { $ENV{DBIC_TRACE} = 1 }
    Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
    my @args = ();
    note ("Execution begin");
    my $executor = new_ok("Executor", \@args, "Instantiate an executor");

    # Test bad structure cluster
    note("Test Instanciation Error");
    throws_ok { Entity::Host->new(
		    host_mac_address => '70:71tbc:6c:2d:b1',
		    kernel_id => 1,
		    host_serial_number => "Wrong Mac",
		    hostmodel_id => 7,
		    processormodel_id => 2) } qr/checkAttrs detect a wrong value/,
    $test_instantiation;

    ########################### Test cluster extended
    note("Test Host extended");
    my $m1 = Entity::Host->new(
	host_mac_address => '00:00:00:00:00:11',
	kernel_id => 1,
	host_serial_number => "First Host",
	hostmodel_id => 8,
	processormodel_id => 8,
	host_toto => "testextended");

    my $m2 = Entity::Host->new(
	host_mac_address => '00:00:00:00:00:00',
	kernel_id => 1,
	host_serial_number => "Second Host",
	hostmodel_id => 8,
	processormodel_id => 8);


    isa_ok($m1, "Entity::Host", $test_instantiation);
    isa_ok($m2, "Entity::Host", $test_instantiation);

    is ($m1->getAttr(name=>'host_toto'), "testextended", 'Access to extended parameter from new host');

    my $mac_addr = $m1->getAttr(name=>'host_mac_address');
    is ($mac_addr, '00:00:00:00:00:11', "Get mac address from extended host");
    note( "Test Host Creation");
    $m1->create();
    $executor->execnround(run => 1);


#    note( "Test Host Creation");
#    $m2->create();
#    $executor->execnround(run => 1);

    note( "Test Host extended field");
    my $clone_m1 = Entity::Host->getHost(hash => {host_mac_address => $mac_addr});
    isa_ok($clone_m1,Entity::Host,"Host extended object");
    is ($clone_m1->getAttr(name=>'host_toto'), "testextended", "Get extended attr from a host load from db");


    note( "Test Host activation");
    $clone_m1->activate();
    $executor->execnround(run => 1);

    note( "Test Host activation error");
    $clone_m1 = Entity::Host->get(id => $clone_m1->getAttr(name=>'host_id'));
    is ($clone_m1->getAttr(name=>'active'), 1, "Test if Host is active");

# We could not get exception in execnrun, because all exceptions are catched by oneRun
#    $clone_m1->activate();
#    throws_ok { $executor->execnround(run => 1) } 'Kanopya::Exception::Internal',
#    "Activate a second time same host";

    $clone_m1 = Entity::Host->get(id => $clone_m1->getAttr(name=>'host_id'));
    $clone_m1->deactivate();
    $executor->execnround(run => 1);
    $clone_m1 = Entity::Host->get(id => $clone_m1->getAttr(name=>'host_id'));
    is ($clone_m1->getAttr(name=>'active'), 0, "Deactivate Host");


    $clone_m1->remove();
    $executor->execnround(run => 1);
    throws_ok { $clone_m1 = Entity::Host->get(id => $clone_m1->getAttr(name=>'host_id'))} 'Kanopya::Exception::Internal',
    "Try to get a deleted host";

    note("Test Host.pm pod");
    pod_file_ok( '/opt/kanopya/lib/administrator/Entity/Host.pm', 'stuff docs are valid POD' );

};
if($@) {
	my $error = $@;
	print Dumper $error;
};

