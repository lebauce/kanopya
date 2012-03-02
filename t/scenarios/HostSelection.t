#!/usr/bin/perl -w
use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Kanopya::Exceptions;


use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'/tmp/HostSelection.t.log', layout=>'%F %L %p %m%n'});

use_ok ('Administrator');
use_ok ('Executor');
use_ok ('Entity::ServiceProvider::Inside::Cluster');
use_ok ('Entity::User');
use_ok ('Entity::Host');
use_ok ('Entity::Kernel');
use_ok ('Entity::Processormodel');
use_ok ('Entity::Hostmodel');

eval {
    Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
    my $adm = Administrator->new;
    my $db = $adm->{db};
    
    my @args = ();
    my $executor = new_ok("Executor", \@args, "Instantiate an executor");

    $db->txn_begin;

    my $hostmodel;
	lives_ok {
		$hostmodel = Entity::Hostmodel->find(hash => {});
	} 'Get an existing host model';

    my $kanopya_cluster;
    my $physical_hoster;
    lives_ok {
		$kanopya_cluster = Entity::ServiceProvider::Inside::Cluster->find(
                               hash => {
                                   cluster_name => 'adm'
                               }
                           );
        $physical_hoster = $kanopya_cluster->getDefaultManager(category => 'HostManager');
     } 'Retrieve the admin cluster';

    isa_ok ($kanopya_cluster, 'Entity::ServiceProvider::Inside::Cluster');
    isa_ok ($physical_hoster, 'Entity::Component::Physicalhoster0');

    my $kernel;
	lives_ok {
		$kernel = Entity::Kernel->find(hash => {});
	} 'Get an existing kernel';

    my $processormodel;
	lives_ok {
		$processormodel = Entity::Processormodel->find(hash => {});
	} 'Get an existing processeur model';

	lives_ok {
		$physical_hoster->createHost(
			host_mac_address   => '00:00:00:00:00:00',
			kernel_id          => $kernel->getAttr(name => 'kernel_id'),
			host_serial_number => 'serial',
			hostmodel_id       => $hostmodel->getAttr(name => 'hostmodel_id'),
			processormodel_id  => $processormodel->getAttr(name => 'processormodel_id'),
			host_ram           => 536870912,
			host_core          => 1
		);
	} 'AddHost operation enqueue from PhysicalHoster';
	
	lives_ok { $executor->oneRun(); } 'AddHost operation execution succeed';

	my ($host, $host_id);
	lives_ok { 
		$host = Entity::Host->getHost(hash => {host_mac_address => '00:00:00:00:00:00'});
	} 'retrieve Host via mac address';

	isa_ok($host, 'Entity::Host');

    lives_ok { $host_id = $host->getAttr(name => 'host_id') } 'get Attribute host_id';

	lives_ok { $host->activate; } 'ActivateHost operation enqueue';
	lives_ok { $executor->oneRun(); } 'ActivateHost operation execution succeed';

    my $admin_user;
    lives_ok {
		$admin_user = Entity::User->find(hash => { user_login => 'admin' });
     } 'Retrieve the admin user';

	lives_ok {
		Entity::ServiceProvider::Inside::Cluster->create(
			cluster_name           => "foobar",
			cluster_min_node       => "1",
			cluster_max_node       => "3",
			cluster_priority       => "100",
			cluster_si_access_mode => 'ro',
			cluster_si_location    => 'diskless',
			cluster_domainname     => 'my.domain',
			cluster_nameserver     => '127.0.0.1',
			cluster_basehostname   =>'test_',
			cluster_si_shared      => '1',
            user_id                => $admin_user->getAttr(name => 'user_id'),
            host_manager_id        => $physical_hoster->getAttr(name => 'component_id')
		);
	} 'AddCluster operation enqueue';

    lives_ok { $executor->oneRun; } 'AddCluster operation execution succeed';

    my ($cluster, $cluster_id);
	lives_ok {
		$cluster = Entity::ServiceProvider::Inside::Cluster->getCluster(
                       hash => { cluster_name => 'foobar'}
                   );
	} 'retrieve Cluster via name';

    isa_ok($cluster, 'Entity::ServiceProvider::Inside::Cluster'); 	
	
	lives_ok {
        $cluster_id = $cluster->getAttr(name => 'cluster_id');
    } 'get Attribute cluster_id';

	lives_ok {
		$cluster->start();
	} 'Start cluster, PreStartNode operation enqueue.';

    lives_ok { $executor->oneRun; } 'PreStartNode operation execution succeed';

	lives_ok { 
		$host = Entity::Host->get(id => $host_id);
	} 'Retrieve Host from id after addNode';

    my ($state, $timestemp) = $cluster->getState;
    cmp_ok ($state, 'eq', 'starting', "Cluster is 'starting'");

    ($state, $timestemp) = $host->getNodeState;
    cmp_ok ($state, 'eq', 'pregoingin', "Host node state is 'pregoingin'");

    ($state, $timestemp) = $host->getState;
    cmp_ok ($state, 'eq', 'locked', "Host is 'locked'");

    lives_ok {
        $cluster->forceStop;
    } 'force stop cluster, ForceStopCluster operation enqueue';

    lives_ok { $executor->oneRun; } 'ForceStopCluster operation execution succeed';

	lives_ok { 
		$cluster = Entity::ServiceProvider->get(id => $cluster_id);
	} 'Retrieve Cluster from id after forceStopCluster';

    ($state, $timestemp) = $cluster->getState;
    cmp_ok ($state, 'eq', 'down', "Cluster is 'down'");

	lives_ok {
		$host = Entity::Host->get(id => $host_id);
	} 'Retrieve Host from id after forceStopCluster';

    ($state, $timestemp) = $host->getState;
    cmp_ok ($state, 'eq', 'down', "Host is 'down'");

	lives_ok { $cluster->remove; } 'RemoveCluster operation enqueue';
    lives_ok { $executor->oneRun; } 'RemoveCluster operation execution succeed';

    throws_ok {
        $cluster = Entity::ServiceProvider::Inside::Cluster->get(id => $cluster_id);
    } 
    'Kanopya::Exception::DB',
    "Cluster with id $cluster_id does not exist anymore";

    lives_ok { $host->deactivate; } 'DeactivateHost operation enqueue';

    lives_ok { $executor->oneRun(); } 'DeactivateHost operation execution succeed';

    lives_ok { $host->remove; } 'RemoveHost operation enqueue';

    lives_ok { $executor->oneRun(); } 'RemoveHost operation execution succeed';

    throws_ok {
        $host = Entity::Host->get(id => $host_id);
    } 
    'Kanopya::Exception::DB',
    "Cluster with id $cluster_id does not exist anymore";

    $db->txn_rollback; 

};
if($@) {
	my $error = $@;
	print $error."\n";
};

