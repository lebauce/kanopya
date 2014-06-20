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

use Entity::ServiceProvider::Cluster;

use Kanopya::Test::Execution;
use Kanopya::Test::Register;
use Kanopya::Test::Retrieve;
use Kanopya::Test::Create;

use Entity::Systemimage;

my $testing = 0;

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
                       cluster_name => "default_cluster_name",
                       cluster_conf => {
                           cluster_min_node => 2,
                           masterimage_id   => $masterimage->id,
                       },
                   );
    } 'Create cluster';

    # Dynamically modify the EHost class to raise exception at postStart.
    use_ok ('EEntity::EHost');

    my $fail_from_test = 0;
    sub EEntity::EHost::postStart {
        my ($self, %args) = @_;

        if ($self->node->node_number == 2) {
            $fail_from_test = 1;
            throw Kanopya::Exception(error => "Second node fail !"); 
        }
    }

    diag('Start physical host that should fail');
    throws_ok {
        Kanopya::Test::Execution->startCluster(cluster => $cluster);
    } 'Kanopya::Exception::Internal', 'Start second node';

    lives_ok {
        my ($state, $timestamp) = $cluster->reload->getState();
        if ($state ne 'down') {
            die "Cluster should be down, not $state";
        }
    } 'Cluser should be down';

    my @nodes = $cluster->nodes;
    ok(scalar(@nodes) == 0, "The cluster should have no nodes");

    lives_ok {
        if (! $fail_from_test) {
            die "The start cluster failed, but not from the test mock";
        }
    } 'The second node fail from test mock';

    if ($testing == 1) {
        Kanopya::Database::rollbackTransaction;
    }
}

1;
