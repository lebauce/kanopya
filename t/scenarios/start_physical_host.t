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

use Entity::Systemimage;

my $testing = 0;
my $NB_HYPERVISORS = 1;

main();

sub main {

    if ($testing == 1) {
        Kanopya::Database::beginTransaction;

        Kanopya::Test::Register->registerHost(board => {
            ram  => 1073741824,
            core => 4,
            serial_number => 0,
            ifaces => [ { name => 'eth0', pxe => 1, mac => '00:00:00:00:00:00' } ]
        });
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
            cluster_name => "default_cluster_name_with_maximum_length_of_db_200" .
                            "default_cluster_name_with_maximum_length_of_db_200" .
                            "default_cluster_name_with_maximum_length_of_db_200" .
                            "default_cluster_name_with_maximum_length_of_db_200",
            cluster_conf => {
                masterimage_id => $masterimage->id,
            },
        );
    } 'Create cluster';

    diag('Start physical host');
    lives_ok {
        Kanopya::Test::Execution->startCluster(cluster => $cluster);
    } 'Start cluster';

    diag('Stopping cluster');
    lives_ok {
        my ($state, $timestamp) = $cluster->reload->getState();
        if ($state ne 'up') {
            die "Cluster should be up, not $state";
        }
        Kanopya::Test::Execution->executeOne(entity => $cluster->stop());
    } 'Stopping cluster';

    diag('Remove cluster');
    lives_ok {
        Kanopya::Test::Execution->executeOne(entity => $cluster->deactivate());
        Kanopya::Test::Execution->executeOne(entity => $cluster->remove());
    } 'Removing cluster';

    my @systemimages = Entity::Systemimage->search();
    diag('Check if systemimage have been deleted');
    ok(scalar(@systemimages) == 0);

    if ($testing == 1) {
        Kanopya::Database::rollbackTransaction;
    }
}

1;
