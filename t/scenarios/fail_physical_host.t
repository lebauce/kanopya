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
    level  => 'INFO',
    file   => __FILE__ . '.log',
    layout => '%d [ %H - %P ] %p -> %M - %m%n'
});

use Kanopya::Database;

use Entity::ServiceProvider::Cluster;

use Kanopya::Tools::Execution;
use Kanopya::Tools::Register;
use Kanopya::Tools::Retrieve;
use Kanopya::Tools::Create;

use Entity::Systemimage;

my $testing = 0;

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
                       cluster_name => "default_cluster_name",
                       cluster_conf => {
                           cluster_min_node => 2,
                           masterimage_id   => $masterimage->id,
                       },
                   );
    } 'Create cluster';

    # Dynamically modify the EHost class to raise exception at postStart.
    use_ok ('EEntity::EHost');

    my ($prereport, $postreport) = (0, 0);
    sub EEntity::EHost::postStart {
        my ($self, %args) = @_;

        if ($self->node->node_number == 2) {
            throw Kanopya::Exception(error => "Second node fail !"); 
        }
    }

    diag('Start physical host that should fail');
    throws_ok {
        Kanopya::Tools::Execution->startCluster(cluster => $cluster);
    } 'Kanopya::Exception::Internal', 'Start cluster';

    lives_ok {
        my ($state, $timestamp) = $cluster->reload->getState();
        if ($state ne 'down') {
            die "Cluster should be down, not $state";
        }
    } 'Cluser should be down';

    diag('Check if systemimage have been deleted');
    my @nodes = $cluster->nodes;
    ok(scalar(@nodes) == 0, "The cluster should have no nodes");

    if ($testing == 1) {
        Kanopya::Database::rollbackTransaction;
    }
}

1;
