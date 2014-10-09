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

use Log::Log4perl qw(:easy get_logger);
Log::Log4perl->easy_init({
    level=>'DEBUG',
    file=>'rabbitmq_clusterization.t.log',
    layout=>'%d [ %H - %P ] %p -> %M - %m%n'
});

use Kanopya::Database;
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

use Kanopya::Test::Execution;
use Kanopya::Test::Register;
use Kanopya::Test::Retrieve;
use Kanopya::Test::Create;

my $testing = 0;
my $NB_HYPERVISORS = 1;

main();

sub main {

    if ($testing == 1) {
        Kanopya::Database::beginTransaction;
    }

    diag('Register master image');
    my $masterimage;
    lives_ok {
        $masterimage = Kanopya::Test::Execution::registerMasterImage();
    } 'Register master image';

    diag('Create and configure cluster');
    my $cluster;
    lives_ok {
        $cluster = Kanopya::Test::Create->createCluster(
                       components => {
                           'amqp' => {}
                       },
                       cluster_conf => {
                           cluster_name => 'RabbitMQ',
                           cluster_min_node => 2,
                           masterimage_id => $masterimage->id
                       }
                   );
    } 'Create cluster';

    diag('Start RabbitMQ cluster with 2 nodes');
    lives_ok {
        Kanopya::Test::Execution->startCluster(cluster => $cluster);
    } 'Start cluster';

    if ($testing == 1) {
        Kanopya::Database::rollbackTransaction;
    }
}

1;
