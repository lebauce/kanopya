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
    level=>'DEBUG',
    file=>'/tmp/SetupUnmanagedStorageHost.t.log',
    layout=>'%F %L %p %m%n'
});

use Administrator;
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
use Entity::Component::Iscsi::IscsiPortal;
use ComponentType;

use Kanopya::Tools::Execution;
use Kanopya::Tools::Register;
use Kanopya::Tools::Retrieve;
use Kanopya::Tools::TestUtils;

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

main();

sub main {
    Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
    my $adm = Administrator->new;

    if ($testing == 1) {
        $adm->beginTransaction;
    }

    diag('Create and configure cluster');
    _create_and_configure_cluster();

    diag('Start unmanaged iscsi host');
    start_iscsi_host();

    diag('Stop, deactivate and remove unmanaged iscsi host');
    stop_deactivate_and_remove_iscsi_host();

    if($testing == 1) {
        $adm->rollbackTransaction;
    }
}

sub start_iscsi_host {
    lives_ok {
        diag('retrieve Cluster via name');
        my $cluster = Kanopya::Tools::Retrieve->retrieveCluster(criteria => {cluster_name => 'UnmanagedStorageCluster'});

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

sub stop_deactivate_and_remove_iscsi_host {
    lives_ok {
        diag('retrieve Cluster via name');
        my $cluster = Kanopya::Tools::Retrieve->retrieveCluster(criteria => {cluster_name => 'UnmanagedStorageCluster'});
        my $cluster_name = $cluster->cluster_name;
        my $cluster_id = $cluster->id;

        diag('Cluster stop operation');
        Kanopya::Tools::Execution->executeOne(entity => $cluster->forceStop);

        my ($state, $timestemp) = $cluster->getState;
        if ($state eq 'down') {
            diag("Cluster $cluster_name stopped successfully");
        }
        else {
            die "Cluster is not 'down'";
        }

        diag('Cluster deactivate operation');
        Kanopya::Tools::Execution->executeOne(entity => $cluster->deactivate);

        my $active = $cluster->reload->active;
        if ($active == 0) {
            diag("Cluster $cluster_name deactivated successfully");
        }
        else {
            die "Cluster is not deactivated";
        }

        diag('Cluster remove operation')
        Kanopya::Tools::Execution->executeOne(entity => $cluster->remove);

        expectedException {
            $cluster = Entity::ServiceProvider::Inside::Cluster->get(id => $cluster->id);
        } 'Kanopya::Exception::DB',
        "Cluster $cluster_name with id $cluster_id has been successfully removed";
    } 'Stop, deactivate and remove cluster';
}

sub _create_and_configure_cluster {
    diag('Retrieve the Kanopya cluster');
    my $kanopya_cluster = Kanopya::Tools::Retrieve->retrieveCluster();

    diag('Get physical hoster');
    my $physical_hoster = $kanopya_cluster->getHostManager();

    diag('Retrieve disk manager');
    my $disk_manager = EFactory::newEEntity(
                        data => $kanopya_cluster->getComponent(name => "Storage")
    );
    diag('Retrieving generic iSCSI component');
    my $export_manager = EFactory::newEEntity(
                          data => $kanopya_cluster->getComponent(name => "Iscsi")
    );

    diag('Configuring portals of the iSCSI component');
    $export_manager->setConf(conf => {
        iscsi_portals => [
            {
                iscsi_portal_ip   => '10.0.0.1',
                iscsi_portal_port => 3261
            },
            {
                iscsi_portal_ip   => '10.0.0.2',
                iscsi_portal_port => 3261
            }
        ]
    });

    diag('Get a kernel for KVM');
    my $kernel = Entity::Kernel->find(hash => { kernel_name => '2.6.32-279.5.1.el6.x86_64' });

    diag('Retrieve physical hosts');
    my @hosts = Entity::Host->find(hash => { host_manager_id => $physical_hoster->getId });

    diag('Retrieve the admin user');
    $admin_user = Entity::User->find(hash => { user_login => 'admin' });

    diag('Registering physical hosts');
    foreach my $board (@{ $boards }) {
        my $host = Kanopya::Tools::Register->registerHost(board => $board);
    }

    diag('Retrieve admin network');
    my $admin_network = Entity::Network->find( hash => { network_name => 'admin' } );

    diag('Retrieve admin network');
    my @iscsi_portal_ids;
    for my $portal (Entity::Component::Iscsi::IscsiPortal->search(hash => { iscsi_id => $export_manager->id })) {
        push @iscsi_portal_ids, $portal->id;
    }

    diag('Create cluster');
    my $cluster_create = Entity::ServiceProvider::Inside::Cluster->create(
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
    Kanopya::Tools::Execution->executeOne(entity => $cluster_create);
}