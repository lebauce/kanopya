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
    layout=>'%F %L %p %m%n'
});

use Kanopya::Database;

use Kanopya::Tools::Create;
use Kanopya::Tools::Execution;
use Kanopya::Tools::Register;

main();

sub main {

    diag('Register master image');
    my $masterimage = Kanopya::Tools::Register::registerMasterImage();

    diag('Create and configure a service instance with one node');
    my $cluster = Kanopya::Tools::Create->createCluster(
        cluster_conf => {
            cluster_min_node => 1,
            cluster_max_node => 1,
            masterimage_id => $masterimage->id,
        },
    );

    diag('Start instance');
    lives_ok {
        Kanopya::Tools::Execution->startCluster(cluster => $cluster);
    } 'Start instance';

    diag('Stop instance');
    lives_ok {
        my ($state, $timestamp) = $cluster->reload->getState();
        if ($state ne 'up') {
            die "Cluster should be up, not $state";
        }
        Kanopya::Tools::Execution->executeOne(entity => $cluster->stop());
        Kanopya::Tools::Execution->executeAll(timeout => 3600);
    } 'Stopping instance';

    diag('Restart instance');
    lives_ok {
        Kanopya::Tools::Execution->startCluster(cluster => $cluster);
    } 'Restart instance';

    diag('Restop instance');
    lives_ok {
        my ($state, $timestamp) = $cluster->reload->getState();
        if ($state ne 'up') {
            die "Cluster should be up, not $state";
        }
        Kanopya::Tools::Execution->executeOne(entity => $cluster->stop());
        Kanopya::Tools::Execution->executeAll(timeout => 3600);
    } 'Restop instance';
}

1;
