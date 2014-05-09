#!/usr/bin/perl

use strict;
use warnings;
use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Data::Dumper;
use DataCache;
DataCache::cacheActive(0);

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'sco_workflow_and_notification.log', layout=>'%F %L %p %m%n'});
my $log = get_logger("");


use Kanopya::Database;

use Entity::ServiceProvider::Externalcluster;
use Entity::Component::MockMonitor;
use Entity::Metric::Clustermetric;
use Entity::Metric::Combination::AggregateCombination;
use Entity::Metric::Combination::NodemetricCombination;
use Entity::Component::Sco;
use Entity::Component::KanopyaMailNotifier;
use Entity::User;
use Entity::WorkflowDef;

use NotificationSubscription;
use Kanopya::Tools::TestUtils 'expectedException';

my $nc1;
my $rule1;
my $service_provider;
my $mock_monitor;
my $sco;
my $service_wf:;

main();

sub main {
    eval{
        Kanopya::Database::authenticate( login =>'admin', password => 'K4n0pY4' );
        Kanopya::Database::beginTransaction;
        lives_ok {
            _create_infra();
            _rule_objects_creation();
        } 'Create objects';

        add_and_remove_notification();
        add_and_remove_workflow();
        add_workflow_and_notification();
        add_notification_and_workflow();

        $rule1 = Entity::Rule::NodemetricRule->new(
            service_provider_id => $service_provider->id,
            formula => 'id'.$nc1->id,
            state => 'enabled'
        );

        add_and_remove_notification();
        add_and_remove_workflow();
        add_workflow_and_notification();
        add_notification_and_workflow();

        # Kanopya::Database::commitTransaction;
        Kanopya::Database::rollbackTransaction;

    };
    if($@) {
        my $error = $@;
        print $error."\n";
        Kanopya::Database::rollbackTransaction;
        fail('Exception occurs');
    }
}

sub add_notification_and_workflow {
    lives_ok {

        if (defined $rule1->workflow_def) {
            die 'rule1 should not have linked workflow def'
        }

        my @users = Entity::User->search();

        $rule1->subscribe(subscriber_id => $users[0]->id,
                          entity_id     => $rule1->id,
                          operationtype => 'ProcessRule');

        $rule1 = $rule1->reload;

        $rule1->associateWorkflow(workflow_def_id => $service_wf->id);

        $rule1 = $rule1->reload;

        my $workflow_def = $rule1->workflow_def;

        if (! defined $rule1->workflow_def) {
            die 'No workflow def associate to rule'
        }

        if ((! $workflow_def->workflow_def_name eq $service_wf->workflow_def_name) ||
            (! $workflow_def->id eq $service_wf->id)) {
                die 'Wrong attributes for linked workflow def';
        }

        my $ns = NotificationSubscription->find(
            hash => {
                subscriber_id       => $users[0]->id,
                entity_id           => $rule1->id,
            }
        );

        $rule1->unsubscribe(notification_subscription_id => $ns->id);

        $rule1 = $rule1->reload;

        $workflow_def = $rule1->workflow_def;

        expectedException {
            NotificationSubscription->find(hash => {
                 subscriber_id => $users[0]->id,
                 entity_id     => $rule1->id,
             });
        } 'Kanopya::Exception::Internal::NotFound', 'Notification not removed';

        if (! defined $rule1->workflow_def) {
            die 'No linked workflow def';
        }

        if ((! $workflow_def->workflow_def_name eq $service_wf->workflow_def_name) ||
            (! $workflow_def->workflow_def_id eq $service_wf->id)) {
                die 'Wrong attributes for linked workflow def';
        }

        $rule1->deassociateWorkflow();

        $rule1 = $rule1->reload;

    } 'Add notification and associate workflow';

}

sub add_workflow_and_notification {
    lives_ok {

        if (defined $rule1->workflow_def) {
            die 'rule1 should not have linked workflow def'
        }

        my @users = Entity::User->search();

        $rule1->associateWorkflow(workflow_def_id => $service_wf->id);

        $rule1 = $rule1->reload;

        my $workflow_def = $rule1->workflow_def;

        $rule1->subscribe(subscriber_id => $users[0]->id,
                          entity_id     => $rule1->id,
                          operationtype => 'ProcessRule');

        $rule1 = $rule1->reload;

        if (! defined $rule1->workflow_def) {
            die 'No workflow def associate to rule'
        }

        if ((! $workflow_def->workflow_def_name eq $service_wf->workflow_def_name) ||
            (! $workflow_def->workflow_def_id eq $service_wf->id)) {
                die 'Wrong attributes for linked workflow def';
        }

        my $ns = NotificationSubscription->find(
            hash => {
                subscriber_id       => $users[0]->id,
                entity_id           => $rule1->id,
            }
        );

        $rule1->deassociateWorkflow();

        $rule1 = $rule1->reload;

        my $notif_workflow_def = $rule1->workflow_def;

        $ns = NotificationSubscription->find(hash => {
                     subscriber_id => $users[0]->id,
                     entity_id     => $rule1->id,
                 });

        if (! defined $rule1->workflow_def) {
            die 'No linked workflow def';
        }

        if (! $notif_workflow_def->workflow_def_name eq $rule1->notifyWorkflowName) {
            die ('Notification Workflow not created after subscription');
        }

        $rule1->unsubscribe(notification_subscription_id => $ns->id);
        $rule1 = $rule1->reload;

    } 'Associate workflow and add subscription';

}

sub add_and_remove_workflow {
    lives_ok {
        $rule1->associateWorkflow(workflow_def_id => $service_wf->id);

        $rule1 = $rule1->reload;

        if (! defined $rule1->workflow_def) {
            die 'No workflow def associate to rule'
        }

        my $workflow_def = $rule1->workflow_def;

        if ((! $workflow_def->workflow_def_name eq $service_wf->workflow_def_name) ||
            (! $workflow_def->workflow_def_id eq $service_wf->id)) {
                die 'Wrong attributes for linked workflow def';
        }

        $rule1->deassociateWorkflow();

        $rule1 = $rule1->reload;

        if (defined $rule1->workflow_def) {
            die 'Still a workflow def associate to rule';
        }

    } 'Associate and deassociate workflow';

}

sub add_and_remove_notification {
    lives_ok {
        my @users = Entity::User->search();

        # Add one suscriber
        $rule1->subscribe(subscriber_id => $users[0]->id, operationtype => 'ProcessRule');
        $rule1 = $rule1->reload;

        my $ns = NotificationSubscription->find(
            hash => {
                subscriber_id       => $users[0]->id,
                entity_id           => $rule1->id,
            }
        );

        if (! defined $rule1->workflow_def) {
            die 'No linked workflow def';
        }

        my $workflow_def = $rule1->workflow_def;

        if (! $workflow_def->workflow_def_name eq $rule1->notifyWorkflowName) {
            die ('Notification Workflow not created after subscription');
        }

        # Add a 2nd suscriber
        $rule1->subscribe(subscriber_id => $users[1]->id, operationtype => 'ProcessRule',);
        $rule1 = $rule1->reload;

        # Check if first notification still present
        NotificationSubscription->find(
            hash => {
                subscriber_id       => $users[0]->id,
                entity_id           => $rule1->id,
            }
        );

        my $ns2 = NotificationSubscription->find(
            hash => {
                subscriber_id       => $users[1]->id,
                entity_id           => $rule1->id,
            }
        );

        # Remove one suscriber
        $rule1->unsubscribe(notification_subscription_id => $ns2->id);
        $rule1 = $rule1->reload;

        expectedException {
            NotificationSubscription->find(
                hash => {
                    subscriber_id       => $users[1]->id,
                    entity_id           => $rule1->id,
                }
            );
        } 'Kanopya::Exception::Internal::NotFound', 'NotificationSubscription 1 still present';

        if (! defined $rule1->workflow_def) {
            die 'Workflow has been unlinked';
        }

        Entity::WorkflowDef->get(id => $workflow_def->id);
        Entity::WorkflowDef->find(hash => {workflow_def_name => $workflow_def->workflow_def_name});

        $rule1->unsubscribe(notification_subscription_id => $ns->id);
        $rule1 = $rule1->reload;

        expectedException {
            NotificationSubscription->find(
                hash => {
                    subscriber_id       => $users[0]->id,
                    entity_id           => $rule1->id,
                }
            );
        } 'Kanopya::Exception::Internal::NotFound', 'NotificationSubscription still present';

        if (defined $rule1->workflow_def) {
            die 'Workflow has not been unlinked';
        }

    } 'Add and remove subscriber'
}

sub _rule_objects_creation {

    my @indicators = Entity::CollectorIndicator->search(hash => {collector_manager_id => $mock_monitor->id});

    my $cm1 = Entity::Metric::Clustermetric->new(
                  clustermetric_service_provider_id => $service_provider->id,
                  clustermetric_indicator_id => ((pop @indicators)->id),
                  clustermetric_statistics_function_name => 'mean',
              );

    my $acomb1 = Entity::Metric::Combination::AggregateCombination->new(
                     service_provider_id             =>  $service_provider->id,
                     aggregate_combination_formula   => 'id' . ($cm1->id),
                 );

    my $ac1 = Entity::AggregateCondition->new(
        aggregate_condition_service_provider_id => $service_provider->id,
        left_combination_id => $acomb1->id,
        comparator => '>',
        threshold => '0',
    );

    $rule1 = Entity::Rule::AggregateRule->new(
        service_provider_id => $service_provider->id,
        formula => 'id'.$ac1->id,
        state => 'enabled'
    );

    # Create nodemetric rule objects
    my $ncomb1 = Entity::Metric::Combination::NodemetricCombination->new(
                     service_provider_id             => $service_provider->id,
                     nodemetric_combination_formula  => 'id' . ((pop @indicators)->id)
                                                        . ' + id' . ((pop @indicators)->id),
                 );

    $nc1 = Entity::NodemetricCondition->new(
        nodemetric_condition_service_provider_id => $service_provider->id,
        left_combination_id => $ncomb1->id,
        nodemetric_condition_comparator => '>',
        nodemetric_condition_threshold => '0',
    );

}

sub _create_infra {
    $service_provider = Entity::ServiceProvider::Externalcluster->new(
                            externalcluster_name => 'Test Service Provider',
                        );

    my $external_cluster_mockmonitor = Entity::ServiceProvider::Externalcluster->new(
                                           externalcluster_name => 'Test Monitor',
                                       );

    $mock_monitor = Entity::Component::MockMonitor->new(
                           service_provider_id => $external_cluster_mockmonitor->id,
                       );

    $service_provider->addManager(
        manager_id      => $mock_monitor->id,
        manager_type    => 'CollectorManager',
        no_default_conf => 1,
    );

    #Create a SCO workflow
    my $external_cluster_sco = Entity::ServiceProvider::Externalcluster->new(
            externalcluster_name => 'Test SCO Workflow Manager',
    );

    $sco = Entity::Component::Sco->new(
            service_provider_id => $external_cluster_sco->id,
    );

    $service_provider->addManager(
        manager_id   => $sco->id,
        manager_type => 'WorkflowManager',
    );

    my $node_wf = $sco->createWorkflowDef(
                      workflow_name => 'Test Workflow',
                      params => {
                          internal => {
                              scope_id   => 1,
                              output_dir => '/tmp'
                          },
                          data => {
                              template_content => '[% node_hostname %]',
                          }
                      }
                  );

    $service_wf = $sco->createWorkflowDef(
        workflow_name => 'Test service Workflow',
        params => {
            internal => {
                scope_id   => 2,
                output_dir => '/tmp'
            },
            data => {
                template_content => 'hello world',
            }
        }
    );

    my $mailNotifier = Entity::Component::KanopyaMailNotifier->find();

    $service_provider->addManager(manager_type => 'NotificationManager',
                                  manager_id   => $mailNotifier->id);

    # Create one node
    my $node = Node->new(
        node_hostname => 'test_node',
        service_provider_id   => $service_provider->id,
        monitoring_state    => 'up',
    );
}
1;
