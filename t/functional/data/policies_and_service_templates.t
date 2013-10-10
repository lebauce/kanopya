#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Data::Dumper;
use ClassType;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({ level=>'DEBUG', file => 'policies_and_service_templates.log', layout => '%F %L %p %m%n' });
my $log = get_logger("");

my $testing = 1;

use Kanopya::Database;
use ClassType;
use Entity::User;
use Entity::ServiceProvider::Cluster;
use Entity::ServiceTemplate;
use Entity::Policy;
use Lvm2Vg;
use Entity::Policy::HostingPolicy;
use Entity::Component::Physicalhoster0;

Kanopya::Database::authenticate(login => 'admin', password => 'K4n0pY4');


main();

sub main {

    if ($testing == 1) {
        Kanopya::Database::beginTransaction;
    }

    test_policies_json();
    test_service_template_json();
    test_service_template_creation();
    test_service_creation_from_service_template();

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
        my $attrdef = $class->toJSON(params => $json)->{attributes};
        lives_ok {
            for my $attr (keys %{ $attrdef }) {
                if (! defined $baseattrdef->{$attr} && ! $attrdef->{$attr}->{is_editable}) {
                    die "Class JSON of policy type $class with params of $policy contains non editable attr <$attr>.";
                }
            }
        } "Check if the attrdef JSON contains editable attrs only.";
    }
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
                if (defined $policyparams->{$policyattr} && "$attributes->{$policyattr}->{is_editable}" == "1") {
                    die "Service template attribute definition JSON contains editable policy attr <$policyattr>";
                }
                elsif (! defined $policyparams->{$policyattr} && $attributes->{$policyattr}->{is_editable} != 1) {
                    die "Service template attribute definition JSON contains non editable policy attr <$policyattr>";
                }
            }
        }
    } "Check if the service template attrdef JSON with defined service_template_id params cnotains only non editable policies ids.";
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

        Entity::ServiceProvider::Cluster->create(cluster_name        => "test_cluster",
                                                 user_id             => Entity::User->find()->id,
                                                 service_template_id => $service_template->id,
                                                 %$additional_policy_aprams);
    } "Create an empty policies of each type.";
}
