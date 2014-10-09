#!/usr/bin/perl -w

use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Kanopya::Exceptions;
use ClassType::ComponentType;

use Log::Log4perl qw(:easy get_logger);
Log::Log4perl->easy_init({
    level=>'DEBUG',
    file=>'start_stop_restart_service.t.log',
    layout=>'%d [ %H - %P ] %p -> %M - %m%n'
});

use Kanopya::Database;

use Kanopya::Test::Create;
use Kanopya::Test::Execution;
use Kanopya::Test::Register;

main();

sub main {

    diag('Register master image');
    my $masterimage = Kanopya::Test::Execution::registerMasterImage();

    diag('Create and configure a service instance with one node');
    my $cluster = Kanopya::Test::Create->createCluster(
        cluster_conf => {
            cluster_min_node => 1,
            cluster_max_node => 1,
            masterimage_id => $masterimage->id,
        },
    );

    diag('Start instance');
    lives_ok {
        Kanopya::Test::Execution->startCluster(cluster => $cluster);
    } 'Start service instance';

    diag('Stop instance');
    lives_ok {
        my ($state, $timestamp) = $cluster->reload->getState();
        if ($state ne 'up') {
            die "Cluster should be up, not $state";
        }

        Kanopya::Test::Execution->executeOne(entity => $cluster->stop());
        Kanopya::Test::Execution->executeAll(timeout => 3600);
    } 'Stopping service instance';

    diag('Restart instance');
    lives_ok {
        Kanopya::Test::Execution->startCluster(cluster => $cluster);
    } 'Restart service instance';

    diag('Restop instance');
    lives_ok {
        my ($state, $timestamp) = $cluster->reload->getState();
        if ($state ne 'up') {
            die "Cluster should be up, not $state";
        }

        Kanopya::Test::Execution->executeOne(entity => $cluster->stop());
        Kanopya::Test::Execution->executeAll(timeout => 3600);
    } 'Restop service instance';
}

1;
