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
    file=>'/vagrant/DeployOnHarddisk.t.log',
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

main();

sub main {
    Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
    my $adm = Administrator->new;

    if ($testing == 1) {
        $adm->beginTransaction;
    }

    lives_ok {
        diag('Register master image');
        Kanopya::Tools::Register::registerMasterImage();

        diag('Create and configure cluster');
        my $cluster = Kanopya::Tools::Create->createCluster(
                          managers => {
                              host_manager => {
                                  manager_params => {
                                      deploy_on_disk => 1
                                   }
                              }
                          }
                      );

        diag('Start physical host');
        Kanopya::Tools::Execution->startCluster(cluster => $cluster);
    } 'Start host and deploy to hard disk';

    if ($testing == 1) {
        $adm->rollbackTransaction;
    }
}

1;
