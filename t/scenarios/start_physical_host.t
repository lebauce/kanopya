#!/usr/bin/perl -w

use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Kanopya::Exceptions;
use ComponentType;

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
use_ok ('Entity::Kernel');
use_ok ('Entity::Processormodel');
use_ok ('Entity::Hostmodel');
use_ok ('Entity::Masterimage');
use_ok ('Entity::Network');
use_ok ('Entity::Netconf');
use_ok ('Entity::Poolip');
use_ok ('Entity::Operation');
use Execution;

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
            },
            {
                name => "eth2",
                mac  => "aa:bb:cc:dd:ee:ff",
                pxe  => 0,
            },
        ]
    },
];

eval {
    Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
    my $adm = Administrator->new;
    my $db = $adm->{db};
    
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
    } 'Retrieving LVM disk manager';

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
        $kernel = Entity::Kernel->find(hash => { kernel_name => $ENV{'KERNEL'} || "2.6.32-279.5.1.el6.x86_64" });
    } 'Get a kernel';

    my @hosts;
    lives_ok {
        @hosts = Entity::Host->find(hash => { host_manager_id => $physical_hoster->id });
    } 'Retrieve physical hosts';

    my $admin_user;
    lives_ok {
        $admin_user = Entity::User->find(hash => { user_login => 'admin' });
    } 'Retrieve the admin user';

    lives_ok {
        for my $board (@{$boards}) {
            my $host = Entity::Host->new(
                active             => 1,
                host_manager_id    => $physical_hoster->id,
                kernel_id          => $kernel->id,
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
    my $deploy;
    lives_ok {
        $deploy = Entity::Operation->enqueue(
                      priority => 200,
                      type     => 'DeployMasterimage',
                      params   => { file_path => "/vagrant/" . ($ENV{'MASTERIMAGE'} || "centos-6.3-opennebula3.tar.bz2"),
                                    keep_file => 1 },
                  );
    } 'Deploy master image';

    Execution->execute(entity => $deploy);

    lives_ok {
        $opennebula_masterimage = Entity::Masterimage->find( hash => { } );
    } 'Retrieve master image';

    my $adminnetconf;
    lives_ok {
        $adminnetconf   = Entity::Netconf->find(hash => {
            netconf_name    => "Kanopya admin"
        });
    } 'Retrieve admin NetConf';

    isa_ok($adminnetconf, 'Entity::Netconf');

    my @iscsi_portal_ids;
    lives_ok {
        for my $portal (Entity::Component::Iscsi::IscsiPortal->search(hash => { iscsi_id => $export_manager->id })) {
            push @iscsi_portal_ids, $portal->id;
        }
    } 'Retrieve iSCSI portals'; 

    my $cluster_create;
    lives_ok {
        $cluster_create = Entity::ServiceProvider::Inside::Cluster->create(
                              active                 => 1,
                              cluster_name           => "MyCluster",
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
                              masterimage_id         => $opennebula_masterimage->id,
                              user_id                => $admin_user->getAttr(name => 'user_id'),
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
                                          iscsi_portals => [ $iscsi_portal_ids[0] ],
                                      }
                                  },
                              },
                              components             => {
                              },
                              interfaces             => {
                                  admin => {
                                      interface_netconfs  => { $adminnetconf->id => $adminnetconf->id },
                                  },
                                  public => {
                                      interface_netconfs  => { $adminnetconf->id => $adminnetconf->id },
                                  }
                              }
                          );
    } 'AddCluster operation enqueue';

    Execution->execute(entity => $cluster_create); 

    my ($cluster, $cluster_id);
    lives_ok {
        $cluster = Entity::ServiceProvider::Inside::Cluster->find(
                       hash => { cluster_name => 'MyCluster' }
                   );
    } 'retrieve Cluster via name';

    isa_ok($cluster, 'Entity::ServiceProvider::Inside::Cluster');     

    Execution->execute(entity => $cluster->start());
};
if($@) {
    my $error = $@;
    print $error."\n";
};

