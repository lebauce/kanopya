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
    file=>'/vagrant/Vlan.t.log',
    layout=>'%F %L %p %m%n'
});

use Administrator;
use NetconfVlan;
use Entity::Vlan;
use Entity::ServiceProvider::Inside::Cluster;
use Entity::User;
use Entity::Host;
use Entity::Kernel;
use Entity::Processormodel;
use Entity::Hostmodel;
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
use Kanopya::Tools::TestUtils;

my $testing = 0;

my $NB_HYPERVISORS = 1;
my $boards = [
    {
        ram    => 2048,
        core   => 2,
        ifaces => [
            {
                name => "eth0",
                mac  => "00:11:11:11:11:11",
                pxe  => 1
            },
        ]
    },
];

my $host_id;
main();

sub main {
    Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
    my $adm = Administrator->new;

    if ($testing == 1) {
        $adm->beginTransaction;
    }

    diag('Create and configure cluster');
    _create_and_configure_cluster();

    diag('Start cluster with vlan interfaces');
    start_cluster();

    diag('Stop and remove cluster with vlan interfaces');
    stop_and_remove_cluster();

    if ($testing == 1) {
        $adm->rollbackTransaction;
    }
}

sub start_cluster {
    lives_ok {
        diag('retrieve Cluster via name');
        my $cluster = Kanopya::Tools::Retrieve->retrieveCluster(criteria => {cluster_name => 'Bondage'});

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

sub stop_and_remove_cluster {
    lives_ok {
        diag('retrieve Cluster via name');
        my $cluster = Kanopya::Tools::Retrieve->retrieveCluster(criteria => {cluster_name => 'Bondage'});
        my $cluster_name = $cluster->cluster_name;
        my $cluster_id = $cluster->id;

        diag('Cluster stop operation');
        Kanopya::Tools::Execution->executeOne(entity => $cluster->forceStop);
        my ($state, $timestemp) = $cluster->getState;
        if ($state eq 'down') {
            diag("Cluster $cluster_name stopped successfully");
        }
        else {
            die "Cluster is not 'up'";
        }

        diag('Cluster remove operation');
        Kanopya::Tools::Execution->executeOne(entity => $cluster->remove);
        expectedException {
            $cluster = Entity::ServiceProvider::Inside::Cluster->get(id => $cluster->id);
        } 'Kanopya::Exception::DB',
        "Cluster $cluster_name with id $cluster_id has been successfully removed";
    } 'Stop and remove cluster';
}

sub _create_and_configure_cluster {
    diag('Retrieve the Kanopya cluster');
    my $kanopya_cluster = Kanopya::Tools::Retrieve->retrieveCluster();

    diag('Get physical hoster');
    my $physical_hoster = $kanopya_cluster->getHostManager();

    diag('Retrieving LVM disk manager');
    my $disk_manager = EFactory::newEEntity(
        data => $kanopya_cluster->getComponent(
            name    => "Lvm",
            version => 2
        )
    );

    diag('Retrieving iSCSI component');
    my $export_manager = EFactory::newEEntity(
        data => $kanopya_cluster->getComponent(
            name    => "Iscsitarget",
            version => 1
        )
    );

    diag('Get a kernel');
    my $kernel = Entity::Kernel->find(hash => { kernel_name => $ENV{'KERNEL'} || '3.0.42-0.7-default' });

    diag('Retrieve physical hosts');
    my @hosts = Entity::Host->find(hash => { host_manager_id => $physical_hoster->id });

    diag('Retrieve the admin user');
    my $admin_user = Entity::User->find(hash => { user_login => 'admin' });

    diag('Registering physical hosts');
    foreach my $board (@{ $boards }) {
        my $host = Kanopya::Tools::Register->registerHost(board => $board);
        $host_id = $host->id;
    }

    diag('Deploy master image');
    my $deploy = Entity::Operation->enqueue(
                  priority => 200,
                  type     => 'DeployMasterimage',
                  params   => { file_path => "/vagrant/" . ($ENV{'MASTERIMAGE'} || "centos-6.3-opennebula3.tar.bz2"),
                                keep_file => 1 },
    );
    Kanopya::Tools::Execution->executeOne(entity => $deploy);

    diag('Retrieve master image');
    my $opennebula_masterimage = Entity::Masterimage->find( hash => { } );

    diag('Retrieve admin NetConf');
    my $adminnetconf   = Entity::Netconf->find(hash => {
        netconf_name    => "Kanopya admin"
    });

    diag('Retrieve iSCSI portals');
    my @iscsi_portal_ids;
    for my $portal (Entity::Component::Iscsi::IscsiPortal->search(hash => { iscsi_id => $export_manager->id })) {
        push @iscsi_portal_ids, $portal->id;
    }

    diag('Create cluster');
    my $cluster_create = Entity::ServiceProvider::Inside::Cluster->create(
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
        masterimage_id         => $opennebula_masterimage->id,
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
        },
        interfaces => {
        },
    );
    Kanopya::Tools::Execution->executeOne(entity => $cluster_create);

    diag('add two vlans to admin netconf');
	my $vlan1 = Entity::Vlan->new(vlan_name => 'prodvlan1', vlan_number => '20');
	my $vlan2 = Entity::Vlan->new(vlan_name => 'prodvlan2', vlan_number => '50');
	NetconfVlan->new(netconf_id => $adminnetconf->id, vlan_id => $vlan1->id);
	NetconfVlan->new(netconf_id => $adminnetconf->id, vlan_id => $vlan2->id);
}