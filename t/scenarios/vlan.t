#!/usr/bin/perl -w

use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;

use Log::Log4perl qw(:easy get_logger);
Log::Log4perl->easy_init({
    level=>'DEBUG',
    file=>'/vagrant/Vlan.t.log',
    layout=>'%F %L %p %m%n'
});

use_ok ('Administrator');
use_ok ('Executor');
use_ok ('NetconfVlan');
use_ok ('Entity::Vlan');
use_ok ('Entity::ServiceProvider::Inside::Cluster');
use_ok ('Entity::User');
use_ok ('Entity::Host');
use_ok ('Entity::Kernel');
use_ok ('Entity::Processormodel');
use_ok ('Entity::Hostmodel');
use_ok ('Entity::Masterimage');
use_ok ('Entity::Network');
use_ok ('Entity::Poolip');
use_ok ('Entity::Operation');
use_ok ('Entity::Netconf');
use_ok ('Entity::Iface');
use_ok ('Externalnode::Node');

my $testing = 0;
my $NB_HYPERVISORS = 1;
my $boards = [
    {
        ram  => 2048,
        core => 2,
        nics => [
            {
                name => "eth0",
                mac  => "00:11:11:11:11:11",
                pxe  => 1
            },
        ]
    },
];

eval {
    Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
    my $adm = Administrator->new;
    my $db = $adm->{db};
    
    my @args = ();
    my $executor = new_ok("Executor", \@args, "Instantiate an executor");

    if ($testing) {
        $adm->beginTransaction;
    }

    my $hostmodel;
    lives_ok {
        $hostmodel = Entity::Hostmodel->find(hash => {});
    } 'Get an existing host model';

    my $kanopya_cluster;
    my $physical_hoster;
    lives_ok {
        $kanopya_cluster = Entity::ServiceProvider::Inside::Cluster->find(
			       hash => {
                                   cluster_name => 'Kanopya'
			       }
			   );
        $physical_hoster = $kanopya_cluster->getHostManager();
    } 'Retrieve the Kanopya cluster';

    isa_ok ($kanopya_cluster, 'Entity::ServiceProvider::Inside::Cluster');
    isa_ok ($physical_hoster, 'Entity::Component::Physicalhoster0');

    my $disk_manager;
    lives_ok {
        $disk_manager = EEntity->new(
                            entity => $kanopya_cluster->getComponent(name    => 'Lvm',
                                                                     version => 2) 
			);
    };

    isa_ok ($disk_manager->_getEntity, 'Manager::DiskManager');

    my $export_manager;
    lives_ok {
        $export_manager = EEntity->new(
                              entity => $kanopya_cluster->getComponent(name    => 'Iscsitarget',
                                                                       version => 1)
                          );
    } 'Retrieving iSCSI component';

    isa_ok ($export_manager->_getEntity, 'Manager::ExportManager');

    my $kernel;
    lives_ok {
        $kernel = Entity::Kernel->find(hash => { kernel_name => '3.0.42-0.7-default' });
    } 'Get a kernel for KVM';

    my @hosts;
    lives_ok {
        @hosts = Entity::Host->find(hash => { host_manager_id => $physical_hoster->getId });
    } 'Retrieve physical hosts';

    my $admin_user;
    lives_ok {
        $admin_user = Entity::User->find(hash => { user_login => 'admin' });
    } 'Retrieve the admin user';

    my $hostid;
    lives_ok {
        for my $board (@{$boards}) {
            my $host = Entity::Host->new(
                active             => 1,
                host_manager_id    => $physical_hoster->getId,
                kernel_id          => $kernel->getId,
                host_serial_number => "123",
                host_ram           => $board->{ram} * 1024 * 1024,
                host_core          => $board->{core}
            );

            for my $nic (@{$board->{nics}}) {
                my $if_id = $host->addIface(
                    iface_name     => $nic->{name},
                    iface_pxe      => $nic->{pxe},
                    iface_mac_addr => $nic->{mac}
                );

                if (defined $nic->{master}) {
	            my $if = Entity::Iface->get(id => $if_id);
		    $if->setAttr(name => 'master', value => $nic->{master});
		    $if->save();
		}
            }

	    $hostid = $host->id;
        };
    } 'Registering physical hosts';

    my $masterimage;
    lives_ok {
        Entity::Operation->enqueue(
            priority => 200,
            type     => 'DeployMasterimage',
            params   => { file_path => "/vagrant/" . ($ENV{'MASTERIMAGE'} || "centos-6.3-opennebula3.tar.bz2"),
                          keep_file => 1 },
        );
    } 'Deploy master image';

    lives_ok { $executor->oneRun; } 'DeployMasterImage operation execution succeed';
    lives_ok { $executor->oneRun; } 'DeployMasterImage operation execution succeed';

    lives_ok {
        $masterimage = Entity::Masterimage->find( hash => { } );
    } 'Retrieve KVM master image';

    my $adminnetconf;
    lives_ok {
	$adminnetconf	= Entity::Netconf->find(hash => {
	    netconf_name    => "Kanopya admin"
	});
    } 'Retrieve admin NetConf';

    isa_ok($adminnetconf, 'Entity::Netconf');

    my @iscsi_portal_ids;
    lives_ok {
	for my $portal (Entity::Component::Iscsi::IscsiPortal->search(hash => { iscsi_id => $export_manager->id })) {
	    push @iscsi_portal_ids, $portal->id;
	}
    } 'Retrieve admin network';

    lives_ok {
        Entity::ServiceProvider::Inside::Cluster->create(
            active                 => 1,
            cluster_name           => "Bondage",
            cluster_min_node       => "1",
            cluster_max_node       => "3",
            cluster_priority       => "100",
            cluster_si_shared      => 0,
            cluster_si_persistent  => 1,
            cluster_domainname     => 'my.domain',
            cluster_basehostname   => 'one',
            cluster_nameserver1    => '208.67.222.222',
            cluster_nameserver2    => '127.0.0.1',
            kernel_id              => $kernel->id,
            masterimage_id         => $masterimage->id,
            user_id                => $admin_user->id,
            managers               => {
                host_manager => {
                    manager_id     => $physical_hoster->id,
                    manager_type   => "host_manager",
                    manager_params => {
                        cpu        => 1,
                        ram        => 512 * 1024 * 1024,
                    }
                },
                disk_manager => {
                    manager_id       => $disk_manager->id,
                    manager_type     => "disk_manager",
                    manager_params   => {
                        vg_id            => 1,
                        systemimage_size => 4 * 1024 * 1024 * 1024
                    },
                },
                export_manager => {
                    manager_id       => $export_manager->id,
                    manager_type     => "export_manager",
                    manager_params   => {
			iscsi_portals => \@iscsi_portal_ids,
			# target        => 'dummytarget',
			# lun           => 0,
                    }
                },
            },
            components => {
		opennebula => {
	            component_type => ComponentType->find(hash => {component_name => 'Opennebula'})->id,
		},
	    },
            interfaces => {
                admin => {
                    interface_netconfs  => { $adminnetconf->id => $adminnetconf->id },
                },
            },
        );
    } 'AddCluster operation enqueue';

    lives_ok { $executor->oneRun; } 'AddCluster operation execution succeed';
    lives_ok { $executor->oneRun; } 'AddCluster operation execution succeed';

    my ($cluster, $cluster_id);
    lives_ok {
        $cluster = Entity::ServiceProvider::Inside::Cluster->find(
                       hash => { cluster_name => 'Bondage'}
                   );
    } 'retrieve Cluster via name';

    isa_ok($cluster, 'Entity::ServiceProvider::Inside::Cluster');     
   
    lives_ok {
	my $vlan = Entity::Vlan->new(vlan_name => 'prodvlan1', vlan_number => '20');
	my $vlan2 = Entity::Vlan->new(vlan_name => 'prodvlan2', vlan_number => '50');
   
	NetconfVlan->new(netconf_id => $adminnetconf->id, vlan_id => $vlan->id); 
	NetconfVlan->new(netconf_id => $adminnetconf->id, vlan_id => $vlan2->id); 
    } 'add two vlans to admin netconf';
 
    my $fileimagemanager;
    lives_ok {
        $fileimagemanager = $kanopya_cluster->getComponent(name    => "Fileimagemanager",
                                                           version => 0);
    } 'retrieve file image manager';

    my $opennebula;
    lives_ok {
        $opennebula = $cluster->getComponent(name    => "Opennebula",
                                             version => 3);
    } 'retrieve Opennebula component';

    lives_ok {
        $opennebula->setConf(conf => {
            image_repository_path    => "/srv/cloud/images",
            opennebula3_id           => $opennebula->id,
#            opennebula3_repositories => [ {
#                container_access_id  => $nfs->id,
#                repository_name      => 'image_repo'
#            } ],
            hypervisor               => "kvm"
        } );
    } 'configuring Opennebula image repository';

    lives_ok {
        $cluster->start();
    } 'Start cluster, PreStartNode operation enqueue.';
                            
    lives_ok { $executor->oneRun; } 'PreStartNode operation execution succeed';
    lives_ok { $executor->oneRun; } 'PreStartNode operation execution succeed';
    lives_ok { $executor->oneRun; } 'PreStartNode operation execution succeed';
    lives_ok { $executor->oneRun; } 'PreStartNode operation execution succeed';
    lives_ok { $executor->oneRun; } 'PreStartNode operation execution succeed';

    my ($state, $timestemp) = $cluster->getState;
    cmp_ok ($state, 'eq', 'starting', "Cluster is 'starting'");

    lives_ok {
        my $timeout = 600;
        my $operation;
        while ($timeout > 0) {
            eval {
                $operation = Entity::Operation->find(hash => {});
            };
            if ($@) {
                last;
            }
            else {
                sleep 5;
                $timeout -= 5;
                $executor->oneRun;
            }
        }
    } 'Waiting maximum 600 seconds for the host to start';

    my $startedHost;
    lives_ok {
        my $hosts = $cluster->getHosts;
        $startedHost = $hosts->{$hostid};
    } 'Retrieve started host';
    isa_ok($startedHost, "Entity::Host");

    my @ifaces;
    lives_ok {
        @ifaces	= $startedHost->ifaces;
    } 'Retrieve its ifaces';

    my $isThereASlave = 0;
    for $iface (@ifaces) {
        isa_ok($iface, "Entity::Iface");
        if ($iface->slaves ne undef) {
            $isThereASlave = 1;
        }
    }
    is($isThereASlave, 1);

    # lives_ok {
    #     $cluster->forceStop;
    # } 'force stop cluster, ForceStopCluster operation enqueue';

    # lives_ok { $executor->oneRun; } 'ForceStopCluster operation execution succeed';

    # ($state, $timestemp) = $cluster->getState;
    # cmp_ok ($state, 'eq', 'down', "Cluster is 'down'");

    # lives_ok { $cluster->remove; } 'RemoveCluster operation enqueue';
    # lives_ok { $executor->oneRun; } 'RemoveCluster operation execution succeed';

    # throws_ok {
    #     $cluster = Entity::ServiceProvider::Inside::Cluster->get(id => $cluster->getId);
    # } 
    # 'Kanopya::Exception::DB',
    # "Cluster with id $cluster_id does not exist anymore";
};
if($@) {
    my $error = $@;
    print $error."\n";
};

