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
    file=>'ceph_cluster.t.log',
    layout=>'%F %L %p %m%n'
});

use BaseDB;

use Kanopya::Test::Execution;
use Kanopya::Test::Register;
use Kanopya::Test::Retrieve;
use Kanopya::Test::Create;

my $testing = 0;

main();

sub main {

    if ($testing == 1) {
        BaseDB->beginTransaction;
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
                           'ceph' => { },
                           'cephmon' => { },
                           'cephosd' => { },
                       },
                       cluster_conf => {
                           cluster_name => 'Ceph',
                           cluster_min_node => 2,
                           masterimage_id => $masterimage->id
                       }
                   );
    } 'Create cluster';

    my $ceph = $cluster->getComponent(name => "Ceph");
    my $ceph_mon = $cluster->getComponent(name => "CephMon");
    my $ceph_osd = $cluster->getComponent(name => "CephOsd");

    $ceph_mon->setConf(conf => {
        ceph_id => $ceph->id
    });

    $ceph_osd->setConf(conf => {
        ceph_id => $ceph->id
    });

    diag('Start physical host');
    lives_ok {
        Kanopya::Test::Execution->startCluster(cluster => $cluster);
    } 'Start cluster';

    if ($testing == 1) {
        BaseDB->rollbackTransaction;
    }
}

1;
