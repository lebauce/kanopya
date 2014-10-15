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

use Entity::User;
use Entity::Policy::NetworkPolicy;
use Entity::Policy::HostingPolicy;
use Entity::Policy::StoragePolicy;
use Entity::Policy::SystemPolicy;
use Entity::Policy::ScalabilityPolicy;
use Entity::Policy::BillingPolicy;
use Entity::Policy::OrchestrationPolicy;
use Entity::ServiceTemplate;
use Entity::Component::KanopyaDeploymentManager;

use Data::Dumper;
my $testing = 1;

main();

sub main {

    if ($testing == 1) {
        Kanopya::Database::beginTransaction;
    }

    diag('Register/get the OpenStack component');
    my $openstack;
    try {
        $openstack = Entity::Component::Virtualization::OpenStack->find();
    }
    catch {
        my $localhostname = `hostname`;
        chomp($localhostname);

        $openstack = Kanopya::Test::Register->registerComponentOnNode(
                         componenttype => "OpenStack",
                         hostname      => $localhostname,
                         component_params => {
                             api_username => 'tgenin',
                             api_password => 'doc@123',
                             keystone_url => '192.168.3.10',
                             tenant_name  => 'Doc'
                         }
                     );

        diag('Synchronize the existing infrastructure');
        lives_ok {
            Kanopya::Test::Execution->executeOne(entity => $openstack->synchronize());

        } 'Synchronize the existing infrastructure';
    }

    my $servicetemplate;
    my $args = { service_name => 'Service template test with openstack policies' };

    diag('Create a network policy with OpenStack as network manager.');
    lives_ok {
        my $policy = Entity::Policy::NetworkPolicy->new(
                             cluster_domainname  => "hederatech.com",
                             cluster_nameserver1 => "8.8.8.8",
                             cluster_nameserver2 => "8.8.4.4",
                             network_manager_id  => $openstack->id,
                             network_tenant      =>  "suse",
                             policy_desc         => "",
                             policy_name         =>  "susecloud_network",
                             policy_type         => "network",
                             subnets             => [ "192.168.123.0/24 (suse-network)" ]
                         );
        $policy->toJSON();
        $args->{'network_policy_id'} = $policy->id;
    } 'Create a network policy with OpenStack as network manager';

    diag('Create a hosting policy with OpenStack as host manager.');
    lives_ok {
        my $policy = Entity::Policy::HostingPolicy->new(
                             host_manager_id  => $openstack->id,
                             flavor => "m1.tiny",
                             availability_zone => "nova",
                             hosting_tenant => "Doc",
                             policy_desc         => "",
                             policy_name         =>  "susecloud_hosting",
                             policy_type         => "hosting",
                         );
        $policy->toJSON();
        $args->{'hosting_policy_id'} = $policy->id;
    } 'Create a hosting policy with OpenStack as host manager';

    diag('Create a storage policy with OpenStack as storage manager.');
    lives_ok {
        my $policy = Entity::Policy::StoragePolicy->new(
                             storage_manager_id  => $openstack->id,
                             volume_type => "NFS",
                             policy_desc         => "",
                             policy_name         =>  "susecloud_storage",
                             policy_type         => "storage",
                         );
        $policy->toJSON();
        $args->{'storage_policy_id'} = $policy->id;
    } 'Create a storage policy with OpenStack as storage manager';

    diag('Create a system policy with OpenStack as deployment manager.');
    lives_ok {
        my $policy = Entity::Policy::SystemPolicy->new(
                             storage_manager_id  => $openstack->id,
                             deploy_on_disk => 0,
                             components => {},
                             deployment_manager_id => Entity::Component::KanopyaDeploymentManager->find->id,
                             systemimage_size => 8589934592,
                             boot_manager_id =>  $openstack->id,
                             cluster_si_persistent => 0,
                             policy_desc         => "",
                             policy_name         =>  "susecloud_system",
                             policy_type         => "system",
                         );
        $policy->toJSON();
        $args->{'system_policy_id'} = $policy->id;
    } 'Create a storage policy with OpenStack as system manager';

    $args->{'billing_policy_id'} = Entity::Policy::BillingPolicy->find->id;
    $args->{'scalability_policy_id'} = Entity::Policy::ScalabilityPolicy->find(hash => { policy_name => "Manual scalability cluster" })->id;
    $args->{'orchestration_policy_id'} = Entity::Policy::OrchestrationPolicy->find->id;

    diag('Create service template from policies');
    lives_ok {
        $servicetemplate = Entity::ServiceTemplate->create(%$args);
        $servicetemplate->toJSON();
    } "Create service template from policies";

    diag('Create service from service template.');
    lives_ok {
        my $additional_policy_aprams = {};

        Entity::ServiceProvider::Cluster->buildInstantiationParams(
            cluster_name        => "test_openstack_based_service",
            owner_id            => Entity::User->find()->id,
            service_template_id => $servicetemplate->id,
            %$additional_policy_aprams
        );
    } "Create service from service template.";

    if ($testing == 1) {
        Kanopya::Database::rollbackTransaction;
    }
}

1;
