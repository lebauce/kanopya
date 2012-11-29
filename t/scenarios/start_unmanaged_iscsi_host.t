#!/usr/bin/perl -w
use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Kanopya::Exceptions;

use Log::Log4perl qw(:easy get_logger);
Log::Log4perl->easy_init({
    level=>'DEBUG',
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
use_ok ('Entity::Poolip');
use_ok ('Entity::Operation');
use_ok ('Entity::Component::Iscsi::IscsiPortal');
use_ok ('ComponentType');

# Set a mock for startHost
#use EEntity::EComponent::EPhysicalhoster0;
#use EEntity::EHost;
#
#EEntity::EHost->setMock(mock => 'EHostMock');
#EEntity::EComponent::EPhysicalhoster0->setMock(mock => 'EPhysicalhoster0Mock');

my $testing = 1;
my $boards = [
    {
        ram  => 2048,
        core => 2,
        nics => [
            {
                name => "eth0",
                mac  => "00:11:22:33:44:55",
                pxe  => 1
            },
            {
                name => "eth1",
                mac  => "66:77:88:99:00:aa",
                pxe  => 0,
            }
        ]
    },
];

eval {
    Administrator::authenticate( login =>'admin', password => '_tamere23' );
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
        $disk_manager = EFactory::newEEntity(
                            data => $kanopya_cluster->getComponent(name => "Storage")
                        );
    };

    isa_ok ($disk_manager->_getEntity, 'Manager::DiskManager');

    my $export_manager;
    lives_ok {
        $export_manager = EFactory::newEEntity(
                              data => $kanopya_cluster->getComponent(name => "Iscsi")
                          );
    } 'Retrieving generic iSCSI component';

    isa_ok ($export_manager->_getEntity, 'Manager::ExportManager');

    lives_ok {
        $export_manager->setConf(conf => { iscsi_portals => [ { iscsi_portal_ip   => '10.0.0.1',
                                                                iscsi_portal_port => 3261 },
                                                              { iscsi_portal_ip   => '10.0.0.2',
                                                                iscsi_portal_port => 3261 } ] });
    } 'Configuring portals of the iSCSI component';

    my $kernel;
    lives_ok {
        $kernel = Entity::Kernel->find(hash => { kernel_name => '2.6.32-279.5.1.el6.x86_64' });
    } 'Get a kernel for KVM';

    my @hosts;
    lives_ok {
        @hosts = Entity::Host->find(hash => { host_manager_id => $physical_hoster->getId });
    } 'Retrieve physical hosts';

    my $admin_user;
    lives_ok {
        $admin_user = Entity::User->find(hash => { user_login => 'admin' });
    } 'Retrieve the admin user';

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
                $host->addIface(
                    iface_name     => $nic->{name},
                    iface_pxe      => $nic->{pxe},
                    iface_mac_addr => $nic->{mac}
                );
            }
        };
    } 'Registering physical hosts';

    my $admin_network;
    lives_ok {
        $admin_network = Entity::Network->find( hash => { network_name => 'admin' } );
    } 'Retrieve admin network';

    my @iscsi_portal_ids;
    lives_ok {
        for my $portal (Entity::Component::Iscsi::IscsiPortal->search(hash => { iscsi_id => $export_manager->id })) {
            push @iscsi_portal_ids, $portal->id;
        }
    } 'Retrieve admin network';

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
                        target        => 'dummytarget',
                        lun           => 0
                    }
                },
            },
        );
    } 'AddCluster operation enqueue';

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

    my ($state, $timestemp) = $cluster->getState;
    cmp_ok ($state, 'eq', 'starting', "Cluster is 'starting'");

    lives_ok {
        my $timeout = 300;
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
    } 'Waiting maximum 300 seconds for the host to start';

    lives_ok {
        $cluster = Entity::ServiceProvider::Inside::Cluster->find(
                       hash => { cluster_name => 'UnmanagedStorageCluster'}
                   );
    } 'retrieve Cluster via name';

    my ($state, $timestemp) = $cluster->getState;
    cmp_ok ($state, 'eq', 'up', "Cluster is 'up'");

    lives_ok {
        $cluster->stop;
    } 'force stop cluster, ForceStopCluster operation enqueue';

    lives_ok { $executor->oneRun; } 'PreStartNode operation execution succeed';

    lives_ok {
        $cluster = Entity::ServiceProvider::Inside::Cluster->find(
                       hash => { cluster_name => 'UnmanagedStorageCluster'}
                   );
    } 'retrieve Cluster via name';

    my ($state, $timestemp) = $cluster->getState;
    cmp_ok ($state, 'eq', 'stopping', "Cluster is 'stopping'");

    lives_ok {
        my $timeout = 300;
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
    } 'Waiting maximum 300 seconds for the host to start';

    lives_ok {
        $cluster = Entity::ServiceProvider::Inside::Cluster->find(
                       hash => { cluster_name => 'UnmanagedStorageCluster'}
                   );
    } 'retrieve Cluster via name';

    ($state, $timestemp) = $cluster->getState;
    cmp_ok ($state, 'eq', 'down', "Cluster is 'down'");

    lives_ok { $cluster->deactivate; } 'DeactivateCluster operation enqueue';
    lives_ok { $executor->oneRun; } 'DeactivateCluster operation execution succeed';

    lives_ok { $cluster->remove; } 'RemoveCluster operation enqueue';
    lives_ok { $executor->oneRun; } 'RemoveCluster operation execution succeed';

    throws_ok {
        $cluster = Entity::ServiceProvider::Inside::Cluster->get(id => $cluster->getId);
    }
    'Kanopya::Exception::Internal::NotFound',
    "Cluster with id $cluster_id does not exist anymore";

    if ($testing) {
        $adm->rollbackTransaction;
    }
};
if($@) {
    my $error = $@;
    print $error."\n";
};

