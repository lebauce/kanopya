#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Data::Dumper;
use ClassType;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({
    level=>'DEBUG',
    file => 'policies_and_service_templates.log',
    layout => '%d [ %H - %P ] %p -> %M - %m%n'
});
my $log = get_logger("");

my $testing = 1;

use Kanopya::Database;
use ClassType;
use Entity::User;
use Entity::ServiceProvider;
use Entity::ServiceProvider::Cluster;
use Entity::ServiceTemplate;
use Entity::Policy;
use Entity::Policy::StoragePolicy;
use Lvm2Vg;
use Entity::Policy::HostingPolicy;
use Entity::Policy::OrchestrationPolicy;
use Entity::Component::Physicalhoster0;
use Entity::Component::Lvm2;
use Entity::Component::Iscsi::Iscsitarget1;
use Entity::Component::HCMStorageManager;
use Entity::Component::HCMNetworkManager;
use Entity::Component::KanopyaDeploymentManager;
use Entity::Component::Kanopyacollector1;
use Kanopya::Test::TestUtils 'expectedException';

Kanopya::Database::authenticate(login => 'admin', password => 'K4n0pY4');


main();

sub main {

    if ($testing == 1) {
        Kanopya::Database::beginTransaction;
    }

    test_policies_json();
    test_policies_merge();
    test_policies_hash_to_list();
    test_service_template_json();
    test_service_template_creation();
    test_service_creation_from_service_template();
    test_add_manager();
    test_orchestration_policy();

    if ($testing == 1) {
        Kanopya::Database::rollbackTransaction;
    }
}

sub test_policies_json {
    for my $policy (Entity::Policy->search(hash => { -not => { policy_type => 'orchestration' } })) {
        my $json = $policy->toJSON();
        my $presets = $policy->getParams();
        lives_ok {
            for my $attr (keys %{ $presets }) {
                exists $json->{$attr} or die "JSON of policy $policy should contain key <$attr>";
            }
        } "Check if the JSON of policy $policy contains all preset attributes.";

        my $class = ref($policy);
        my $baseattrdef = $class->_attributesDefinition();
        my $attrjson = $class->toJSON(params => $json);
        my $attrdef = $attrjson->{attributes};

        my @skiped = ('gps', 'time_periods', 'tags');
        lives_ok {
            for my $attr (keys %{ $attrdef }) {
                if (scalar(grep { $_ eq $attr } @skiped) <= 0 && 
                    $attrdef->{$attr}->{type} eq "relation" &&
                    $attrdef->{$attr}->{relation} eq "single_multi" &&
                    ! defined $attrjson->{relations}->{$attr}) {
                    die "Attribute \"$attr\" should be in the relation definition";
                }
            }
        } "Check if relations are in the relations fields";

        lives_ok {
            for my $attr (keys %{ $attrdef }) {
                if (! defined $baseattrdef->{$attr} && ! $attrdef->{$attr}->{is_editable}) {
                    die "Class JSON of policy type $class with params of $policy contains non editable attr <$attr>.";
                }
            }
        } "Check if the attrdef JSON contains editable attrs only.";
    }
}

sub test_policies_merge {

    # Create a policy with presets containing arrays
    my $policy = Entity::Policy::StoragePolicy->new(
                     policy_name        => "storage_policy_test",
                     policy_type        => "storage",
                     storage_manager_id => Entity::Component::HCMStorageManager->find()->id,
                     disk_manager_id    => Entity::Component::Lvm2->find()->id,
                     vg_id              => 1,
                     export_manager_id  => Entity::Component::Iscsi::Iscsitarget1->find()->id,
                     iscsi_portals      => [ 1 ]
                 );

    lives_ok {
        # Check if the jysonification is working
        $policy->toJSON();
    } "Check if the jysonification is working";

    my $params = Entity::ServiceProvider::Cluster->buildConfigurationPattern(
                     policies           => ($policy),
                     policy_type        => "storage",
                     storage_manager_id => Entity::Component::HCMStorageManager->find()->id,
                     disk_manager_id    => Entity::Component::Lvm2->find()->id,
                     vg_id              => 2,
                     export_manager_id  => Entity::Component::Iscsi::Iscsitarget1->find()->id,
                     iscsi_portals      => [ 1 ]
                 );

    my @portals = @{ $params->{managers}->{storage_manager}->{manager_params}->{iscsi_portals} };
    my $vg_id = $params->{managers}->{storage_manager}->{manager_params}->{vg_id};
    lives_ok {
        if (scalar(@portals) != 1 || (pop @portals) != 1) {
            die "Iscsiportals from the merged configuration pattern: " . Dumper(\@portals) .
                " do not match the original value: [ 1 ]."
        }
        if ($vg_id != 2) {
            die "Vg_id from the merged configuration pattern: " . $vg_id . " do not match the overriden value: 2";
        }
    } "Check if the service template attrdef JSON contains all policy type attributes.";
}

sub test_policies_hash_to_list {

    # Create a policy with presets containing arrays
    my $net_policy = Entity::Policy::NetworkPolicy->new(
                         policy_name        => "net_policy_tests_hash_to_list",
                         policy_type        => "network",
                         cluster_nameserver1 => "8.8.8.8",
                         cluster_nameserver2 => "8.8.4.4",
                         cluster_domainname => "hedera-technology.com",
                         network_manager_id => Entity::Component::HCMNetworkManager->find->id,
                         interfaces => [ {
                            interface_name => "eth0",
                            netconfs => [ 123 ]
                         }, {
                            interface_name => "eth1",
                            netconfs => [ 123, 5678 ]
                         } ],
                     );

    lives_ok {
        # Check if the jysonification is working
        my $dynamic_attrdef = Entity::Policy::NetworkPolicy->toJSON(params => $net_policy->toJSON());
        if (! defined $dynamic_attrdef->{attributes}->{interfaces}) {
            die "Network policy dynamic attr def should contains attr \"interfaces\"";
        }
        if (! defined $dynamic_attrdef->{relations}->{interfaces}) {
            die "Network policy dynamic relation def should contains relations \"interfaces\"";
        }

        my @displayed_relations = grep { ref($_) eq "HASH" } @{ $dynamic_attrdef->{displayed} };
        if (scalar(grep { (keys %{ $_ })[0] eq "interfaces" } @displayed_relations) <= 0) {
            die "Network policy dynamic attr def should contains attr \"interfaces\" in the displayed list";
        }
    } "Check if the jysonification is working";

    my $sys_policy = Entity::Policy::SystemPolicy->new(
                         policy_name        => "sys_policy_tests_hash_to_list",
                         policy_type        => "system",
                         cluster_si_persistent => 0,
                         systemimage_size => 5368709120,
                         deployment_manager_id => Entity::Component::KanopyaDeploymentManager->find->id,
                         boot_manager_id => Entity::Component::KanopyaDeploymentManager->find->id,
                         components => [ {
                            component_type => 29
                         }, {
                            component_type => 30
                         }, {
                            component_type => 31
                         } ]
                     );

    lives_ok {
        # Check if the jysonification is working
        my $dynamic_attrdef = Entity::Policy::SystemPolicy->toJSON(params => $sys_policy->toJSON());

        if (! defined $dynamic_attrdef->{attributes}->{components}) {
            die "System policy dynamic attr def should contains attr \"components\"";
        }
        if (! defined $dynamic_attrdef->{relations}->{components}) {
            die "System policy dynamic relation def should contains relations \"components\"";
        }

        my @displayed_relations = grep { ref($_) eq "HASH" } @{ $dynamic_attrdef->{displayed} };
        if (scalar(grep { (keys %{ $_ })[0] eq "components" } @displayed_relations) <= 0) {
            die "System policy dynamic attr def should contains attr \"components\" in the displayed list";
        }
    } "Check if the jysonification is working";

    lives_ok {
        my $net_pattern = $net_policy->param_preset->load;
        my $interfaces =  $net_pattern->{managers}->{network_manager}->{manager_params}->{interfaces};
        if (ref($interfaces) ne "HASH") {
            die "Value for key \"interfaces\" should be a HASH, not: " . ref($interfaces);
        }

        my @interfaces = values %{ $interfaces };
        my $any_interface = pop @interfaces;
        if (ref($any_interface->{netconfs}) ne "HASH") {
            die "Value for key \"netconfs\" should be a HASH, not: " . ref($any_interface->{netconfs});
        }

        my $sys_pattern = $sys_policy->param_preset->load;
        my $components =  $sys_pattern->{managers}->{deployment_manager}->{manager_params}->{components};
        if (ref($components) ne "HASH") {
            die "Value for key \"components\" should be a HASH, not: " . ref($components);
        }

    } "Check if the list values are properly stored as hashes";

    lives_ok {
        my $net_params = $net_policy->getParams;
        if (ref($net_params->{interfaces}) ne "ARRAY") {
            die "Value for key \"interfaces\" should be a ARRAY, not: " . ref($net_params->{interfaces});
        }

        my $any_interface = pop @{ $net_params->{interfaces} };
        if (ref($any_interface->{netconfs}) ne "ARRAY") {
            die "Value for key \"netconfs\" should be a ARRAY, not: " . ref($any_interface->{netconfs});
        }

        my $sys_params = $sys_policy->getParams;
        if (ref($sys_params->{components}) ne "ARRAY") {
            die "Value for key \"components\" should be a ARRAY, not: " . ref($sys_params->{components});
        }

    } "Check if the list values stored as hashes are properly returned as list at getParams";
}

sub test_service_template_json {
    my $attributes = Entity::ServiceTemplate->toJSON()->{attributes};
    lives_ok {
        my @policy_classes = ClassType->search(hash => { class_type => { like => "Entity::Policy::%" } });
        for my $class (map { $_->class_type } @policy_classes) {
            my $policyattrs = $class->toJSON()->{attributes};
            my $baseattrdef = $class->_attributesDefinition();
            for my $attr (keys %$policyattrs) {
                if (! defined $baseattrdef->{$attr} && ! exists $attributes->{$attr}) {
                    die "Service template attribute definition JSON should contain the $class attr <$attr>";
                }
            }
        }
    } "Check if the service template attrdef JSON contains all policy type attributes.";

    my $service_template = Entity::ServiceTemplate->find();
    my @policies = $service_template->getPolicies();
    $attributes = Entity::ServiceTemplate->toJSON(params => { service_template_id => $service_template->id })->{attributes};

    lives_ok {
        for my $attr (grep { $_ =~ m/.*policy_id/ } keys $attributes) {
            if ("$attributes->{$attr}->{is_editable}" == "1") {
                die "Service template attribute definition JSON contains editable policy id attr <$attr>";
            }
            (my $policytype = $attr) =~ s/_policy_id$//g;

            if ($policytype eq 'orchestration') { next; };

            my $policy        = (grep { $_->policy_type eq $policytype } @policies)[0];
            my $policyclass   = ref($policy);
            my $policyattrdef = $policyclass->toJSON(params => $policy->toJSON())->{attributes};
            my $policyparams  = $policy->getParams(noarrays => 1);

            for my $policyattr (keys $policyattrdef) {
                if ($policyattr =~ m/class_type_id|label/ || ! defined $attributes->{$policyattr} ||
                    defined $policyclass->getPolicySelectorAttrDef->{$policyattr}) {
                    next;
                }
                # Relation single_multi and multi are editable as we allow to add entries at service instanciation
                if (defined $policyparams->{$policyattr} &&
                    ! ($attributes->{$policyattr}->{type} eq "relation" && $attributes->{$policyattr}->{relation} =~ m/^(single_multi|multi)$/) &&
                    "$attributes->{$policyattr}->{is_editable}" == "1") {
                    die "Service template attribute definition JSON contains editable policy attr <$policyattr>";
                }
                elsif (! defined $policyparams->{$policyattr} && $attributes->{$policyattr}->{is_editable} != 1) {
                    die "Service template attribute definition JSON contains non editable policy attr <$policyattr>";
                }
            }
        }
    } "Check if the service template attrdef JSON with defined service_template_id params contains only non editable policies ids.";
}

sub test_service_template_creation {
    my $policies = {};
    lives_ok {
        my @policy_classes = ClassType->search(hash => { class_type => { like => "Entity::Policy::%" } });
        for my $class (map { $_->class_type } @policy_classes) {
            (my $policy_type = $class) =~ s/^Entity::Policy:://g;
            $policy_type =~ s/Policy$//g;
            $policy_type = lc($policy_type);

            $policies->{$policy_type} = $class->create(policy_name => $policy_type . ' test policy', policy_type => $policy_type);
        }
    } "Create an empty policies of each type.";

    my $servicetemplate;
    my $args = { service_name => 'Service template test with empty policies' };
    lives_ok {
        for my $policy_type (keys %{ $policies }) {
            $args->{$policy_type . '_policy_id'} = $policies->{$policy_type}->id;
        }
        $servicetemplate = Entity::ServiceTemplate->create(%$args);

        for my $policy_type (keys %{ $policies }) {
            my $policy = $servicetemplate->getAttr(name => $policy_type . '_policy');
            if ($policy->id != $policies->{$policy_type}->id) {
                die "The $policy_type of the created service template should be the same than at creation: <" . $policies->{$policy_type}->id . ">, but got <" . $policy->id . ">";
            }
        }
    } "Create a service template with empty policies";

    lives_ok {
        $policies->{hosting} = Entity::Policy::HostingPolicy->create(policy_name     => "Full hosting policy",
                                                                     policy_type     => 'hosting',
                                                                     host_manager_id => Entity::Component::Physicalhoster0->find()->id,
                                                                     cpu             => 2,
                                                                     ram             => 1024);

        $args->{service_name}      = 'Service template test with totaly filled hosting policy';
        $args->{hosting_policy_id} = $policies->{hosting}->id;
        $servicetemplate = Entity::ServiceTemplate->create(%$args);

        for my $policy_type (keys %{ $policies }) {
            my $policy = $servicetemplate->getAttr(name => $policy_type . '_policy');

            if ($policy->id != $policies->{$policy_type}->id) {
                die "The $policy_type of the created service template should be the same than at creation: <" . $policies->{$policy_type}->id . ">, but got <" . $policy->id . ">";
            }
        }
    } "Create a service template with fully filled hosting policy";

    lives_ok {
        $args->{service_name} = 'Service template test with modified hosting policy';
        $servicetemplate = Entity::ServiceTemplate->create(cpu => 4 , %$args);

        for my $policy_type (keys %{ $policies }) {
            my $policy = $servicetemplate->getAttr(name => $policy_type . '_policy');

            if ($policy_type ne 'hosting' && $policy->id != $policies->{$policy_type}->id) {
                die "The $policy_type of the created service template should be the same than at creation: <" . $policies->{$policy_type}->id . ">, but got <" . $policy->id . ">";
            }
            elsif ($policy_type eq 'hosting' && $policy->id == $policies->{$policy_type}->id) {
                die "The hosting policy of the created service template should be different than at creation: <" . $policies->{$policy_type}->id . ">, but got <" . $policy->id . ">";
            }
        }
    } "Create a service template with modified hosting policy";
}

sub test_service_creation_from_service_template {
    my $service_template = Entity::ServiceTemplate->find(hash => { service_name =>  "Standard physical cluster" });
    lives_ok {
        my $additional_policy_aprams = {
            vg_id         => Lvm2Vg->find()->id,
            iscsi_portals => [ IscsiPortal->find()->id ]
        };

        Entity::ServiceProvider::Cluster->buildInstantiationParams(
            cluster_name        => "test_cluster",
            owner_id            => Entity::User->find()->id,
            service_template_id => $service_template->id,
            %$additional_policy_aprams
        );
    } "Create service from service template.";
}

sub test_orchestration_policy {

    my $sp = Entity::ServiceProvider->new();
    my $collector_manager = Entity::Component::Kanopyacollector1->find();
    $sp->addManager(manager_id => $collector_manager->id, manager_type => 'CollectorManager');

    my $orchestration_policy = Entity::Policy::OrchestrationPolicy->create(
                                   collector_manager_id => $collector_manager->id,
                                   policy_name => 'Test orchestration',
                                   policy_type => 'orchestration',
                                   orchestration => {service_provider_id => $sp->id},
                               );
    $orchestration_policy->remove();
    lives_ok {
        expectedException { Entity->get(id => $sp->id) }
            'Kanopya::Exception::Internal::NotFound',
            'Service Provider has to be deleted';

    } 'Remove orchestration policy service provider with policy deletion'
}

sub test_add_manager {
    my $sp = Entity::ServiceProvider->new();
    my $collector_manager_1 = Entity::Component::Kanopyacollector1->find();
    my $collector_manager_2 = Entity::Component::Kanopyacollector1->new();

    my $collector_manager;
    lives_ok {
        expectedException {
            $collector_manager = $sp->getManager(manager_type => 'CollectorManager');
        } 'Kanopya::Exception::Internal::NotFound',
          'Service Provider should not have any Collector manager';

        $sp->addManager(manager_id => $collector_manager_1->id,
                        manager_type => 'CollectorManager');

        $collector_manager = $sp->getManager(manager_type => 'CollectorManager');

        if ($collector_manager->id ne $collector_manager_1->id) {
            die 'Collector manager should be collector manager 1';
        }

        $sp->addManager(manager_id => $collector_manager_2->id,
                        manager_type => 'CollectorManager');

        $collector_manager = $sp->getManager(manager_type => 'CollectorManager');

        if ($collector_manager->id ne $collector_manager_2->id) {
            die 'Collector manager should be collector manager 2';
        }

        $sp->addManager(manager_id => $collector_manager_1->id,
                        manager_type => 'CollectorManager');

        $collector_manager = $sp->getManager(manager_type => 'CollectorManager');

        if ($collector_manager->id ne $collector_manager_1->id) {
            die 'Collector manager should be collector manager 1 (2nd time)';
        }

    } 'Add manager'
}
