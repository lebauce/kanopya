#!/usr/bin/perl -w

use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;

use Log::Log4perl qw(:easy get_logger);
Log::Log4perl->easy_init({
    level=>'DEBUG',
    file=>'/vagrant/Bonding.t.log',
    layout=>'%F %L %p %m%n'
});

use_ok ('Administrator');
use_ok ('NetconfVlan');
use_ok ('Entity::Vlan');
use_ok ('Entity::ServiceProvider::Inside::Cluster');
use_ok ('Entity::User');
use_ok ('Entity::Host');
use_ok ('Entity::Kernel');
use_ok ('Entity::Masterimage');
use_ok ('Entity::Network');
use_ok ('Entity::Poolip');
use_ok ('Entity::Operation');
use_ok ('Entity::Netconf');
use_ok ('Entity::Iface');
use_ok ('Externalnode::Node');
use Kanopya::Tools::Execution;
use Kanopya::Tools::Register;
use Kanopya::Tools::Retrieve;

my $testing = 0;
my $NB_HYPERVISORS = 1;
my $boards = [
    {
        ram    => 4,
        core   => 2,
        ifaces => [
            {
                name => "eth0",
                mac  => "00:11:22:33:44:55",
                pxe  => 1
            },
            {
                name => "eth1",
                mac  => "66:77:88:99:00:aa",
                pxe  => 0,
		        master => 'bond0',
            },
            {
                name => "eth2",
                mac  => "66:87:88:99:00:aa",
                pxe  => 0,
        		master => 'bond0',
            },
            {
                name => "bond0",
                mac  => "66:89:88:99:00:aa",
                pxe  => 0,
            },
        ]
    },
];

my @interfaces = (
    {
	name	=> 'face_one',
	bond_nb => 0,
    },
);

eval {
    Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
    my $adm = Administrator->new;
    my $db = $adm->{db};
    
    if ($testing) {
        $adm->beginTransaction;
    }

    my $kanopya_cluster;
    my $physical_hoster;
    lives_ok {
        $kanopya_cluster = Kanopya::Tools::Retrieve->retrieveCluster();
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

    my $admin_user;
    lives_ok {
        $admin_user = Entity::User->find(hash => { user_login => 'admin' });
    } 'Retrieve the admin user';

    lives_ok {
        foreach my $board (@{ $boards }) {
            Kanopya::Tools::Register->registerHost(board => $board);
        };
    } 'Registering physical hosts';

    my $masterimage;
    my $deploy;
    lives_ok {
        $deploy = Entity::Operation->enqueue(
                      priority => 200,
                      type     => 'DeployMasterimage',
                      params   => { file_path => "/vagrant/" . ($ENV{'MASTERIMAGE'} || "centos-6.3-opennebula3.tar.bz2"),
                                    keep_file => 1 },
                  );
    } 'Deploy master image';

    Kanopya::Tools::Execution->execute(entity => $deploy);

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

    my $cluster_create;
    lives_ok {
        $cluster_create = Entity::ServiceProvider::Inside::Cluster->create(
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
                                          ram        => 4 * 1024 * 1024,
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
                                  public => {
                                      interface_netconfs  => { $adminnetconf->id => $adminnetconf->id },
                                          bonds_number => 2
                                  },
                              },
                          );
    } 'AddCluster operation enqueue';

    Kanopya::Tools::Execution->execute(entity => $cluster_create); 

    my $cluster;
    lives_ok {
        $cluster = Kanopya::Tools::Retrieve->retrieveCluster(criteria => {cluster_name => 'Bondage'});
    } 'retrieve Cluster via name';

    isa_ok($cluster, 'Entity::ServiceProvider::Inside::Cluster');     
   
    lives_ok {
	    my @c_interfaces = Entity::Interface->search(hash => {service_provider_id => $cluster->id});
    	my $hosts = $cluster->getHosts;
	    foreach my $host (values %$hosts) {
	        my @ifaces = Entity::Ifaces->search(hash => {host_id => $host->id});
    	    my @simple_ifaces = grep {scalar @{ $_->slaves } == 0 && !$_->master } @ifaces;
	        my @bonded = grep {scalar @{ $_->slaves } > 0 || defined $_->master } @ifaces;
	        foreach my $interface (@c_interfaces) {
    		    my @netconfs = $interface->netconfs;
    	    	if (!$interface->bonds_number || $interface->bonds_number == 0) {
                    foreach my $simple_iface (@simple_ifaces) {
	    	            foreach my $netconf (@netconfs) {
		    	            NetconfIface->new(netconf_id => $netconf->id,
			    	                    	  iface_id   => $simple_iface->id);
		                }
                    }
    		    }
	    	    else {
                    foreach my $bonded (@bonded) {
                        foreach my $netconf (@netconfs) {
                            NetconfIface->new(netconf_id => $netconf->id,
                                              iface_id   => $bonded->id);
                        }
                    }
                }
            }
        }
    } 'associate netconf to ifaces';

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
        $opennebula->setConf(
            conf => {
                image_repository_path => "/srv/cloud/images",
                opennebula3_id        => $opennebula->id,
                hypervisor            => "kvm",
            }
        );
    } 'configuring Opennebula image repository';

    Kanopya::Tools::Execution->execute(entity => $cluster->start());
};
if($@) {
    my $error = $@;
    print $error."\n";
};
