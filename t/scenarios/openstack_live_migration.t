#!/usr/bin/perl -w

=head1 SCOPE

TODO

=head1 PRE-REQUISITE

TODO

=cut

use Test::More 'no_plan';
use Test::Exception;

use Kanopya::Test::OpenStack;

use Log::Log4perl qw(:easy get_logger);
Log::Log4perl->easy_init({
    level=>'DEBUG',
    file=>'openstack_live_migration.t.log',
    layout=>'%d [ %H - %P ] %p -> %M - %m%n'
});

use Kanopya::Database;

my $testing = 0;

main();

sub main {
    Kanopya::Database::authenticate( login =>'admin', password => 'K4n0pY4' );

    if ($testing == 1) {
        Kanopya::Database::beginTransaction;
    }

    Kanopya::Test::OpenStack->start1OpenStackOn3Clusters();

    my $cloud = Entity::ServiceProvider::Cluster->find(hash => { cluster_name => "CloudController" });
    my $compute = Entity::ServiceProvider::Cluster->find(hash => { cluster_name => "Compute" });

    my $vm = Entity::ServiceProvider::Cluster->find(hash => { cluster_name => "VmCluster" });
    my $cinder = Entity::ServiceProvider::Cluster->find(hash => { cluster_name => "CinderVmCluster" });

    lives_ok {
        Kanopya::Test::Execution->startCluster(cluster => $vm);
    } 'Starting VM Cluster';

    lives_ok {
        Kanopya::Test::Execution->startCluster(cluster => $cinder);
    } 'Starting CinderVM Cluster';

    lives_ok {
        Kanopya::Test::Execution->addNode(cluster => $compute);
    } 'Starting a 2nd Compute node';

    my $hypervisor_dst;
    lives_ok {
        $hypervisor_dst = Entity::Node->find(hash => { node_hostname => 'compute2' })->host;
    } 'Retrieve 2nd Compute node';

    my $vm_to_migrate;
    lives_ok {
        $vm_to_migrate = Entity::Node->find(hash => { node_hostname => 'cindervm1' })->host;
    } 'Retrieve cindervm node';

    my $controller = $cloud->getComponent(name => "NovaController");
    lives_ok {
        $controller->migrate(host_id => $vm_to_migrate->id, hypervisor_dst => $hypervisor_dst->id);
    } 'Migrate CinderVM to 2nd Compute';

    if ($testing == 1) {
        Kanopya::Database::rollbackTransaction;
    }
}
