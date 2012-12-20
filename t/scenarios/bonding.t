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
    file=>'/vagrant/Bonding.t.log',
    layout=>'%F %L %p %m%n'
});

use Administrator;
use NetconfVlan;
use Entity::Vlan;
use Entity::ServiceProvider::Inside::Cluster;
use Entity::User;
use Entity::Host;
use Entity::Kernel;
use Entity::Masterimage;
use Entity::Network;
use Entity::Poolip;
use Entity::Operation;
use Entity::Netconf;
use Entity::Iface;
use Externalnode::Node;
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

my $cluster;

Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
my $adm = Administrator->new;

lives_ok {
    if ($testing == 1) {
        $adm->beginTransaction;
    }

    diag('Create and configure cluster');
    _create_and_configure_cluster();
    diag('Start cluster');
    start_cluster();

    if($testing == 1) {
        $adm->rollbackTransaction;
    }
} 'Create, configure and start cluster with bonded interfaces';

sub start_cluster {
    Kanopya::Tools::Execution->execute(entity => $cluster->start());
}

sub _create_and_configure_cluster {
    diag('Retrieve the Kanopya cluster');
    my $kanopya_cluster;
    my $physical_hoster;
    $kanopya_cluster = Kanopya::Tools::Retrieve->retrieveCluster();
    $physical_hoster = $kanopya_cluster->getHostManager();

    diag('Retrieve Lvm component');
    my $disk_manager;
    $disk_manager = EEntity->new(
        entity => $kanopya_cluster->getComponent(
            name    => 'Lvm',
            version => 2
        )
    );

    diag('Retrieving iSCSI component');
    my $export_manager;
    $export_manager = EEntity->new(
        entity => $kanopya_cluster->getComponent(
            name    => 'Iscsitarget',
            version => 1
        )
    );

    diag('Get a kernel for KVM');
    my $kernel;
    $kernel = Entity::Kernel->find(hash => { kernel_name => '3.0.42-0.7-default' });

    diag('Retrieve the admin user');
    my $admin_user;
    $admin_user = Entity::User->find(hash => { user_login => 'admin' });

    diag('Registering physical hosts');
    foreach my $board (@{ $boards }) {
        Kanopya::Tools::Register->registerHost(board => $board);
    }

    diag('Deploy master image');
    my $masterimage;
    my $deploy;
    $deploy = Entity::Operation->enqueue(
                  priority => 200,
                  type     => 'DeployMasterimage',
                  params   => { file_path => "/vagrant/" . ($ENV{'MASTERIMAGE'} || "centos-6.3-opennebula3.tar.bz2"),
                                keep_file => 1 },
    );
    Kanopya::Tools::Execution->execute(entity => $deploy);

    diag('Retrieve KVM master image');
    $masterimage = Entity::Masterimage->find( hash => { } );

    diag('Retrieve admin NetConf');
    my $adminnetconf;
    $adminnetconf	= Entity::Netconf->find(hash => {
        netconf_name    => "Kanopya admin"
    });

    diag('Retrieve admin network');
    my @iscsi_portal_ids;
    for my $portal (Entity::Component::Iscsi::IscsiPortal->search(hash => { iscsi_id => $export_manager->id })) {
        push @iscsi_portal_ids, $portal->id;
    }

    diag('Create cluster');
    my $cluster_create;
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
    Kanopya::Tools::Execution->execute(entity => $cluster_create);


    diag('retrieve Cluster via name');
    $cluster = Kanopya::Tools::Retrieve->retrieveCluster(criteria => {cluster_name => 'Bondage'});

    diag('associate netconf to ifaces');
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

    diag('retrieve file image manager');
    my $fileimagemanager;
    $fileimagemanager = $kanopya_cluster->getComponent(name    => "Fileimagemanager",
                                                       version => 0);
    diag('retrieve Opennebula component');
    my $opennebula;
    $opennebula = $cluster->getComponent(name    => "Opennebula",
                                         version => 3);

    diag('configuring Opennebula image repository');
    $opennebula->setConf(
        conf => {
            image_repository_path => "/srv/cloud/images",
            opennebula3_id        => $opennebula->id,
            hypervisor            => "kvm",
        }
    );
}