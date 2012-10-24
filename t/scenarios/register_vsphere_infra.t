#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;     
use Data::Dumper;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'/tmp/VSphere.t.log', layout=>'%F %L %p %m%n'});

use_ok ('Administrator');
use_ok ('Executor');
use_ok ('EFactory');
use_ok ('Entity::ServiceProvider::Inside::Cluster');
use_ok ('Entity::User');
use_ok ('Entity::Kernel');
use_ok ('Entity::Processormodel');
use_ok ('Entity::Hostmodel');
use_ok ('Entity::Masterimage');
use_ok ('Entity::Network');
use_ok ('Entity::Poolip');
use_ok ('Entity::Host');
use_ok ('Entity::Operation');
use_ok ('Entity::Container');
use_ok ('Entity::ContainerAccess');
use_ok ('Entity::ContainerAccess::NfsContainerAccess');
use_ok ('Externalnode::Node');
use_ok ('ComponentType');
use_ok ('Entity::InterfaceRole');

my $testing = 0;

my $boards = [
    {
        ram  => 2048,
        core => 2,
        nics => [
            {
                name => "eth0",
                mac  => "68:05:ca:0a:71:cf",
                pxe  => 0
            },
        ]
    },
];

eval {
    Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
    my $adm = Administrator->new;

    if ($testing == 1) {
        $adm->beginTransaction;
    }

    my @args = ();
    my $executor = new_ok("Executor", \@args, "Instantiate an executor");

    my $kanopya_cluster;
    my $physical_hoster;
    lives_ok {
        $kanopya_cluster = Entity::ServiceProvider::Inside::Cluster->find(
                               hash => { cluster_name => 'kanopya' });
        $physical_hoster = $kanopya_cluster->getHostManager();
    } 'Retrieve Kanopya cluster';

    isa_ok ($kanopya_cluster, 'Entity::ServiceProvider::Inside::Cluster');
    isa_ok ($physical_hoster, 'Entity::Component::Physicalhoster0');

    my $disk_manager;
    lives_ok {
        $disk_manager = EFactory::newEEntity(
                            data => $kanopya_cluster->getComponent(name    => "Lvm",
                                                                   version => 2)
                        );
    } 'Retrieving LVM component';

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

    my $nfs;
    eval {
        $nfs = Entity::ContainerAccess::NfsContainerAccess->find (hash => {
            container_access_ip     => $kanopya_cluster->getMasterNodeIp,
            container_access_export => $kanopya_cluster->getMasterNodeIp . ":/nfsexports/new_img_repo"
        });
    };
    
    if ($@) {
      my $image_disk;
        lives_ok {
            $image_disk = $disk_manager->createDisk(
                name         => "new_img_repo",
                size         => 6 * 1024 * 1024 * 1024,
                filesystem   => "ext3",
                vg_id        => 1
            )->_getEntity;
        } 'Creating disk for image repository';
      
    	lives_ok {
            $nfs = $nfs_manager->createExport(
                container      => $image_disk,
                export_name    => "new_img_repo",
                client_name    => "*",
                client_options => "rw,sync,no_root_squash"
            );
            #CHEAT: give the nfs container access the location of 192.168.0.173 export
            $nfs->setAttr(name => 'container_access_export', value => '192.168.0.173:/nfsexports/nas');
            $nfs->setAttr(name => 'container_access_ip', value => '192.168.0.173');
            $nfs->save();
      	} 'Creating export for image repository';
    }

    my $vm_masterimage;
    eval {
        $vm_masterimage = Entity::Masterimage->find( hash => {
                              masterimage_name => { like => "%squeeze%" }
                          } );
    };
    if ($@) {
    	lives_ok {
          Entity::Operation->enqueue(
           	priority => 200,
            	type     => 'DeployMasterimage',
            	params   => { file_path => "/vagrant/squeeze-amd64-xenvm.tar.bz2",
               	              keep_file => 1 },
        	);
    	} 'Deploy Virtual machine master image';
    
       lives_ok { $executor->oneRun; } 'DeployMasterimage operation execution succeed';
       lives_ok { $executor->oneRun; } 'DeployMasterimage operation execution succeed';

        $vm_masterimage = Entity::Masterimage->find( hash => {
                              masterimage_name => { like => "%squeeze%" }
                          } );
	}

    #exit 0 if (!$testing);

    my $kernel;
    lives_ok {
        $kernel = Entity::Kernel->find(hash => { kernel_name => '2.6.32-5-xen-amd64' });
    } 'Get a kernel for Xen';

    my @hosts;
    lives_ok { 
        @hosts = Entity::Host->find(hash => { host_manager_id => $physical_hoster->getId });
    } 'Retrieve physical hosts';	

    my $admin_user;
    lives_ok {
        $admin_user = Entity::User->find(hash => { user_login => 'admin' });
     } 'Retrieve the admin user';

    my $host;
    #$host = Entity::Host->find(hash => { host_id => 100 });
    lives_ok {
      for my $board (@{$boards}) {
           $host = Entity::Host->new(
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
            cluster_name           => "VSphere",
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
            user_id                => $admin_user->getAttr(name => 'user_id'),
            managers               => {
                host_manager => {
                    manager_id     => $physical_hoster->getId,
                    manager_type   => "host_manager",
                    manager_params => {
                        cpu        => 1,
                        ram        => 512,
                        ram_unit   => 'M',
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
                vsphere5 => {
                    component_type => ComponentType->find(hash => {
                                          component_name => "Vsphere"
                    				  } )->id
                }
            },
            interfaces             => {
                admin => {
                    interface_role => $interface_role->getId,
                    interface_networks => [ $admin_network->getId ],
                }
            }
        );
      } 'AddCluster operation enqueue';

    lives_ok { $executor->oneRun; } 'AddCluster operation execution succeed';
    lives_ok { $executor->oneRun; } 'AddCluster operation execution succeed';

    #$DB::single = 1;
    my ($cluster, $cluster_id);
    lives_ok {
        $cluster = Entity::ServiceProvider::Inside::Cluster->getCluster(
                       hash => { cluster_name => 'VSphere'}
                   );
    } 'retrieve Cluster via name';

    isa_ok($cluster, 'Entity::ServiceProvider::Inside::Cluster');

    #lives_ok {
    #    $cluster->setAttr(name => 'service_template_id', value => 1);
    #    $cluster->save();
    #} 'associate a service template to the hypervisor cluster';

    lives_ok {
        # dirty way to get $cluster admin interface
        my $admin_if = Entity::Interface->find(hash => {
            service_provider_id => $cluster->id,
            interface_role_id   => Entity::InterfaceRole->find(hash => {
                                       interface_role_name => 'admin',
                                   } )->id,
        } );

        # associate the iface to the cluster admin interface
        my $iface = Entity::Iface->find(hash => { host_id => $host->id });
        $iface->setAttr(name  => 'interface_id',
                        value => $admin_if->id);
        $iface->save();
    } 'associate cluster admin interface to host iface';

    my $externalnode;
    lives_ok {
        $externalnode = Externalnode::Node->new(
                            inside_id   => $cluster->id,
                            host_id     => $host->id,
                            master_node => 1,
                            node_number => 1,
                            node_state  => 'in:1344944117',
                            externalnode_hostname => 'vsphere01'
                        );
    } 'create node from hypervisor cluster and host';

    my $fileimagemanager;
    lives_ok {
        $fileimagemanager = $kanopya_cluster->getComponent(name    => "Fileimagemanager",
                                                           version => 0);
        $fileimagemanager->setAttr( name => 'image_type', value => 'vmdk');
        $fileimagemanager->save();


    } 'retrieve file image manager';

    my $vsphere;
    lives_ok {
        $vsphere = $cluster->getComponent(name    => "Vsphere",
                                             version => 5);
    } 'retrieve Vsphere component';

    lives_ok {
        $vsphere->setConf(conf => {
            login    => 'Administrator@hedera.forest',
            password => 'H3d3r4#234',
            url      => '192.168.1.160',

            repositories => {
                'image_repo' => {
                    container_access_id   => $nfs->id,
                }
            }
        });
    } 'configuring VSphere image repository';

    my $datacenter;
    lives_ok {
        $datacenter = $vsphere->registerDatacenter( 
                          name => 'TortueCenter'
                      );
    
    } 'register a new datacenter in the vsphere component';

    lives_ok {
        $vsphere->addHypervisor(host          => $host,
                                datacenter_id => $datacenter->id,
        );
    } 'promote hypervisor host to Vsphere5Hypervisor';
};    

if($@) {
    my $error = $@; 
    print $error."\n";
}
