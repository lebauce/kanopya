#!/usr/bin/perl -w
use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Kanopya::Exceptions;

use Log::Log4perl qw(:easy get_logger);
Log::Log4perl->easy_init({
    level=>'DEBUG',
    file=>'/vagrant/SetupPhysicalHost.t.log',
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

my $testing = 0;
my $NB_HYPERVISORS = 1;
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
        $disk_manager = EFactory::newEEntity(
                            data => $kanopya_cluster->getComponent(name    => "Lvm",
                                                                   version => 2)
                        );
    };

    isa_ok ($disk_manager->_getEntity, 'Manager::DiskManager');

    my $export_manager;
    lives_ok {
        $export_manager = EFactory::newEEntity(
                              data => $kanopya_cluster->getComponent(name    => "Iscsitarget",
                                                                     version => 1)
                          );
    } 'Retrieving iSCSI component';

    isa_ok ($export_manager->_getEntity, 'Manager::ExportManager');

    my $nfs_manager;
    lives_ok {
        $nfs_manager = EFactory::newEEntity(
                           data => $kanopya_cluster->getComponent(name    => "Nfsd",
                                                                  version => 3)
                       );
    } 'Retrieving NFS server component';

    isa_ok ($nfs_manager->_getEntity, 'Manager::ExportManager');

    my $image_disk;
    lives_ok {
        $image_disk = $disk_manager->createDisk(
            name         => "test_image_repository",
            size         => 6 * 1024 * 1024 * 1024,
            filesystem   => "ext3",
            vg_id        => 1
        )->_getEntity;
    } 'Creating disk for image repository';

    my $nfs;
    lives_ok {
        $nfs = $nfs_manager->createExport(
            container      => $image_disk,
            export_name    => "test_image_repository",
            client_name    => "*",
            client_options => "rw,sync,no_root_squash"
        );
    } 'Creating export for image repository';

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

    my $opennebula_masterimage;
    lives_ok {
        Entity::Operation->enqueue(
            priority => 200,
            type     => 'DeployMasterimage',
            params   => { file_path => "/opt/kanopya/centos-6.3-opennebula3.tar.bz2",
                          keep_file => 1 },
        );
    } 'Deploy KVM master image';

    lives_ok { $executor->oneRun; } 'DeployMasterImage operation execution succeed';
    lives_ok { $executor->oneRun; } 'DeployMasterImage operation execution succeed';

    lives_ok {
        $opennebula_masterimage = Entity::Masterimage->find( hash => { } );
    } 'Retrieve KVM master image';

    my $admin_network;
    lives_ok {
        $admin_network = Entity::Network->find( hash => { network_name => 'admin' } );
    } 'Retrieve admin network';

    my $interface_role; 
    lives_ok {
        $interface_role = Entity::InterfaceRole->find(hash => { interface_role_name => "admin" });
    } 'Get the interface role admin';

    my $interface_vms_role;
    lives_ok {
        $interface_vms_role = Entity::InterfaceRole->find(hash => { interface_role_name => "vms" });
    } 'Get the interface role vms';
 
    lives_ok {
        Entity::ServiceProvider::Inside::Cluster->create(
            active                 => 1,
            cluster_name           => "OpenNebula",
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
            masterimage_id         => $opennebula_masterimage->getId,
            user_id                => $admin_user->getAttr(name => 'user_id'),
            managers               => {
                host_manager => {
                    manager_id     => $physical_hoster->getId,
                    manager_type   => "host_manager",
                    manager_params => {
                        cpu        => 1,
                        ram        => 512*1024*1024,
                    }
                },
                disk_manager => {
                    manager_id       => $disk_manager->getId,
                    manager_type     => "disk_manager",
                    manager_params   => {
                        vg_id => 1,
                        systemimage_size => 4 * 1024 * 1024 * 1024
                    },
                },
                export_manager => {
                    manager_id       => $export_manager->getId,
                    manager_type     => "export_manager",
                    manager_params   => {
                        systemimage_size => 4 * 1024 * 1024 * 1024
                    }
                },
            },
            components             => {
                fileimagemanager => {
                    component_type => 16
                },
                opennebula => {
                    component_type => 14
                }
            },
            interfaces             => {
                admin => {
                    interface_role => $interface_role->getId,
                    interface_networks => [ $admin_network->getId ],
                },
                vms => {
                    interface_role => $interface_vms_role->getId,
                }
            }
        );
    } 'AddCluster operation enqueue';

    lives_ok { $executor->oneRun; } 'AddCluster operation execution succeed';
    lives_ok { $executor->oneRun; } 'AddCluster operation execution succeed';

    my ($cluster, $cluster_id);
    lives_ok {
        $cluster = Entity::ServiceProvider::Inside::Cluster->getCluster(
                       hash => { cluster_name => 'OpenNebula'}
                   );
    } 'retrieve Cluster via name';

    isa_ok($cluster, 'Entity::ServiceProvider::Inside::Cluster');     

    my $fileimagemanager;
    lives_ok {
        $fileimagemanager = $cluster->getComponent(name    => "Fileimagemanager",
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
            opennebula3_id           => $opennebula->getId,
            opennebula3_repositories => [ {
                container_access_id  => $nfs->getId,
                repository_name      => 'image_repo'
            } ],
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

