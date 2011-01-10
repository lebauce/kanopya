#!/usr/bin/perl -w
use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use McsExceptions;


use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'/tmp/test.log', layout=>'%F %L %p %m%n'});

use_ok ('Administrator');
use_ok('Entity::Cluster');
use Data::Dumper;


eval {
    Administrator::authenticate( login =>'admin', password => 'admin' );    
    note("Test Instanciation");
    throws_ok { Entity::Cluster->new(cluster_name => "foo\nbar", 
				     cluster_min_node => "1", 
				     cluster_max_node => "2", 
				     cluster_priority => "100", 
				     systemimage_id => "1") } qr/checkAttrs detect a wrong value/, 
    'Exception bad cluster name';
    throws_ok { Entity::Cluster->new(cluster_name => "foobar", 
				     cluster_min_node => "1q", 
				     cluster_max_node => "2", 
				     cluster_priority => "100", 
				     systemimage_id => "1") } 'Mcs::Exception::Internal::WrongValue',
    'Exception bad node number';
    

    note( "Test Cluster management");


#    my $cluster = Entity::Cluster->get(id => "1");
#    print "Admin cluster has a id : <" . $cluster->getAttr(name => "cluster_id") . ">\n";
#    my $cluster2 = Entity::Cluster->new(cluster_name => "toto", cluster_min_node => "1", cluster_max_node => "2", cluster_priority => "100", systemimage_id => "1");
#    print "New cluster has a name : <" . $cluster2->getAttr(name => "cluster_name") . ">\n";
#    $cluster2->save();
#    print "New cluster has a name : <" . $cluster2->getAttr(name => "cluster_name") . "> and its id is". $cluster2->getAttr(name => "cluster_id") ."\n";
#    $cluster2->addComponent(component_id=>2);
#    my $comp_instance = $cluster2->getComponent(name=>"Apache", version=>2);
#    print "component instance added, its id is " . $comp_instance->getAttr(name => "component_instance_id") . " and its component id is " . $comp_instance->getAttr(name => "component_id") . "\n";
    note("Test Cluster.pm pod");
    pod_file_ok( '/opt/kanopya/lib/administrator/Entity/Cluster.pm', 'stuff docs are valid POD' );

};
if($@) {
	my $error = $@;	
	print Dumper $error;
};

