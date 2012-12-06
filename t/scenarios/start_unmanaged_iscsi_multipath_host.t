#!/usr/bin/perl -w
use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Kanopya::Exceptions;

use Log::Log4perl qw(:easy get_logger);
Log::Log4perl->easy_init({
    level=>'INFO',
    file=>'/tmp/SetupUnmanagedStorageHost.t.log',
    layout=>'%F %L %p %m%n'
});

use_ok ('Administrator');
use_ok ('Executor');
use_ok ('Entity::ServiceProvider::Inside::Cluster');
use_ok ('Entity::User');
use_ok ('Entity::Host');
use_ok ('Entity::Kernel');
use_ok ('Entity::Processormodel');
use_ok ('Entity::Hostmodel');
use_ok ('Entity::Masterimage');
use_ok ('Entity::Network');
use_ok ('Entity::Netconf');
use_ok ('NetconfPoolip');
use_ok ('NetconfIface');
use_ok ('Entity::Poolip');
use_ok ('Entity::Operation');
use_ok ('Entity::Component::Iscsi::IscsiPortal');
use_ok ('ComponentType');


my $testing = 1;

eval {
    Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
    my $adm = Administrator->new;
    my $db = $adm->{db};
    
    my @args = ();
    my $executor = new_ok("Executor", \@args, "Instantiate an executor");

    if ($testing) {
        $adm->beginTransaction;
    }

    #####################
    # register networks #
    #####################

    my ($storage_network1, $storage_network2);
    lives_ok {
        $storage_network1 = Entity::Network->new(network_name    => 'storage_path1',
                                                 network_addr    => '10.100.0.0',
                                                 network_netmask => '255.255.255.0',
                                                 network_gateway => '10.100.0.254');
    } 'create storage_network1 10.100.0.0';
    
    lives_ok {
        $storage_network2 = Entity::Network->new(network_name    => 'storage_path2',
                                                 network_addr    => '10.200.0.0',
                                                 network_netmask => '255.255.255.0',
                                                 network_gateway => '10.200.0.254');
    } 'create storage_network2 10.200.0.0';

    my $admin_network;
    lives_ok {
        $admin_network = Entity::Network->find( hash => { network_name => 'admin' } );
    } 'Retrieve admin network';

    ##############################
    # register networks' poolips #
    ##############################
    
    my ($pool1, $pool2);
    lives_ok {
        $pool1 = Entity::Poolip->new(poolip_name       => 'storage_pool1',
                                     poolip_first_addr => '10.100.0.10',
                                     poolip_size       => 200,
                                     network_id        => $storage_network1->id);
    } 'create poolip 1 on storage_network1';
    
    lives_ok {
        $pool2 = Entity::Poolip->new(poolip_name       => 'storage_pool2',
                                     poolip_first_addr => '10.200.0.10',
                                     poolip_size       => 200,
                                     network_id        => $storage_network2->id);
    } 'create poolip 2 on storage_network2';
    
    #####################
    # register netconfs #
    #####################
    
    my ($storage_netconf1, $storage_netconf2, $admin_netconf);
    lives_ok {
        $storage_netconf1 = Entity::Netconf->new(netconf_name => 'storage_netconf1');
        NetconfPoolip->new(netconf_id => $storage_netconf1->id, poolip_id => $pool1->id);
    } 'register new netconf for storage_network1';
    
    lives_ok {
        $storage_netconf2 = Entity::Netconf->new(netconf_name => 'storage_netconf2');
        NetconfPoolip->new(netconf_id => $storage_netconf2->id, poolip_id => $pool2->id);
    } 'register new netconf for storage_network2';

    lives_ok {
        $admin_netconf = Entity::Netconf->find(hash => { netconf_name => 'Kanopya admin' });
    } 'retrieve admin netconf';

    ####################################################
    # declare physical host with its attached netconfs #
    ####################################################

    my $kernel;
    lives_ok {
        $kernel = Entity::Kernel->find(hash => { kernel_name => '3.0.42-0.7-default' });
    } 'Get a kernel for KVM';

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

    lives_ok {
        my $host = Entity::Host->new(
            active             => 1,
            host_manager_id    => $physical_hoster->getId,
            kernel_id          => $kernel->getId,
            host_serial_number => "123",
            host_ram           => 2048 * 1024 * 1024,
            host_core          => 2
        );

        my @ifaces = ( { name => "eth0",
                         mac  => "00:11:11:11:11:11",
                         pxe  => 1,
                         netconf_id => $admin_netconf->id },
                       { name => "eth1",
                         mac  => "00:22:22:22:22:22",
                         pxe  => 0, 
                         netconf_id => $storage_netconf1->id }, 
                       { name => "eth2",
                         mac  => "00:33:33:33:33:33",
                         pxe  => 0, 
                         netconf_id => $storage_netconf2->id }
                     );

        for my $nic (@ifaces) {
            my $id = $host->addIface(
                iface_name     => $nic->{name},
                iface_pxe      => $nic->{pxe},
                iface_mac_addr => $nic->{mac}
            );
            
            NetconfIface->new(netconf_id => $nic->{netconf_id}, iface_id => $id);
        }
        
    } 'Registering physical host';

    ###########################################
    # configure export_manager with 2 portals #
    ###########################################

    my $export_manager;
    lives_ok {
        $export_manager = EFactory::newEEntity(
                              data => $kanopya_cluster->getComponent(name => "Iscsi")
                          );
    } 'Retrieving generic iSCSI component';

    isa_ok ($export_manager->_getEntity, 'Manager::ExportManager');

    lives_ok {
        $export_manager->setConf(conf => { iscsi_portals => [ { iscsi_portal_ip   => '10.100.0.1',
                                                                iscsi_portal_port => 3260 },
                                                                { iscsi_portal_ip   => '10.200.0.1',
                                                                iscsi_portal_port => 3260 },
                                                              ] });
    } 'Configuring portals of the iSCSI component';

    ####################
    # register service #
    ####################

    my $admin_user;
    lives_ok {
        $admin_user = Entity::User->find(hash => { user_login => 'admin' });
    } 'Retrieve the admin user';

    my @iscsi_portal_ids;
    lives_ok {
        for my $portal (Entity::Component::Iscsi::IscsiPortal->search(hash => { iscsi_id => $export_manager->id })) {
            push @iscsi_portal_ids, $portal->id;
        }
    } 'Retrieve iscsi portals';

    my $disk_manager;
    lives_ok {
        $disk_manager = EFactory::newEEntity(
                            data => $kanopya_cluster->getComponent(name => "Storage")
                        );
    };

    isa_ok ($disk_manager->_getEntity, 'Manager::DiskManager');

    lives_ok {
        Entity::ServiceProvider::Inside::Cluster->create(
            active                 => 1,
            cluster_name           => "UnmanagedStorageCluster",
            cluster_min_node       => "1",
            cluster_max_node       => "3",
            cluster_priority       => "100",
            cluster_si_shared      => 0,
            cluster_si_persistent  => 1,
            cluster_domainname     => 'my.domain',
            cluster_basehostname   => 'one',
            cluster_nameserver1    => '208.67.222.222',
            cluster_nameserver2    => '127.0.0.1',
            # cluster_boot_policy    => 'PXE Boot via ISCSI',
            user_id                => $admin_user->id,
            managers               => {
                host_manager => {
                    manager_id     => $physical_hoster->id,
                    manager_type   => "host_manager",
                    manager_params => {
                        cpu        => 1,
                        ram        => 512 *1024 *1024,
                    }
                },
                disk_manager => {
                    manager_id       => $disk_manager->id,
                    manager_type     => "disk_manager",
                    manager_params   => {
                        vg_id => 1,
                        systemimage_size => 4 * 1024 * 1024 * 1024
                    },
                },
                export_manager => {
                    manager_id       => $export_manager->id,
                    manager_type     => "export_manager",
                    manager_params   => {
                        iscsi_portals => \@iscsi_portal_ids,
                        target        => 'iqn.2012-11.com.hederatech.nas:vm2',
                        lun           => 0
                    }
                },
            },
            components             => {
                fileimagemanager => {
                    component_type => ComponentType->find(hash => { component_name => 'Fileimagemanager' })->id,
                },
                opennebula => {
                    component_type => ComponentType->find(hash => { component_name => 'Opennebula' })->id,
                },
                suse => {
                    component_type => ComponentType->find(hash => { component_name => 'Suse' })->id,
                }
            },
            interfaces => {
                i1 => { interface_netconfs => { $admin_netconf->id    => $admin_netconf->id }, 
                                              { $storage_netconf1->id => $storage_netconf1->id }, 
                                              { $storage_netconf2->id => $storage_netconf2->id },
                        },
                        # bonds_number => 2,
                
                
            },
        );
    } 'AddCluster operation enqueue';

    lives_ok { $executor->oneRun; } 'AddCluster operation execution succeed';
    lives_ok { $executor->oneRun; } 'AddCluster operation execution succeed';

    my ($cluster, $cluster_id);
    lives_ok {
        $cluster = Entity::ServiceProvider::Inside::Cluster->find(
                       hash => { cluster_name => 'UnmanagedStorageCluster'}
                   );
    } 'retrieve Cluster via name';

    isa_ok($cluster, 'Entity::ServiceProvider::Inside::Cluster');     

    lives_ok {
        $cluster->start();
    } 'Start cluster, PreStartNode operation enqueue.';

    lives_ok { $executor->oneRun; } 'PreStartNode operation execution succeed';
    lives_ok { $executor->oneRun; } 'PreStartNode operation execution succeed';
    lives_ok { $executor->oneRun; } 'PreStartNode operation execution succeed';
    lives_ok { $executor->oneRun; } 'PreStartNode operation execution succeed';
    lives_ok { $executor->oneRun; } 'PreStartNode operation execution succeed';

    if ($testing) {
        $adm->rollbackTransaction;
    }
};
if($@) {
    my $error = $@;
    print $error."\n";
};

