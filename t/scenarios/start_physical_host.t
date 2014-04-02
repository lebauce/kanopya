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
    file=>'start_physical_host.t.log',
    layout=>'%F %L %p %m%n'
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
use Entity::Systemimage;

use Kanopya::Tools::Execution;
use Kanopya::Tools::Register;
use Kanopya::Tools::Retrieve;
use Kanopya::Tools::Create;

my $testing = 0;
my $NB_HYPERVISORS = 1;

main();

sub main {

    if ($testing == 1) {
        Kanopya::Database::beginTransaction;

        Kanopya::Tools::Register->registerHost(board => {
            ram  => 1073741824,
            core => 4,
            serial_number => 0,
            ifaces => [ { name => 'eth0', pxe => 1, mac => '00:00:00:00:00:00' } ]
        });
    }

    diag('Register master image');
    my $masterimage;
    lives_ok {
        $masterimage = Kanopya::Tools::Register::registerMasterImage();
    } 'Register master image';

    diag('Create and configure cluster');
    my $cluster;
    lives_ok {
        $cluster = Kanopya::Tools::Create->createCluster(
            cluster_name => "default_cluster_name_with_maximum_length_of_db_200" .
                            "default_cluster_name_with_maximum_length_of_db_200" .
                            "default_cluster_name_with_maximum_length_of_db_200" .
                            "default_cluster_name_with_maximum_length_of_db_200"
            cluster_conf => {
                masterimage_id => $masterimage->id,
            },
        );
    } 'Create cluster';

    diag('Start physical host');
    lives_ok {
        Kanopya::Tools::Execution->startCluster(cluster => $cluster);
    } 'Start cluster';

    diag('Stopping cluster');
    lives_ok {
        Kanopya::Tools::Execution->executeOne(entity => $cluster->stop());
        Kanopya::Tools::Execution->executeAll(timeout => 3600);
    } 'Stopping cluster';

    diag('Remove cluster');
    lives_ok {
        Kanopya::Tools::Execution->executeOne(entity => $cluster->deactivate());
        Kanopya::Tools::Execution->executeOne(entity => $cluster->remove());
        Kanopya::Tools::Execution->executeAll(timeout => 3600);
    } 'Removing cluster';

    my @systemimages = Entity::Systemimage->search();
    diag('Check if systemimage have been deleted');
    ok(scalar(@systemimages) == 0);

    if ($testing == 1) {
        Kanopya::Database::rollbackTransaction;
    }
}

1;
