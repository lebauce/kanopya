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
    Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
    my @args = ();
    note ("Execution begin");
    my $executor = new_ok("Executor", \@args, "Instantiate an executor");
    # Test bad structure cluster
    note("Test Instanciation Error");
    #  
    throws_ok { Entity::Cluster->new(cluster_name => "foo\nbar",
        cluster_min_node => "1",
        cluster_max_node => "2",
        cluster_priority => "100",
        systemimage_id => "1") } qr/checkAttrs detect a wrong value/,
        $test_instantiation;
    throws_ok { Entity::Cluster->new(cluster_name => "foobar",
                                                         cluster_min_node       => "1",
                                                         cluster_max_node       => "3",
                                                         cluster_priority       => "100",
                                                         cluster_si_access_mode => 'ro',
                                                         cluster_si_location    => 'diskless',
                                                         cluster_domainname     => 'my.domain',
                                                         cluster_nameserver     => '127.0.0.1',
                                                         cluster_basehostname   =>'test_',
                                                         cluster_si_shared      => '1',
                                                         systemimage_id         => "1") } 'Kanopya::Exception::Internal::WrongValue',
                        $test_instantiation;

    ########################### Test cluster extended
    note("Test Cluster extended");
 throws_ok {my $c1 = Entity::Cluster->new(cluster_name => "foobar", 
				  cluster_min_node       => "1",
				  cluster_max_node       => "2",
				  cluster_priority       => "100",
				  cluster_nameserver     => '127.0.0.1',
				  cluster_si_access_mode => 'ro',
				  cluster_si_location    => 'diskless',
				  cluster_domainname     => 'my.domain',
				  cluster_si_shared      => '1',
				  cluster_basehostname   =>'test_',
				  systemimage_id         => "1",)} 'Kanopya::Exception::Internal::WrongValue',
    $test_instantiation;       
throws_ok {my $c2 = Entity::Cluster->new(cluster_name => "foobar", 
				    cluster_min_node                  => "1",
				    cluster_max_node                  => "2",
				    cluster_priority                  => "100",
				    cluster_nameserver                => '127.0.0.1',
				    cluster_si_access_mode            => 'ro',
				    cluster_si_location               => 'diskless',
				    cluster_domainname                => 'my.domain',
				    cluster_si_shared                 => '1',
				    cluster_basehostname              =>'test',
				    systemimage_id                    => "1",)} 'Kanopya::Exception::Internal::WrongValue',
    $test_instantiation;   
    note("Test Cluster basehostname");
    my $cluster_basehostname = $c1->getAttr(name=>'cluster_basehostname');
	is  ($cluster_basehostname, 'test', 'cluster_basehostname');       
    isa_ok($c1, "Entity::Cluster", $test_instantiation);
    is($c1->getAttr(name=>'cluster_toto'), "testextended", 'Access to extended parameter from new cluster');
    lives_ok { $c1->create(); } 'AddCluster operation enqueue';
    lives_ok { $executor->execnround(run => 1); } 'AddCluster operation execution succeed';
  # Test cluster->get
    my $c2 = Entity::Cluster->getCluster(hash => {'cluster_name'=>'foobare'});
    isa_ok($c2,Entity::Cluster,"l\'objet est bien un cluster");
    is ($c2->getAttr(name=>'cluster_toto'), "testextended", "Get extended attr from a cluster load from db");
    # Test Cluster Activate
    note( "Test Cluster management");
    $c2->activate();
    $executor->execnround(run => 1);
    print "NEW CLUSTER ADDED With ID : <" . $c2->getAttr(name=>'cluster_id') .">\n";
    #$c2 = Entity::Cluster->get(id => $c2->getAttr(name=>'cluster_id'));
    is ($c2->getAttr(name=>'active'), 1, "Test if cluster is active");

    # Test Cluster activate error
    $c2->activate();
    throws_ok { $executor->execnround(run => 1) } 'Kanopya::Exception::Internal',
    "Activate a second time same cluster";
     #Test Cluster systeme image
    pass($c2->getSystemImage());
     $executor->execnround(run => 1);
     $c2 = Entity::Cluster->get(id => $c2->getAttr(name=>'cluster_id')); 
    pass ($c2->getAttr(name=>'systemimage_id'));
     
   #Test Start Cluster
    note ("test start cluster");
    pass($c2->start());

    my ($state, $timestamp) = $c2->getState();
    
    $executor->execnround(run => 1);
    $c2 = Entity::Cluster->get(id => $c2->getAttr(name=>'cluster_id'));
    is ($c2->getAttr(name=> 'cluster_state'),'up', "Cluster up");
    #Test Cluster start error
    $c2->start();
    throws_ok { $executor->execnround(run => 1) } 'Kanopya::Exception::Internal',
    "Activate a second time same cluster";    
     
   #Test Cluster down
    note("stop cluster");
    pass($c2->stop());
    $executor->execnround(run => 1);
    throws_ok { $c2 = Entity::Cluster->get(id => $c2->getAttr(name=>'cluster_id'))} 'Kanopya::Exception::Internal', 
    "Stop cluster";
    
    # Test Cluster Dsactivate
    $c2->deactivate();
    $executor->execnround(run => 1);
    $c2 = Entity::Cluster->get(id => $c2->getAttr(name=>'cluster_id'));
    is ($c2->getAttr(name=>'active'),0, "Deactivate Cluster");
 
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

