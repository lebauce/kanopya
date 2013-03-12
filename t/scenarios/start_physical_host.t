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

use BaseDB;
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

use Kanopya::Tools::Execution;
use Kanopya::Tools::Register;
use Kanopya::Tools::Retrieve;
use Kanopya::Tools::Create;

my $testing = 1;
my $NB_HYPERVISORS = 1;

main();

sub main {

    if ($testing == 1) {
        BaseDB->beginTransaction;
    }

    diag('Register master image');
    lives_ok {
        Kanopya::Tools::Register::registerMasterImage();
    } 'Register master image';

    diag('Create and configure cluster');
    my $cluster;
    lives_ok {
        $cluster = Kanopya::Tools::Create->createCluster();
    } 'Create cluster';

    diag('Start physical host');
    lives_ok {
        Kanopya::Tools::Execution->startCluster(cluster => $cluster);
    } 'Start cluster';

    if ($testing == 1) {
        BaseDB->rollbackTransaction;
    }
}

1;
