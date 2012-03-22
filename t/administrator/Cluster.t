#!/usr/bin/perl -w
use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Kanopya::Exceptions;


use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'/tmp/Cluster.t.log', layout=>'%F %L %p %m%n'});

use_ok ('Administrator');
use_ok ('Executor');
use_ok('Entity::ServiceProvider::Inside::Cluster');
use_ok('Entity::User');


eval {
    Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
    my $adm = Administrator->new;
    my $db = $adm->{db};
    
    my @args = ();
    my $executor = new_ok("Executor", \@args, "Instantiate an executor");

    $db->txn_begin;

    my ($kanopya_cluster, $physical_hoster, $lvm_component, $iscsi_component);
    lives_ok {
		$kanopya_cluster = Entity::ServiceProvider::Inside::Cluster->find(
                               hash => {
                                   cluster_name => 'Kanopya'
                               }
                           );
        $physical_hoster = $kanopya_cluster->getDefaultManager(category => 'HostManager');
        $lvm_component   = $kanopya_cluster->getDefaultManager(category => 'DiskManager');
        $iscsi_component = $kanopya_cluster->getDefaultManager(category => 'ExportManager');
     } 'Retrieve the Kanopya cluster';

    isa_ok ($kanopya_cluster, 'Entity::ServiceProvider::Inside::Cluster');
    isa_ok ($physical_hoster, 'Entity::Component::Physicalhoster0');

    my $admin_user;
    lives_ok {
		$admin_user = Entity::User->find(hash => { user_login => 'admin' });
     } 'Retrieve the admin user';

    throws_ok {
		Entity::ServiceProvider::Inside::Cluster->create(
			cluster_name     => 'foo/bar',
			cluster_min_node => '1',
			cluster_max_node => '2',
			cluster_priority => '100',
			masterimage_id   => '1'
		);
     } 'Kanopya::Exception::Internal::WrongValue',
		'bad attribute value';
    
    throws_ok {
		Entity::ServiceProvider::Inside::Cluster->create(
			#cluster_name           => "foobar",
			cluster_min_node       => "1",
			cluster_max_node       => "3",
			cluster_priority       => "100",
			cluster_boot_policy    => 'best_policy',
			cluster_domainname     => 'my.domain',
			cluster_nameserver1    => '127.0.0.1',
            cluster_nameserver2    => '127.0.0.1',
			cluster_basehostname   => 'test_',
			cluster_si_shared      => '1',
			masterimage_id         => "1"
		); 
	} 'Kanopya::Exception::Internal::IncorrectParam',
	  'missing mandatory attribute';

	lives_ok {
		Entity::ServiceProvider::Inside::Cluster->create(
			cluster_name           => "foobar",
			cluster_min_node       => "1",
			cluster_max_node       => "3",
			cluster_priority       => "100",
			cluster_boot_policy    => 'best_policy',
			cluster_domainname     => 'my.domain',
			cluster_nameserver1    => '127.0.0.1',
            cluster_nameserver2    => '127.0.0.1',
			cluster_basehostname   =>'test_',
			cluster_si_shared      => '1',
			masterimage_id         => "1",
            user_id                => $admin_user->getAttr(name => 'user_id'),
            host_manager_id        => $physical_hoster->getAttr(name => 'component_id'),
            disk_manager_id        => $lvm_component->getAttr(name => 'component_id'),
            export_manager_id      => $iscsi_component->getAttr(name => 'component_id'),
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
	
	lives_ok { $cluster_id = $cluster->getAttr(name=>'cluster_id')} 'get Attribute cluster_id';
	
	isnt($cluster_id, undef, "cluster_id is defined ($cluster_id)");

	lives_ok { $executor->oneRun(); } 'AddHost operation execution succeed';

	lives_ok { $cluster->remove; } 'RemoveCluster operation enqueue';
    lives_ok { $executor->oneRun; } 'RemoveCluster operation execution succeed';
    
    throws_ok { $cluster = Entity::ServiceProvider::Inside::Cluster->get(id => $cluster_id);} 
		'Kanopya::Exception::DB',
		"Cluster with id $cluster_id does not exist anymore";

    $db->txn_rollback; 

};
if($@) {
	my $error = $@;
	print $error."\n";
};

