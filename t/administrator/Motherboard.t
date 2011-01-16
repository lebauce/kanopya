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
    Administrator::authenticate( login =>'admin', password => 'admin' );    
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
	motherboard_mac_address => '00:00:00:00:00:00', 
	kernel_id => 9, 
	motherboard_serial_number => "First Motherboard",
	motherboardmodel_id => 7,
	processormodel_id => 2,
	motherboard_toto => "testextended");
    my $m2 = Entity::Motherboard->new(	
	motherboard_mac_address => '00:00:00:00:00:11', 
	kernel_id => 9, 
	motherboard_serial_number => "Second Motherboard",
	motherboardmodel_id => 7,
	processormodel_id => 2);


    isa_ok($m1, "Entity::Motherboard", $test_instantiation);
    is ($m1->getAttr(name=>'motherboard_toto'), "testextended", 'Access to extended parameter from new motherboard');
    
    $m1->save();
#    $m2->save();
    # Test cluster->get
    note( "Test Motherboard management");
    $m1->activate();
    $executor->execnround(run => 1);
    my $clone_m1 = Entity::Motherboard->get(id => $m1->getAttr(name=>'motherboard_id'));
    is ($clone_m1->getAttr(name=>'motherboard_toto'), "testextended", "Get extended attr from a motherboard load from db");
    is ($clone_m1->getAttr(name=>'active'), 1, "Test if Motherboard is active");
    $m1->activate();
    throws_ok { $executor->execnround(run => 1) } 'Kanopya::Exception::Internal',
    "Activate a second time same motherboard";
    $m1->deactivate();
    $executor->execnround(run => 1);
    is ($m1->getAttr(name=>'active'), undef, "Deactivate Motherboard");
    $m1->delete();
    throws_ok { $clone_m1 = Entity::Motherboard->get(id => $m1->getAttr(name=>'motherboard_id'))} 'Kanopya::Exception::Internal',
    "Try to get a deleted motherboard";

# Ici probleme d instanciation d une meme row dans 2 entity et suppression de l une d elle.
#    note("Cluster deleted");
#    $c2->setAttr(name => "cluster_desc", value => "New descrition");
#    is($c2->getAttr(name => 'systemimage_id'), 1,  "Test getAttr from an entity removed from db");
#    print "cluster is changed : " . $c2->{_dbix}->is_changed() . "\n";
#    print "cluster is in storage : " . $c2->{_dbix}->in_storage() . "\n";
#    $c2->save();




#    my $cluster = Entity::Cluster->get(id => "1");
#    print "Admin cluster has a id : <" . $cluster->getAttr(name => "cluster_id") . ">\n";
#    my $cluster2 = Entity::Cluster->new(cluster_name => "toto", cluster_min_node => "1", cluster_max_node => "2", cluster_priority => "100", systemimage_id => "1");
#    print "New cluster has a name : <" . $cluster2->getAttr(name => "cluster_name") . ">\n";
#    $cluster2->save();
 #   print "New cluster has a name : <" . $cluster2->getAttr(name => "cluster_name") . "> and its id is". $cluster2->getAttr(name => "cluster_id") ."\n";
#    $cluster2->addComponent(component_id=>2);
#    my $comp_instance = $cluster2->getComponent(name=>"Apache", version=>2);
#    print "component instance added, its id is " . $comp_instance->getAttr(name => "component_instance_id") . " and its component id is " . $comp_instance->getAttr(name => "component_id") . "\n";
#    note("Test Cluster.pm pod");
#    pod_file_ok( '/opt/kanopya/lib/administrator/Entity/Cluster.pm', 'stuff docs are valid POD' );

};
if($@) {
	my $error = $@;	
	print Dumper $error;
};

