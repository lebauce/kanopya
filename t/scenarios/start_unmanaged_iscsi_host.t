#!/usr/bin/perl -w

=head1 SCOPE

TODO

=head1 PRE-REQUISITE

TODO

=cut

use Test::More 'no_plan';
use Test::Exception;
use Kanopya::Exceptions;

use File::Basename;
use Log::Log4perl qw(:easy get_logger);
Log::Log4perl->easy_init({
    level  => 'INFO',
    file   => basename(__FILE__) . '.log',
    layout => '%F %L %p %m%n'
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
use Entity::Poolip;
use Entity::Operation;
use IscsiPortal;
use ClassType::ComponentType;
use Entity::Component::DummyHostManager;

use Kanopya::Tools::Execution;
use Kanopya::Tools::Register;
use Kanopya::Tools::Retrieve;
use Kanopya::Tools::TestUtils 'expectedException';

use String::Random;

my $random = String::Random->new;
my $cluster_name = $random->randpattern("nnCccCCnnncCCnncnCCn");

my $testing = 0;

main();

sub main {
    if ($testing == 1) {
        Kanopya::Database::beginTransaction;
    }


    diag('Create and configure cluster');
    _create_and_configure_cluster();

    diag('Start unmanaged iscsi host');
    start_iscsi_host();

    diag('Stop, deactivate and remove unmanaged iscsi host');
    stop_deactivate_and_remove_iscsi_host();

    diag('Create and configure cluster');
    _create_and_configure_cluster();

    diag('Start unmanaged iscsi host');
    start_iscsi_host();

    diag('Force stop, deactivate and remove unmanaged iscsi host');
    stop_deactivate_and_remove_iscsi_host(force => 1);

    if ($testing == 1) {
        Kanopya::Database::rollbackTransaction;
    }
}

sub start_iscsi_host {
    lives_ok {
        diag('retrieve Cluster via name');
        my $cluster = Kanopya::Tools::Retrieve->retrieveCluster(criteria => {cluster_name => $cluster_name});

        diag('Cluster start operation');
        Kanopya::Tools::Execution->executeOne(entity => $cluster->start());

        my ($state, $timestemp) = $cluster->reload->getState;
        if ($state eq 'up') {
            diag("Cluster " . $cluster->cluster_name . " started successfully");
        }
        else {
            die "Cluster is not 'up'";
        }
    } 'Start cluster';
}

sub stop_deactivate_and_remove_iscsi_host {
    my (%args) = @_;

    lives_ok {
        diag('retrieve Cluster via name');
        my $cluster = Kanopya::Tools::Retrieve->retrieveCluster(criteria => {cluster_name => $cluster_name});
        my $cluster_name = $cluster->cluster_name;
        my $cluster_id = $cluster->id;

        diag('Cluster stop operation');
        Kanopya::Tools::Execution->executeOne(entity => $args{force} ? $cluster->forceStop : $cluster->stop);

        my ($state, $timestemp) = $cluster->reload->getState;
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

        diag('Cluster remove operation');
        Kanopya::Tools::Execution->executeOne(entity => $cluster->remove);

        expectedException {
            $cluster = Entity::ServiceProvider::Cluster->get(id => $cluster->id);
        } 'Kanopya::Exception::Internal::NotFound',
        "Cluster $cluster_name with id $cluster_id has been successfully removed";
    } 'Stop, deactivate and remove cluster';
}

sub _create_and_configure_cluster {
    diag('Retrieve the Kanopya cluster');
    my $kanopya_cluster = Kanopya::Tools::Retrieve->retrieveCluster();

    diag('Get physical hoster');
    my $dummy_host_manager = Entity::Component::DummyHostManager->find;

    diag('Retrieve disk manager');
    my $disk_manager = EEntity->new(
                           data => $kanopya_cluster->getComponent(name => "Storage")
                       );

    diag('Retrieving generic iSCSI component');
    my $export_manager = EEntity->new(
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

#    diag('Get a kernel for KVM');
#    my $kernel = Entity::Kernel->find(hash => { kernel_name => '2.6.32-279.5.1.el6.x86_64' });

    diag('Retrieve the admin user');
    $admin_user = Entity::User->find(hash => { user_login => 'admin' });

    diag('Retrieve admin network');
    my $admin_network = Entity::Network->find( hash => { network_name => 'admin' } );

    diag('Retrieve admin network');
    my @iscsi_portal_ids;
    for my $portal (IscsiPortal->search(hash => { iscsi_id => $export_manager->id })) {
        push @iscsi_portal_ids, $portal->id;
    }

    diag('Retrieve admin NetConf');
    my $adminnetconf = Entity::Netconf->find(hash => {
                           netconf_name => "Kanopya admin"
                       });

    diag('Create cluster');
    my $cluster_def = {
        active                 => 1,
        cluster_name           => $cluster_name,
        kernel_id              => Entity::Kernel->find()->id,
        cluster_min_node       => "1",
        cluster_max_node       => "3",
        cluster_priority       => "100",
        cluster_si_persistent  => 1,
        cluster_domainname     => 'my.domain',
        cluster_basehostname   => $random->randpattern("nnccnnncnncnn"),
        cluster_nameserver1    => '208.67.222.222',
        cluster_nameserver2    => '127.0.0.1',
        # cluster_boot_policy    => 'PXE Boot via ISCSI',
        owner_id               => $admin_user->id,
        managers               => {
            host_manager => {
                manager_id     => $dummy_host_manager->id,
                manager_type   => "HostManager",
                manager_params => {
                    cpu        => 1,
                    ram        => 512 *1024 *1024,
                }
            },
            disk_manager => {
                manager_id       => $disk_manager->id,
                manager_type     => "DiskManager",
                manager_params   => {
                    vg_id => 1,
                    systemimage_size => 4 * 1024 * 1024 * 1024
                },
            },
            export_manager => {
                manager_id       => $export_manager->id,
                manager_type     => "ExportManager",
                manager_params   => {
                    iscsi_portals => \@iscsi_portal_ids,
                    target        => 'dummytarget',
                    lun           => 0
                }
            },
        },
        interfaces => {
            eth0 => {
                interface_name => 'eth0',
                netconfs  => { $adminnetconf->id => $adminnetconf->id },
            }
        },
    };

    for my $component_name ("Puppetagent", "Debian") {
        $cluster_def->{components}->{$component_name} = {
            component_type => ClassType::ComponentType->find(hash => {
                                   component_name => $component_name
                              })->id,
        };
    }
    my $cluster_create = Entity::ServiceProvider::Cluster->create(%$cluster_def);

    Kanopya::Tools::Execution->executeOne(entity => $cluster_create);
}
