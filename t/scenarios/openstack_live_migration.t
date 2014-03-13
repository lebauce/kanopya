#!/usr/bin/perl -w

=head1 SCOPE

TODO

=head1 PRE-REQUISITE

TODO

=cut

use Test::More 'no_plan';
use Test::Exception;

use Kanopya::Tools::OpenStack;

use Log::Log4perl qw(:easy get_logger);
Log::Log4perl->easy_init({
    level=>'DEBUG',
    file=>'openstack_live_migration.t.log',
    layout=>'%F %L %p %m%n'
});

use Kanopya::Database;

my $testing = 0;

main();

sub main {
    Kanopya::Database::authenticate( login =>'admin', password => 'K4n0pY4' );

    if ($testing == 1) {
        Kanopya::Database::beginTransaction;
    }

    Kanopya::Tools::OpenStack->start1OpenStackOn3Clusters();

    my $cloud = Entity::ServiceProvider::Cluster->find(hash => { cluster_name => "CloudController" });
    my $compute = Entity::ServiceProvider::Cluster->find(hash => { cluster_name => "Compute" });
    my $cinder = Entity::ServiceProvider::Cluster->find(hash => { cluster_name => "CinderVmCluster" });
    
    lives_ok {
        Kanopya::Tools::Execution->startCluster(cluster => $cinder);
    } 'Starting CinderVM Cluster';

    lives_ok {
        Kanopya::Tools::Execution->addNode(cluster => $compute);
    } 'Starting a 2nd Compute node';
    
    $controller = $cloud->getComponent(name => "NovaController");
    lives_ok {
        $controller->migrateHost( host => 'cindervm1', hypervisor_dst => 'compute2');
    } 'Migrate CinderVM to 2nd Compute';

    if ($testing == 1) {
        Kanopya::Database::rollbackTransaction;
    }
}
