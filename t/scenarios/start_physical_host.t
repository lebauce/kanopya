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
use ComponentType;

use Log::Log4perl qw(:easy get_logger);
Log::Log4perl->easy_init({
    level=>'DEBUG',
    file=>'/vagrant/SetupPhysicalHost.t.log',
    layout=>'%F %L %p %m%n'
});

use Administrator;
use Entity::ServiceProvider::Inside::Cluster;
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

my $testing = 0;
my $NB_HYPERVISORS = 1;
my $boards = [
    {
        ram    => 2048,
        core   => 2,
        ifaces => [
            {
                name => "eth0",
                mac  => "00:11:22:33:44:55",
                pxe  => 1
            },
            {
                name => "eth1",
                mac  => "66:77:88:99:00:aa",
                pxe  => 0,
            },
            {
                name => "eth2",
                mac  => "aa:bb:cc:dd:ee:ff",
                pxe  => 0,
            },
        ]
    },
];

main();

sub main {
    Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
    my $adm = Administrator->new;

    if ($testing == 1) {
        $adm->beginTransaction;
    }

    diag('Create and configure cluster');
    my $host_manager_params = {
        cpu => 1,
        ram => 512 * 1024 * 1024,
    };
    my $disk_manager_params = {
        vg_id            => 1,
        systemimage_size => 4 * 1024 * 1024 * 1024,
    };

    Kanopya::Tools::Create->createCluster(
        cluste_name => 'MyCluster',
        hosts => $boards,
        host_manager_params => $host_manager_params,
        disk_manager_params => $disk_manager_params,
    );

    diag('Start physical host');
    start_cluster();

    if ($testing == 1) {
        $adm->rollbackTransaction;
    }
}

sub start_cluster {
    lives_ok {
        my $cluster;
        diag('retrieve Cluster via name');
        $cluster = Kanopya::Tools::Retrieve->retrieveCluster(criteria => {cluster_name => 'MyCluster'});
        Kanopya::Tools::Execution->executeOne(entity => $cluster->start());

        my ($state, $timestemp) = $cluster->getState;
        if ($state eq 'up') {
            diag("Cluster $cluster->cluster_name started successfully");
        }
        else {
            die "Cluster is not 'up'";
        }
    } 'Start cluster';
}

1;
