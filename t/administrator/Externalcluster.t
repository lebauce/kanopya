#!/usr/bin/perl -w
use Test::More 'no_plan';
use Test::Exception;
use Kanopya::Exceptions;
use Data::Dumper;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'STDOUT', layout=>'%F %L %p %m%n'});

use_ok ('Administrator');
use_ok('Entity::ServiceProvider::Outside::Externalcluster');
use_ok('Entity::Connector::ActiveDirectory');


eval {
    Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
    
#    Entity::ServiceProvider::Outside::Externalcluster->new(
#            externalcluster_name           => "foobar",
#        );
#        
    my @clusters = Entity::ServiceProvider::Outside::Externalcluster->search(hash => {externalcluster_name => "foobar"});
    my $cluster = pop @clusters;
#    $cluster->addNode(hostname => "tutu");
#    $cluster->addNode(hostname => "titi");
    
    my $nodes = $cluster->getNodes();
    
    print Dumper $nodes;
    
    
    
    my $ad_connector = Entity::Connector::ActiveDirectory->new( ad_host => "HOST");
    
    my $connector_id = $cluster->addConnector(connector => $ad_connector);
    
    print "==> $connector_id\n";
    
#    $cluster->delete;


#
#    lives_ok { $executor->execnround(run => 1); } 'AddCluster operation execution succeed';
#
#    my ($cluster, $cluster_id);
#    lives_ok { 
#        $cluster = Entity::ServiceProvider::Inside::Cluster->getCluster(hash => {cluster_name => 'foobar'});
#    } 'retrieve Cluster via name';
#
#    isa_ok($cluster, 'Entity::ServiceProvider::Inside::Cluster');     
#    
#    lives_ok { $cluster_id = $cluster->getAttr(name=>'cluster_id')} 'get Attribute cluster_id';
#    
#    isnt($cluster_id, undef, "cluster_id is defined ($cluster_id)");
#
#    lives_ok { $cluster->remove; } 'RemoveCluster operation enqueue';
#    lives_ok { $executor->execnround(run => 1); } 'RemoveCluster operation execution succeed';
#    
#    throws_ok { $cluster = Entity::ServiceProvider::Inside::Cluster->get(id => $cluster_id);} 
#        'Kanopya::Exception::DB',
#        "Cluster with id $cluster_id does not exist anymore";
    

};
if($@) {
    my $error = $@;
    print $error."\n";
};

