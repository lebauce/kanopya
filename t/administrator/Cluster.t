#!/usr/bin/perl -w
use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Kanopya::Exceptions;


use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'/tmp/test.log', layout=>'%F %L %p %m%n'});

use_ok ('Administrator');
use_ok ('Executor');
use_ok('Entity::Cluster');
use Data::Dumper;
my $test_instantiation = "Instantiation test";

eval {
    Administrator::authenticate( login =>'admin', password => 'admin' );
    my @args = ();
    note ("Execution begin");
    my $executor = new_ok("Executor", \@args, "Instantiate an executor");
    # Test bad structure cluster
    note("Test Instanciation Error");

    throws_ok { Entity::Cluster->new(cluster_name => "foo\nbar",
        cluster_min_node => "1",
        cluster_max_node => "2",
        cluster_priority => "100",
        systemimage_id => "1") } qr/checkAttrs detect a wrong value/,
        $test_instantiation;
    throws_ok { Entity::Cluster->new(cluster_name => "foobar",
                                                         cluster_min_node => "1q",
                                                         cluster_max_node => "2",
                                                         cluster_priority => "100",
                                                         systemimage_id => "1") } 'Kanopya::Exception::Internal::WrongValue',
                        $test_instantiation;

    ########################### Test cluster extended
    note("Test Cluster extended");
    my $c1 = Entity::Cluster->new(cluster_name => "foobar", 
                                                       cluster_min_node => "1",
                                                       cluster_max_node => "2",
                                                       cluster_priority => "100",
                                                       systemimage_id => "1",
                                                       cluster_toto => "testextended");
    isa_ok($c1, "Entity::Cluster", $test_instantiation);
    is ($c1->getAttr(name=>'cluster_toto'), "testextended", 'Access to extended parameter from new cluster');
    $c1->create();
    $executor->execnround(run => 1);

    # Test cluster->get
    my $c2 = Entity::Cluster->getCluster(hash => {'cluster_name'=>'foobar'});
    is ($c2->getAttr(name=>'cluster_toto'), "testextended", "Get extended attr from a cluster load from db");

    # Test Cluster Activate
    note( "Test Cluster management");
    $c2->activate();
    $executor->execnround(run => 1);
    print "NEW CLUSTER ADDED With ID : <" . $c2->getAttr(name=>'cluster_id') .">\n";
    $c2 = Entity::Cluster->get(id => $c2->getAttr(name=>'cluster_id'));
    is ($c2->getAttr(name=>'active'), 1, "Test if cluster is active");

    # Test Cluster activate error
    $c2->activate();
    throws_ok { $executor->execnround(run => 1) } 'Kanopya::Exception::Internal',
    "Activate a second time same cluster";

    # Test Cluster Deactivate
    $c2->deactivate();
    $executor->execnround(run => 1);
    $c2 = Entity::Cluster->get(id => $c2->getAttr(name=>'cluster_id'));
    is ($c2->getAttr(name=>'active'), 0, "Deactivate Cluster");

    # Cluster delete
    $c2->delete();
    throws_ok { $c2 = Entity::Cluster->get(id => $c2->getAttr(name=>'cluster_id'))} 'Kanopya::Exception::Internal',
    "Try to get a deleted cluster";


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

