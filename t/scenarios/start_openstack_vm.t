#!/usr/bin/perl -w

=head1 SCOPE

TODO

=head1 PRE-REQUISITE

TODO

=cut

use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Kanopya::Exceptions;
use ClassType::ComponentType;

use File::Basename;
use Log::Log4perl qw(:easy get_logger);
Log::Log4perl->easy_init({
    level  => 'DEBUG',
    file   => basename(__FILE__) . '.log',
    layout => '%d [ %H - %P ] %p -> %M - %m%n'
});

use Kanopya::Database;

use Kanopya::Test::Execution;
use Kanopya::Test::Register;
use Kanopya::Test::Retrieve;
use Kanopya::Test::Create;

use Entity::Component::KanopyaDeploymentManager;

my $testing = 1;

main();

sub main {

    if ($testing == 1) {
        Kanopya::Database::beginTransaction;
    }

    my $localhostname = `hostname`;
    chomp($localhostname);

    diag('Register/get the OpenStack component');
    my $openstack = Kanopya::Test::Register->registerComponentOnNode(
                        componenttype => "OpenStack",
                        hostname      => $localhostname,
                        component_params => {
                        }
                    );

    diag('Create and configure the openstack vm cluster');
    my $cluster;
    lives_ok {
        my $clustername = "openstack_vm_cluster_test_" . time();
        my $create = Entity::ServiceProvider::Cluster->create(
                        active                => 1,
                        cluster_name          => $clustername,
                        cluster_min_node      => 1,
                        cluster_max_node      => 3,
                        cluster_priority      => "100",
                        cluster_si_persistent => 1,
                        cluster_domainname    => 'my.domain',
                        cluster_nameserver1   => '208.67.222.222',
                        cluster_nameserver2   => '127.0.0.1',
                        owner_id              => Entity::User->find(hash => { user_login => 'admin' })->id,
                        managers => {
                            host_manager => {
                                manager_id     => $openstack->id,
                                manager_type   => "HostManager",
                                manager_params => {
                                    flavor => "dummy",
                                    availability_zone => "dummy",
                                    tenant => "dummy",
                                },
                            },
                            storage_manager => {
                                manager_id     => $openstack->id,
                                manager_type   => "StorageManager",
                                manager_params => {
                                    volume_type => "dummy"
                                },
                            },
                            deployment_manager => {
                                manager_id     => Entity::Component::KanopyaDeploymentManager->find()->id,
                                manager_type   => "DeploymentManager",
                                manager_params => {
                                    boot_manager_id => $openstack->id,
                                    components      => {}
                                },
                            },
                            network_manager => {
                                manager_id     => $openstack->id,
                                manager_type   => "NetworkManager",
                                manager_params => {
                                    networks  => "dummy"
                                },
                            },
                        },
                     );

        Kanopya::Test::Execution->executeOne(entity => $create);

        $cluster = Kanopya::Test::Retrieve->retrieveCluster(criteria => { cluster_name => $clustername });
    } 'Create OpenStack VM cluster';

    diag('Start OpenStack VM cluster');
    lives_ok {
        Kanopya::Test::Execution->startCluster(cluster => $cluster);
    } 'Start cluster';

    diag('Stopping OpenStack VM cluster');
    lives_ok {
        my ($state, $timestamp) = $cluster->reload->getState();
        if ($state ne 'up') {
            die "Cluster should be up, not $state";
        }
        Kanopya::Test::Execution->executeOne(entity => $cluster->stop());
    } 'Stopping OpenStack VM cluster';

    diag('Remove OpenStack VM cluster');
    lives_ok {
        Kanopya::Test::Execution->executeOne(entity => $cluster->deactivate());
        Kanopya::Test::Execution->executeOne(entity => $cluster->remove());
    } 'Removing OpenStack VM cluster';

    my @systemimages = Entity::Systemimage->search();
    diag('Check if systemimage have been deleted');
    ok(scalar(@systemimages) == 0);

    if ($testing == 1) {
        Kanopya::Database::rollbackTransaction;
    }
}

1;
