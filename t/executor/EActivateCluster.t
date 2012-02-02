#!/usr/bin/perl -w
use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Kanopya::Exceptions;


use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'/tmp/test.log', layout=>'%F %L %p %m%n'});

use_ok ('Administrator');
use_ok('Entity::ServiceProvider::Inside::Cluster');
use_ok('Executor');
use Data::Dumper;
my $test_instantiation = "Instantiation test";

eval {
    Administrator::authenticate( login =>'admin', password => 'admin' );    
    
    ########################### Test cluster extended
    note("Test Cluster extended");
    my $c1 = Entity::ServiceProvider::Inside::Cluster->new(cluster_name => "foobar", 
			 cluster_min_node => "1", 
			 cluster_max_node => "2", 
			 cluster_priority => "100", 
			 systemimage_id => "1");
    isa_ok($c1, "Entity::ServiceProvider::Inside::Cluster", $test_instantiation);
    $c1->save();
    # Test cluster->get
    note( "Test Cluster management");
    $c1->activate();
    
    

# Ici probleme d instanciation d une meme row dans 2 entity et suppression de l une d elle.
#    note("Cluster deleted");
#    $c2->setAttr(name => "cluster_desc", value => "New descrition");
#    is($c2->getAttr(name => 'systemimage_id'), 1,  "Test getAttr from an entity removed from db");
#    print "cluster is changed : " . $c2->{_dbix}->is_changed() . "\n";
#    print "cluster is in storage : " . $c2->{_dbix}->in_storage() . "\n";
#    $c2->save();




#    my $cluster = Entity::ServiceProvider::Inside::Cluster->get(id => "1");
#    print "Admin cluster has a id : <" . $cluster->getAttr(name => "cluster_id") . ">\n";
#    my $cluster2 = Entity::ServiceProvider::Inside::Cluster->new(cluster_name => "toto", cluster_min_node => "1", cluster_max_node => "2", cluster_priority => "100", systemimage_id => "1");
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

