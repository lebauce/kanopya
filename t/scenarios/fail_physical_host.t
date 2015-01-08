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
                       cluster_conf => {
                           cluster_name => "default_cluster_name" . time,
                           masterimage_id   => $masterimage->id,
                       },
                   );
    } 'Create cluster';

    # Dynamically modify the EHost class to raise exception at postStart.
    use_ok ('EEntity::EHost');

    my $fails = {
        "First" => {
            node_number => 1,
            fail_from_test => 0,
            expected_state => "down",
            expected_nodes => 0,
            should_fail    => 1,
        },
        "Second" => {
            node_number => 2,
            fail_from_test => 0,
            expected_state => "up",
            expected_nodes => 1,
            should_fail    => 0,
        }
    };

    for $node ("First", "Second") {
        $cluster->cluster_min_node($fails->{$node}->{node_number});

        sub EEntity::EHost::postStart {
            my ($self, %args) = @_;

            if ($self->node->node_number == $fails->{$node}->{node_number}) {
                $fails->{$node}->{fail_from_test} = 1;
                throw Kanopya::Exception(error => $node . " node fail !");
            }
        }

        if ($fails->{$node}->{should_fail}) {
            diag('Start physical host that should fail at ' . $node . ' node');
            throws_ok {
                Kanopya::Test::Execution->startCluster(cluster => $cluster);
            } 'Kanopya::Exception::Test', 'Start ' . $node  .  ' node';
        }
        else {
            diag('Start physical host that should succeed at ' . $node . ' node');
            lives_ok {
                Kanopya::Test::Execution->startCluster(cluster => $cluster);
            } 'Start ' . $node  .  ' node';
        }

        lives_ok {
            my ($state, $timestamp) = $cluster->reload->getState();
            if ($state ne $fails->{$node}->{expected_state}) {
                die "Cluster should be " . $fails->{$node}->{expected_state} . ", not $state";
            }
        } 'Cluser should be down';

        my @nodes = $cluster->nodes;
        ok(scalar(@nodes) == $fails->{$node}->{expected_nodes},
            "The cluster should have " . $fails->{$node}->{expected_nodes} . " node(s), not " . scalar(@nodes));

        lives_ok {
            if (! $fails->{$node}->{fail_from_test}) {
                die "The start cluster failed, but not from the test mock";
            }
        } 'The ' . $node . ' node fail from test mock';
    }

    if ($testing == 1) {
        Kanopya::Database::rollbackTransaction;
    }
}

1;
