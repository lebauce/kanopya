#!/usr/bin/perl -w

use lib qw (/workspace/mcs/Administrator/Lib /workspace/mcs/Common/Lib);
#use FindBin qw($Bin);
#use lib "$Bin/../Lib", "$Bin/../../Common/Lib";
#use lib qw(../Lib ../../Common/Lib);

use McsExceptions;


use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'STDOUT', layout=>'%F %L %p %m%n'});

use Test::More 'no_plan';
use Administrator;
use Entity::Cluster;
use Data::Dumper;

note( "Test Cluster management");

eval {
    Administrator::authenticate( login =>'admin', password => 'admin' );
    my $cluster = Entity::Cluster->get(id => "1");
    print "Admin cluster has a id : <" . $cluster->getAttr(name => "cluster_id") . ">\n";
    my $cluster2 = Entity::Cluster->new(cluster_name => "toto", cluster_min_node => "1", cluster_max_node => "2", cluster_priority => "100", systemimage_id => "1");
    print "New cluster has a name : <" . $cluster2->getAttr(name => "cluster_name") . ">\n";
    $cluster2->save();
    print "New cluster has a name : <" . $cluster2->getAttr(name => "cluster_name") . "> and its id is". $cluster2->getAttr(name => "cluster_id") ."\n";
    $cluster2->addComponent(component_id=>2);
    my $comp_instance = $cluster2->getComponent(name=>"Apache", version=>2);
    print "component instance added, its id is " . $comp_instance->getAttr(name => "component_instance_id") . " and its component id is " . $comp_instance->getAttr(name => "component_id") . "\n";
};
if($@) {
	my $error = $@;	
	print Dumper $error;
};

