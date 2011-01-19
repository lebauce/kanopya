#!/usr/bin/perl -w
use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Kanopya::Exceptions;


use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'/tmp/test.log', layout=>'%F %L %p %m%n'});

BEGIN{
    use_ok ('Administrator');
    use_ok ('Executor');
    use_ok('Entity::Cluster');
    use_ok('Entity::Motherboard');
    use_ok('Entity::Systemimage');
}
use Data::Dumper;
my $test_instantiation = "Instantiation test";

eval {
    Administrator::authenticate( login =>'admin', password => 'admin' );
    my @args = ();
    note ("Execution begin");
    my $executor = new_ok("Executor", \@args, "Instantiate an executor");

    # Test Motherboard Creation
    note( "Test Motherboard Creation");
    my $m1 = Entity::Motherboard->new(
	motherboard_mac_address => '00:00:00:00:00:11',
	kernel_id => 9,
	motherboard_serial_number => "Second Motherboard",
	motherboardmodel_id => 7,
	processormodel_id => 2);
    isa_ok($m1, "Entity::Motherboard", $test_instantiation);
    $m1->create();
    $executor->execnround(run => 1);
    my $m2 = Entity::Motherboard->getMotherboard(hash => {motherboard_mac_address => $m1->getAttr(name=>'motherboard_mac_address')});
    isa_ok($m2, "Entity::Motherboard", "Motherboard creation");

    # Test Systemimage creation
    note( "Test Systemimage creation");
    my $s1 = Entity::Systemimage->new(
		    systemimage_name => 'MySystemImageTest',
		    systemimage_desc => 'Testnowhitespace',
		    distribution_id => 1);
    isa_ok($s1, "Entity::Systemimage", $test_instantiation);
    $s1->create();
    $executor->execnround(run => 1);
    my $s2 = Entity::Systemimage->getSystemimage(hash => {systemimage_name => 'MySystemImageTest'});
    isa_ok($s2, "Entity::Systemimage", $test_instantiation);

    # Test Systemimage Activation
    note( "Test Systemimage activation");
    $s2->activate();
    $executor->execnround(run => 1);
    $s2 = Entity::Systemimage->get(id => $s2->getAttr(name=>'systemimage_id'));
    is ($s2->getAttr(name=>'active'), 1, "Test if SystemImage is active");

    # Test Cluster Creation
    note("Test Cluster Creation");
    my $c1 = Entity::Cluster->new(cluster_name => "foobar", 
                                  cluster_min_node => "1",
				  cluster_max_node => "2",
				  cluster_priority => "100",
				  systemimage_id => $s2->getAttr(name=>"systemimage_id"));

    isa_ok($c1, "Entity::Cluster", $test_instantiation);
    $c1->create();
    $executor->execnround(run => 1);
    my $c2 = Entity::Cluster->getCluster(hash => {'cluster_name'=>'foobar'});
    isa_ok($c2, "Entity::Cluster", "Cluster creation");

    # Test Cluster Activation
    note( "Test Cluster Activation");
    $c2->activate();
    $executor->execnround(run => 1);
    $c2 = Entity::Cluster->get(id => $c2->getAttr(name=>'cluster_id'));
    is ($c2->getAttr(name=>'active'), 1, "Activate Cluster");


    # Test Motherboard Activation
    note( "Test Motherboard Activation");
    $m2->activate();
    $executor->execnround(run => 1);
    $m2 = Entity::Motherboard->get(id => $m2->getAttr(name=>'motherboard_id'));
    is ($m2->getAttr(name=>'active'), 1, "Activate Motherboard");

    # Test Motherboard Migration
    note( "Test Motherboard Migration");
    $c2->addMotherboard(motherboard_id => $m2->getAttr(name => 'motherboard_id'));
    $executor->execnround(run => 1);

    # Test Motherboard Deactivation
    note( "Test Motherboard Deactivation");
    $m2->deactivate();
    $executor->execnround(run => 1);
    $m2 = Entity::Motherboard->get(id => $m2->getAttr(name=>'motherboard_id'));
    is ($m2->getAttr(name=>'active'), 0, "Deactivate Motherboard");


    # Test Cluster Deactivation
    note( "Test Cluster Deactivation");
    $c2->deactivate();
    $executor->execnround(run => 1);
    $c2 = Entity::Cluster->get(id => $c2->getAttr(name=>'cluster_id'));
    is ($c2->getAttr(name=>'active'), 0, "Deactivate Cluster");

    # Cluster delete
    $c2->delete();
    $m2->delete();
    throws_ok { $m2 = Entity::Motherboard->get(id => $m2->getAttr(name=>'motherboard_id'))} 'Kanopya::Exception::Internal',
    "Try to get a deleted motherboard";
    throws_ok { $c2 = Entity::Cluster->get(id => $c2->getAttr(name=>'motherboard_id'))} 'Kanopya::Exception::Internal',
      "Try to get a deleted Cluster";
  };
if($@) {
  my $error = $@;
  print Dumper $error;
};
