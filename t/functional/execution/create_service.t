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

use TryCatch;
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

use Entity::ServiceProvider::Cluster;
use Entity::ServiceTemplate;
use IscsiPortal;
use Lvm2Vg;

my $testing = 1;

main();

sub main {

    if ($testing == 1) {
        Kanopya::Database::beginTransaction;
    }

    my $service_template = Entity::ServiceTemplate->find(hash => { service_name =>  "Standard physical cluster" });
    my $additional_policy_aprams = {
        vg_id         => Lvm2Vg->find()->id,
        iscsi_portals => [ IscsiPortal->find()->id ]
    };

    lives_ok {
        my $clustername = "openstack_vm_cluster_test_" . time();
        my $create = Entity::ServiceProvider::Cluster->create(
                        service_template_id   => $service_template->id,
                        cluster_name          => $clustername,
                        owner_id              => Entity::User->find(hash => { user_login => 'admin' })->id,
                        %{ $additional_policy_aprams }
                     );

        Kanopya::Test::Execution->executeOne(entity => $create);

        $cluster = Kanopya::Test::Retrieve->retrieveCluster(criteria => { cluster_name => $clustername });
    } 'Create Standard physical cluster from service template only.';

    if ($testing == 1) {
        Kanopya::Database::rollbackTransaction;
    }
}

1;
