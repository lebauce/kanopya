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
    $c2->remove();
    $executor->execnround(run => 1); 
    throws_ok { $c2 = Entity::Cluster->get(id => $c2->getAttr(name=>'cluster_id'))} 'Kanopya::Exception::Internal',
    "Try to get a deleted cluster";
    note("Test Cluster.pm pod");
    pod_file_ok( '/opt/kanopya/lib/administrator/Entity/Cluster.pm', 'stuff docs are valid POD' );

};
if($@) {
	my $error = $@;
	print Dumper $error;
};

