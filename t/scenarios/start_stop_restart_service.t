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

    diag('Start service instance');
    lives_ok {
        Kanopya::Tools::Execution->startCluster(cluster => $cluster);
    } 'Start service instance';

    diag('Stop service instance');
    lives_ok {
        Kanopya::Tools::Execution->executeOne(entity => $cluster->stop());
        Kanopya::Tools::Execution->executeAll(timeout => 3600);
    } 'Stopping service instance';

    diag('Restart service instance');
    lives_ok {
        Kanopya::Tools::Execution->startCluster(cluster => $cluster);
    } 'Restart service instance';

    diag('Restop service instance');
    lives_ok {
        Kanopya::Tools::Execution->executeOne(entity => $cluster->stop());
        Kanopya::Tools::Execution->executeAll(timeout => 3600);
    } 'Restop service instance';
}

1;
