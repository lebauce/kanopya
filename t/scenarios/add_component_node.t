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

use Log::Log4perl qw(:easy get_logger);
Log::Log4perl->easy_init({
    level=>'DEBUG',
    file=>'start_physical_host.t.log',
    layout=>'%F %L %p %m%n'
});

use BaseDB;
use Entity::ServiceProvider::Cluster;
use Entity::User;
use Entity::Kernel;
use Entity::Processormodel;
use Entity::Hostmodel;
use Entity::Masterimage;
use Entity::Network;
use Entity::Netconf;
use Entity::Poolip;
use Entity::Operation;
use Kanopya::Tools::Execution;
use Kanopya::Tools::Register;
use Kanopya::Tools::Retrieve;
use Kanopya::Tools::Create;

my $testing = 0;

main();

sub main {

    if ($testing == 1) {
        BaseDB->beginTransaction;
    }

    diag('Register master image');
    lives_ok {
        Kanopya::Tools::Register::registerMasterImage();
    } 'Register master image';

    diag('Create and configure cluster');
    my $cluster;
    lives_ok {
        $cluster = Kanopya::Tools::Create->createCluster();
    } 'Create cluster';

    diag('Start host');
    lives_ok {
        Kanopya::Tools::Execution->startCluster(cluster => $cluster);
    } 'Start cluster';

    my ($node1, $node2);
    diag('Add 2 nodes with some components on each');
    lives_ok {
        my $sql = $cluster->getComponent(name => 'Mysql');
        my $puppetagent = $cluster->getComponent(name => 'Puppetagent');
        $node1 = Kanopya::Tools::Execution->addNode(cluster => $cluster, component_types => [$sql->id, $puppetagent->id]);
        $node2 = Kanopya::Tools::Execution->addNode(cluster => $cluster, component_types => [$sql->id, $puppetagent->id]);
    } 'Add nodes';

    diag("Adding other components to nodes");
    lives_ok {
        my @component_types = $cluster->getComponents(category => 'DiskManager');
        $cluster->addComponents(
            nodes => [$node1, $node2],
            component_types => @component_types,
        );
    } 'Add components to node';

    if ($testing == 1) {
        BaseDB->rollbackTransaction;
    }
}

1;