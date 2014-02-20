#!/usr/bin/perl -w

=head1 SCOPE

TODO

=head1 PRE-REQUISITE

TODO

=cut

use Test::More 'no_plan';
use Test::Exception;
use Kanopya::Exceptions;

use Log::Log4perl qw(:easy get_logger);
Log::Log4perl->easy_init({
    level=>'INFO',
    file=>'setup_unmanaged_iscsi_multipath.t.log',
    layout=>'%F %L %p %m%n'
});

use Kanopya::Database;
use Entity::ServiceProvider::Cluster;
use Entity::User;
use Entity::Host;
use Entity::Kernel;
use Entity::Processormodel;
use Entity::Hostmodel;
use Entity::Masterimage;
use Entity::Network;
use Entity::Netconf;
use NetconfPoolip;
use NetconfIface;
use Entity::Poolip;
use Entity::Operation;
use IscsiPortal;
use ClassType::ComponentType;
use Entity::Workflow;

use Kanopya::Tools::Execution;
use Kanopya::Tools::Register;
use Kanopya::Tools::Retrieve;

my $testing = 1;

main();

sub main {
    Kanopya::Database::authenticate( login =>'admin', password => 'K4n0pY4' );

    if ($testing) {
        Kanopya::Database::beginTransaction;
    }

    diag('Create and configure cluster');
    _create_and_configure_cluster();

    diag('Start unmanaged multipath host');
    start_unmanaged_multipath_host();

    if ($testing) {
        Kanopya::Database::rollbackTransaction;
    }
}

sub start_unmanaged_multipath_host {
    lives_ok {
        diag('retrieve Cluster via name');
        my $cluster = Kanopya::Tools::Retrieve->retrieveCluster(criteria => {cluster_name => 'UnmanagedMulStorageCluster'});

        diag('Cluster start operation');
        Kanopya::Tools::Execution->executeOne(entity => $cluster->start());

        my ($state, $timestemp) = $cluster->getState;
        if ($state eq 'up') {
            diag("Cluster $cluster->cluster_name started successfully");
        }
        else {
            die "Cluster is not 'up'";
        }
    } 'Start cluster';
}

sub _create_and_configure_cluster {
    #####################
    # register networks #
    #####################

    diag('create storage_network1 10.100.0.0');
    my $storage_network1 = Entity::Network->new(network_name    => 'storage_path1',
                                             network_addr    => '10.100.0.0',
                                             network_netmask => '255.255.255.0',
                                             network_gateway => '10.100.0.254'
    );

    diag('create storage_network2 10.200.0.0');
    my $storage_network2 = Entity::Network->new(network_name    => 'storage_path2',
                                             network_addr    => '10.200.0.0',
                                             network_netmask => '255.255.255.0',
                                             network_gateway => '10.200.0.254'
    );

    diag('Retrieve admin network');
    my $admin_network = Entity::Network->find( hash => { network_name => 'admin' } );

    ##############################
    # register networks' poolips #
    ##############################

    diag('create poolip 1 on storage_network1');
    my $pool1 = Entity::Poolip->new(poolip_name       => 'storage_pool1',
                                 poolip_first_addr => '10.100.0.10',
                                 poolip_size       => 200,
                                 network_id        => $storage_network1->id
    );

    diag('create poolip 2 on storage_network2');
    my $pool2 = Entity::Poolip->new(poolip_name       => 'storage_pool2',
                                 poolip_first_addr => '10.200.0.10',
                                 poolip_size       => 200,
                                 network_id        => $storage_network2->id
    );

    #####################
    # register netconfs #
    #####################

    diag('register new netconf for storage_network1');
    my $storage_netconf1 = Entity::Netconf->new(netconf_name => 'storage_netconf1');
    NetconfPoolip->new(netconf_id => $storage_netconf1->id, poolip_id => $pool1->id);

    diag('register new netconf for storage_network2');
    my $storage_netconf2 = Entity::Netconf->new(netconf_name => 'storage_netconf2');
    NetconfPoolip->new(netconf_id => $storage_netconf2->id, poolip_id => $pool2->id);

    diag('retrieve admin netconf');
    my $admin_netconf = Entity::Netconf->find(hash => { netconf_name => 'Kanopya admin' });

    ####################################################
    # declare physical host with its attached netconfs #
    ####################################################

    diag('Get a kernel for KVM');
    my $kernel = Entity::Kernel->find(hash => { kernel_name => '3.0.42-0.7-default' });

    diag('Get an existing host model');
    my $hostmodel = Entity::Hostmodel->find(hash => {});

    diag('Retrieve the Kanopya cluster');
    my $kanopya_cluster = Kanopya::Tools::Retrieve->retrieveCluster();

    diag('Get physical hoster');
    my $physical_hoster = $kanopya_cluster->getHostManager();

    my $host = Entity::Host->new(
        active             => 1,
        host_manager_id    => $physical_hoster->id,
        kernel_id          => $kernel->id,
        host_serial_number => "123",
        host_ram           => 2048 * 1024 * 1024,
        host_core          => 2
    );

    diag('Registering physical host');
    my @ifaces = (
        {
            name => "eth0",
            mac  => "00:11:11:11:11:11",
            pxe  => 1,
            netconf_id => $admin_netconf->id
        },
        {
            name => "eth1",
            mac  => "00:22:22:22:22:22",
            pxe  => 0,
            netconf_id => $storage_netconf1->id
        },
        {
            name => "eth2",
            mac  => "00:33:33:33:33:33",
            pxe  => 0,
            netconf_id => $storage_netconf2->id
        }
    );
    for my $nic (@ifaces) {
        my $id = $host->addIface(
            iface_name     => $nic->{name},
            iface_pxe      => $nic->{pxe},
            iface_mac_addr => $nic->{mac}
        );

        NetconfIface->new(netconf_id => $nic->{netconf_id}, iface_id => $id);
    }

    ###########################################
    # configure export_manager with 2 portals #
    ###########################################
    diag('Retrieving generic iSCSI component');
    my $export_manager = EEntity->new(
                          data => $kanopya_cluster->getComponent(name => "Iscsi")
    );

    diag('Configuring portals of the iSCSI component');
    $export_manager->setConf(conf => {
        iscsi_portals => [
            {
                iscsi_portal_ip   => '10.100.0.1',
                iscsi_portal_port => 3260
            },
            {
                iscsi_portal_ip   => '10.200.0.1',
                iscsi_portal_port => 3260
            },
        ]
    });

    ####################
    # register service #
    ####################
    diag('Retrieve the admin user');
    my $admin_user = Entity::User->find(hash => { user_login => 'admin' });

    diag('Retrieve iscsi portals');
    my @iscsi_portal_ids;
    for my $portal (IscsiPortal->search(hash => { iscsi_id => $export_manager->id })) {
        push @iscsi_portal_ids, $portal->id;
    }

    diag('Retrieve disk manager');
    my $disk_manager = EEntity->new(
                        data => $kanopya_cluster->getComponent(name => "Storage")
    );

    diag('Create cluster');
    my $cluster_create = Entity::ServiceProvider::Cluster->create(
        active                 => 1,
        cluster_name           => "UnmanagedMulStorageCluster",
        cluster_min_node       => "1",
        cluster_max_node       => "3",
        cluster_priority       => "100",
        cluster_si_persistent  => 1,
        cluster_domainname     => 'my.domain',
        cluster_basehostname   => 'one',
        cluster_nameserver1    => '208.67.222.222',
        cluster_nameserver2    => '127.0.0.1',
        cluster_boot_policy    => 'PXE Boot via ISCSI',
        owner_id               => $admin_user->id,
        managers               => {
            host_manager => {
                manager_id     => $physical_hoster->id,
                manager_type   => 'Hostmanager',
                manager_params => {
                    cpu        => 1,
                    ram        => 512 *1024 *1024,
                }
            },
            disk_manager => {
                manager_id       => $disk_manager->id,
                manager_type     => 'DiskManager',
                manager_params   => {
                    vg_id => 1,
                    systemimage_size => 4 * 1024 * 1024 * 1024
                },
            },
            export_manager => {
                manager_id       => $export_manager->id,
                manager_type     => 'ExportManager',
                manager_params   => {
                    iscsi_portals => \@iscsi_portal_ids,
                    target        => 'iqn.2012-11.com.hederatech.nas:' . ($ENV{'LUNNAME'} || 'vm'),
                    lun           => 0
                }
            },
        },
        components             => {
            fileimagemanager => {
                component_type => ClassType::ComponentType->find(hash => { component_name => 'Fileimagemanager' })->id,
            },
            opennebula => {
                component_type => ClassType::ComponentType->find(hash => { component_name => 'Opennebula' })->id,
            },
            suse => {
                component_type => ClassType::ComponentType->find(hash => { component_name => 'Suse' })->id,
            }
        },
        interfaces => {
            i1 => {
                interface_name => 'eth0',
                netconfs       => { $admin_netconf->id    => $admin_netconf->id },
                                  { $storage_netconf1->id => $storage_netconf1->id },
                                  { $storage_netconf2->id => $storage_netconf2->id },
                # bonds_number => 2,
            },
        },
    );
    Kanopya::Tools::Execution->executeOne(entity => $cluster_create);
}
