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
use_ok('Entity::Motherboard');


my $test_instantiation = "Instantiation test";

eval {
    Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
    my @args = ();
    note ("Execution begin");
    my $executor = new_ok("Executor", \@args, "Instantiate an executor");

    # Test bad structure cluster
    note("Test Instanciation Error");
    throws_ok { Entity::Motherboard->new(
		    motherboard_mac_address => '70:71tbc:6c:2d:b1',
		    kernel_id => 9,
		    motherboard_serial_number => "Wrong Mac",
		    motherboardmodel_id => 7,
		    processormodel_id => 2) } qr/checkAttrs detect a wrong value/,
    $test_instantiation;

    ########################### Test cluster extended
    note("Test Motherboard extended");
    my $m1 = Entity::Motherboard->new(
	motherboard_mac_address => '00:00:00:00:00:11',
	kernel_id => 1,
	motherboard_serial_number => "First Motherboard",
	motherboardmodel_id => 8,
	processormodel_id => 8,
	motherboard_toto => "testextended");
    
    my $m2 = Entity::Motherboard->new(
	motherboard_mac_address => '00:00:00:00:00:00',
	kernel_id => 1,
	motherboard_serial_number => "Second Motherboard",
	motherboardmodel_id => 8,
	processormodel_id => 8);


    isa_ok($m1, "Entity::Motherboard", $test_instantiation);
    isa_ok($m2, "Entity::Motherboard", $test_instantiation);
    
    is ($m1->getAttr(name=>'motherboard_toto'), "testextended", 'Access to extended parameter from new motherboard');
    
    my $mac_addr = $m1->getAttr(name=>'motherboard_mac_address'); 
    is ($mac_addr, '00:00:00:00:00:11');
    note( "Test Motherboard Creation");
    pass($m1->create());
    pass ($executor->execnround(run => 1));
   
      
    note( "Test Motherboard Creation");
    $m1->create();
    $executor->execnround(run => 1);
    
    note( "Test Motherboard extended field");
    my $clone_m1 = Entity::Motherboard->getMotherboard(hash => {motherboard_mac_address => $mac_addr});
    isa_ok($clone_m1,Entity::Motherboard,"Motherboard extended object");
    is ($clone_m1->getAttr(name=>'motherboard_toto'), "testextended", "Get extended attr from a motherboard load from db");


    note( "Test Motherboard activation");
    $clone_m1->activate();
    $executor->execnround(run => 1);

    note( "Test Motherboard activation error");
    $clone_m1 = Entity::Motherboard->get(id => $clone_m1->getAttr(name=>'motherboard_id'));
    is ($clone_m1->getAttr(name=>'active'), 1, "Test if Motherboard is active");
    $clone_m1->activate();
    throws_ok { $executor->execnround(run => 1) } 'Kanopya::Exception::Internal',
    "Activate a second time same motherboard";

    $clone_m1 = Entity::Motherboard->get(id => $clone_m1->getAttr(name=>'motherboard_id'));
    $clone_m1->deactivate();
    $executor->execnround(run => 1);
    $clone_m1 = Entity::Motherboard->get(id => $clone_m1->getAttr(name=>'motherboard_id'));
    is ($clone_m1->getAttr(name=>'active'), 0, "Deactivate Motherboard");


    $clone_m1->remove();
    $executor->execnround(run => 1);
    throws_ok { $clone_m1 = Entity::Motherboard->get(id => $clone_m1->getAttr(name=>'motherboard_id'))} 'Kanopya::Exception::Internal',
    "Try to get a deleted motherboard";

    note("Test Motherboard.pm pod");
    pod_file_ok( '/opt/kanopya/lib/administrator/Entity/Motherboard.pm', 'stuff docs are valid POD' );

};
if($@) {
	my $error = $@;
	print Dumper $error;
};

