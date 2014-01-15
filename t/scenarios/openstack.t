#!/usr/bin/perl -w

=head1 SCOPE

TODO

=head1 PRE-REQUISITE

TODO

=cut

use Test::More 'no_plan';
use Test::Exception;

use Log::Log4perl qw(:easy get_logger);
Log::Log4perl->easy_init({
    level=>'DEBUG',
    file=>'openstack.t.log',
    layout=>'%F %L %p %m%n'
});

use Kanopya::Database;
use NetconfVlan;
use Entity::Vlan;
use Lvm2Vg;
use Lvm2Pv;

use Kanopya::Tools::Execution;
use Kanopya::Tools::Register;
use Kanopya::Tools::Retrieve;
use Kanopya::Tools::Create;
use Kanopya::Tools::TestUtils 'expectedException';

my $testing = 0;

main();

sub main {
    Kanopya::Database::authenticate( login =>'admin', password => 'K4n0pY4' );

    if ($testing == 1) {
        Kanopya::Database::beginTransaction;
    }

    diag('Register master image');
    my $masterimage;
    lives_ok {
        $masterimage = Kanopya::Tools::Register::registerMasterImage();
    } 'Register master image';

    diag('Create and configure MySQL and RabbitMQ cluster');
    my $db;
    lives_ok {
        $db = Kanopya::Tools::Create->createCluster(
                        cluster_conf => {
                            cluster_name         => 'Database',
                            cluster_basehostname => 'database',
                            masterimage_id       => $masterimage->id
                        },
                        components => {
                            'mysql' => {
                            },
                            'amqp'  => {
                            },
                        }
                    );
    } 'Create MySQL and RabbitMQ cluster';

    my $sql = $db->getComponent(name => 'Mysql');
    my $amqp = $db->getComponent(name => 'Amqp');

    diag('Create and configure Nova controller');
    my $cloud;
    lives_ok {
        $cloud = Kanopya::Tools::Create->createCluster(
                        cluster_conf => {
                            cluster_name         => 'CloudController',
                            cluster_basehostname => 'cloud',
                            masterimage_id       => $masterimage->id
                        },
                        managers => {
                            host_manager => {
                                manager_params => {
                                    deploy_on_disk => 1
                                }
                            }
                        },
                        components => {
                            'keystone' => {
                            },
                            'novacontroller' => {
                                overcommitment_cpu_factor    => 1,
                                overcommitment_memory_factor => 1
                            },
                            'cinder' => {
                            },
                            'lvm' => {
                            },
                            'glance' => {
                            },
                            'neutron' => {
                            },
                            'apache' => {
                            }
                        }
                    );
    } 'Create Nova controller cluster';

    my $keystone = $cloud->getComponent(name => 'Keystone');
    my $nova_controller = $cloud->getComponent(name => "NovaController");
    my $glance = $cloud->getComponent(name => "Glance");
    my $neutron = $cloud->getComponent(name => "Neutron");
    my $cinder = $cloud->getComponent(name => "Cinder");
    my $lvm = $cloud->getComponent(name => "Lvm");

    $keystone->setConf(conf => {
        mysql5_id   => $sql->id,
    });

    $nova_controller->setConf(conf => {
        mysql5_id   => $sql->id,
        keystone_id => $keystone->id,
        amqp_id     => $amqp->id
    });

    $glance->setConf(conf => {
        mysql5_id          => $sql->id,
        nova_controller_id => $nova_controller->id
    });

    $neutron->setConf(conf => {
        mysql5_id          => $sql->id,
        nova_controller_id => $nova_controller->id
    });

    $cinder->setConf(conf => {
        mysql5_id          => $sql->id,
        nova_controller_id => $nova_controller->id
    });

    my $vg = Lvm2Vg->new(
        lvm2_id           => $lvm->id,
        lvm2_vg_name      => "cinder-volumes",
        lvm2_vg_freespace => 0,
        lvm2_vg_size      => 10 * 1024 * 1024 * 1024
    );

    my $pv = Lvm2Pv->new(
        lvm2_vg_id   => $vg->id,
        lvm2_pv_name => "/dev/sda2"
    );

    diag('Create and configure Nova compute cluster');

    my $vms_netconf = Entity::Netconf->find(hash => { netconf_name => 'Virtual machines bridge' } );
    my $admin_netconf = Entity::Netconf->find(hash => { netconf_name => 'Kanopya admin' });

    my $compute;
    lives_ok {
        $compute = Kanopya::Tools::Create->createCluster(
                       cluster_conf => {
                           cluster_name         => 'Compute',
                           cluster_basehostname => 'compute',
                           masterimage_id       => $masterimage->id
                       },
                       managers => {
                           host_manager => {
                               manager_params => {
                                   deploy_on_disk => 1
                               }
                           }
                       },
                       interfaces => {
                           i1 => {
                               netconfs => { $admin_netconf->id   => $admin_netconf->id },
                               interface_name => 'admin'
                           },
                           i2 => {
                               netconfs => { $vms_netconf->id   => $vms_netconf->id },
                               interface_name => 'vms'
                           },
                       },
                       components => {
                           'novacompute'  => {
                               iaas_id            => $nova_controller->id,
                               libvirt_type       => 'qemu',
                           },
                           'nfsd' => {
                           }
                       }
                   );
    } 'Create Nova Compute cluster';

    my $kanopya = Kanopya::Tools::Retrieve::retrieveCluster();
    my $lvm = EEntity->new(data => $kanopya->getComponent(name => "Lvm"));
    my $nfs = EEntity->new(data => $kanopya->getComponent(name => "Nfsd"));
    my $shared;
    my $export;

    lives_ok {
        $shared = $lvm->createDisk(
                      name       => "nova-instances",
                      size       => 1 * 1024 * 1024 * 1024,
                      filesystem => "ext4",
                  );

        $export = $nfs->createExport(
                       container => $shared,
                       client_name => "*",
                       client_options => "rw,sync,fsid=0,no_root_squash"
                   );
    } "Create computes shared storage";

    my $system = $compute->getComponent(category => "System");

    for my $export ($nfs->container_accesses) {
        $system->addMount(
            mountpoint => "/var/lib/nova/instances",
            filesystem => "nfs",
            options => "vers=3",
            device => $export->container_access_export
        );
    }

    lives_ok {
        my $vm_cluster = Kanopya::Tools::Create->createVmCluster(
                             iaas => $cloud,
                             container_type => 'iscsi',
                             cluster_conf => {
                                 cluster_name         => 'VmCluster',
                                 cluster_basehostname => 'vmcluster',
                                 masterimage_id       => $masterimage->id,
                             }
                         );
    } 'Create VM cluster';

    lives_ok {
        my $cinder_vm = Kanopya::Tools::Create->createVmCluster(
                            iaas => $cloud,
                            container_type => 'iscsi',
                            cluster_conf => {
                                cluster_name         => 'CinderVmCluster',
                                cluster_basehostname => 'cindervm',
                                masterimage_id       => $masterimage->id,
                            },
                            managers => {
                                disk_manager => {
                                    manager_id => $cinder->id,
                                    manager_params => {
                                        systemimage_size => 4 * 1024 * 1024 * 1024,
                                    }
                                },
                                export_manager => {
                                    manager_id => $cinder->id,
                                    manager_params => {
                                    }
                                }
                            }
                        );
    } 'Create VM cluster with Cinder as disk manager manager';

    lives_ok {
        Kanopya::Tools::Execution->startCluster(cluster => $db);
    } 'Start database cluster';

    lives_ok {
        Kanopya::Tools::Execution->startCluster(cluster => $cloud);
    } 'Start Cloud controller cluster';

    lives_ok {
        Kanopya::Tools::Execution->startCluster(cluster => $compute);
    } 'Start Nova Compute cluster';

    if ($testing == 1) {
        Kanopya::Database::rollbackTransaction;
    }
}
