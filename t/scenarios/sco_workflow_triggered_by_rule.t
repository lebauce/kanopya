#!/usr/bin/perl -w

=head1 SCOPE

Triggering and return of sco workflow using node and cluster rules

TODO

=head1 PRE-REQUISITE

None

=cut

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({
    level=>'DEBUG',
    file=>'sco_workflow_triggered_by_rule.log',
    layout=>'%F %L %p %m%n'
});

use BaseDB;

use RulesEngine;
use Aggregator;
use Entity::CollectorIndicator;
use Entity::ServiceProvider::Externalcluster;
use Entity::Component::MockMonitor;
use Entity::Component::Sco;
use Entity::Workflow;
use Entity::Operation;
use Entity::Combination;
use Entity::Combination::NodemetricCombination;
use Entity::NodemetricCondition;
use Entity::Rule::NodemetricRule;
use VerifiedNoderule;
use WorkflowNoderule;
use Entity::Clustermetric;
use Entity::AggregateCondition;
use Entity::Combination::AggregateCombination;
use Entity::Rule::AggregateRule;

use Kanopya::Tools::Execution;
use Kanopya::Tools::TestUtils 'expectedException';

my $testing = 0;

my $service_provider;

main();

sub main {
    BaseDB->authenticate( login =>'admin', password => 'K4n0pY4' );

    if ($testing == 1) {
        BaseDB->beginTransaction;
    }

    sco_workflow_triggered_by_rule();
#    clean_infra();

    if ($testing == 1) {
        BaseDB->rollbackTransaction;
    }
}

sub sco_workflow_triggered_by_rule {
    my $aggregator= Aggregator->new();

    my $external_cluster_mockmonitor = Entity::ServiceProvider::Externalcluster->new(
            externalcluster_name => 'Test Monitor',
    );

    my $mock_monitor = Entity::Component::MockMonitor->new(
            service_provider_id => $external_cluster_mockmonitor->id,
    );

    $service_provider = Entity::ServiceProvider::Externalcluster->new(
            externalcluster_name => 'Test Service Provider',
    );

    # Create one node
    my $node = Node->new(
        node_hostname => 'test_node',
        service_provider_id   => $service_provider->id,
        monitoring_state    => 'up',
    );

    diag('Add mock monitor to service provider');
    $service_provider->addManager(
        manager_id      => $mock_monitor->id,
        manager_type    => 'CollectorManager',
        no_default_conf => 1,
    );

    my @indicators = Entity::CollectorIndicator->search(hash => {collector_manager_id => $mock_monitor->id});

    my $agg_rule_ids  = _service_rule_objects_creation(indicators => \@indicators);
    my $node_rule_ids = _node_rule_objects_creation(indicators => \@indicators);

    sleep 2;
    $aggregator->update();

    # Launch orchestrator with no workflow to trigger
    my $rulesengine = RulesEngine->new();
    $rulesengine->_component->time_step(2);
    $rulesengine->refreshConfiguration();

    $rulesengine->oneRun();

    diag('Check rules verification');
    check_rule_verification(
            agg_rule1_id  => $agg_rule_ids->{agg_rule1_id},
            agg_rule2_id  => $agg_rule_ids->{agg_rule2_id},
            node_rule1_id => $node_rule_ids->{node_rule1_id},
            node_rule2_id => $node_rule_ids->{node_rule2_id},
            node_id       => $node->id,
    );

    #Create a SCO workflow
    my $external_cluster_sco = Entity::ServiceProvider::Externalcluster->new(
            externalcluster_name => 'Test SCO Workflow Manager',
    );

    my $sco = Entity::Component::Sco->new(
            service_provider_id => $external_cluster_sco->id,
    );

    diag('Add workflow manager to service provider');
    $service_provider->addManager(
        manager_id   => $sco->id,
        manager_type => 'WorkflowManager',
    );

    diag('Create a new node workflow');
    my $node_wf = $sco->createWorkflow(
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

    diag('Create a new service workflow');
    my $service_wf = $sco->createWorkflow(
        workflow_name => 'Test service Workflow',
        params => {
            internal => {
                scope_id   => 2,
                output_dir => '/tmp'
            },
            data => {
                template_content => '[% service_provider_name %] [% specific_attribute %]',
            }
        }
    );

    diag('Associate node workflow to node rule 2');
    $sco->associateWorkflow (
        new_workflow_name => $node_rule_ids->{node_rule2_id}.'_'.($node_wf->workflow_def_name),
        origin_workflow_def_id => $node_wf->id,
        specific_params => {},
        rule_id         =>  $node_rule_ids->{node_rule2_id},
    );

    diag('Associate service workflow to service rule 2');
    $sco->associateWorkflow (
        new_workflow_name => $agg_rule_ids->{agg_rule2_id}.'_'.($service_wf->workflow_def_name),
        origin_workflow_def_id => $service_wf->id,
        specific_params => {specific_attribute => 'hello world!'},
        rule_id         => $agg_rule_ids->{agg_rule2_id},
    );

    #Launch orchestrator a workflow must be enqueued
    $rulesengine->oneRun();

    my ($node_workflow, $service_workflow, $sco_operation, $service_sco_operation);
    lives_ok {
        diag('Check triggered node workflow');

        $node_workflow = Entity::Workflow->find(hash=>{
            workflow_name => $node_rule_ids->{node_rule2_id}.'_'.($node_wf->workflow_def_name),
            state => 'pending',
            related_id => $service_provider->id,
        });

        diag('Check triggered service workflow');
        $service_workflow = Entity::Workflow->find(hash=>{
            workflow_name => $agg_rule_ids->{agg_rule2_id}.'_'.($service_wf->workflow_def_name),
            state => 'pending',
            related_id => $service_provider->id,
        });

        diag('Check WorkflowNoderule creation');
        WorkflowNoderule->find(hash=>{
            node_id => $node->id,
            nodemetric_rule_id  => $node_rule_ids->{node_rule2_id},
            workflow_id => $node_workflow->id,
        });

        diag('Check triggered node enqueued operation');
        my $op_node = Entity::Operation->find( hash => {
            type => 'LaunchSCOWorkflow',
            state => 'pending',
            workflow_id => $node_workflow->id,
        });

        diag('Check triggered service enqueued operation');
        my $op_sco = Entity::Operation->find( hash => {
            type => 'LaunchSCOWorkflow',
            state => 'pending',
            workflow_id => $service_workflow->id,
        });

        # Execute operation 4 times (1 time per trigerred rule * 2 (op confirmation + op workflow))
        # Kanopya::Tools::Execution->nRun(n => 4);
        # Kanopya::Tools::Execution->executeAll();

        $DB::single = 1;

        my $executor = Executor->new(duration => 'SECOND');
        my @processes_rules = Entity::Operation->search(hash => {'operationtype.operationtype_name' => 'ProcessRule'});

        my $p1 = (pop @processes_rules);
        my $p2 = (pop @processes_rules);

        $executor->executeOperation(operation_id => $p1->id);
        $executor->handleResult(operation_id => $p1->id, status => $p1->state);

        $executor->executeOperation(operation_id => $p2->id);
        $executor->executeOperation(operation_id => $op_node->id);
        $executor->executeOperation(operation_id => $op_sco->id);


        #  Check node rule output
        diag('Check postreported operation');
        $sco_operation = Entity::Operation->find( hash => {
            type => 'LaunchSCOWorkflow',
            state => 'postreported',
            workflow_id => $node_workflow->id,
        });

        my $output_file = '/tmp/'.($sco_operation->unserializeParams->{output_file});
        my $return_file = $sco_operation->unserializeParams->{return_file};

        diag('Open the output file');
        open(FILE,$output_file);

        my @lines;
        while (<FILE>) {
            push @lines, $_;
        }

        diag('Check if node file contain line 1');
        die 'Node file does not contain line 1' if ( $lines[0] ne $node->node_hostname."\n");

        diag('Check if node file contain line 2');
        die 'Node file does not contain line 2' if ( $lines[1] ne $return_file);

        close(FILE);

        diag('Rename the output sco node file');
        chdir "/tmp";
        rename($output_file,$return_file);
        open(FILE,$return_file);
        close(FILE);

        #  Check service rule output
        diag('Check postreported service sco operation');
        $service_sco_operation = Entity::Operation->find( hash => {
            type => 'LaunchSCOWorkflow',
            state => 'postreported',
            workflow_id => $service_workflow->id,
        });

        $output_file = '/tmp/'.($service_sco_operation->unserializeParams->{output_file});
        $return_file = $service_sco_operation->unserializeParams->{return_file};

        diag('Open the output service file');
        open(FILE,$output_file);

        @lines= ();
        while (<FILE>) {
            push @lines, $_;
        }

        diag('Check if service file contain line 1');
        die 'Service file does not contain line 1' if ($lines[0] ne $service_provider->externalcluster_name." hello world!\n");

        diag('Check if service file contain line 2');
        die 'Service file does not contain line 2' if ($lines[1] ne $return_file);

        close(FILE);

        diag('Rename the output sco service file');
        chdir "/tmp";
        rename($output_file,$return_file);
        open(FILE,$return_file);
        close(FILE);
    } 'Triggering of SCO workflow using rule (node and service scope)';

    # Modify hoped_execution_time in order to avoid waiting for the delayed time
    $sco_operation->setAttr( name => 'hoped_execution_time', value => time() - 1);
    $sco_operation->save();

    # Modify hoped_execution_time in order to avoid waiting for the delayed time
    $service_sco_operation->setAttr( name => 'hoped_execution_time', value => time() - 1);
    $service_sco_operation->save();

    # Execute operation 2 times (1 time per operation enqueud)
    Kanopya::Tools::Execution->oneRun();
    Kanopya::Tools::Execution->oneRun();

    lives_ok {
        expectedException {
            Entity::Operation->find( hash => {
                type => 'LaunchSCOWorkflow',
                workflow_id => $node_workflow->id,
            });
        } 'Kanopya::Exception::Internal::NotFound',
        'Check node operation has been deleted';

        expectedException {
            Entity::Operation->find( hash => {
                type => 'LaunchSCOWorkflow',
                workflow_id => $service_workflow->id,
            });
        } 'Kanopya::Exception::Internal::NotFound',
        'Check service operation has been deleted';

        diag('Check if node workflow is done');
        $node_workflow = Entity::Workflow->find(hash=>{
            workflow_name => $node_rule_ids->{node_rule2_id}.'_'.($node_wf->workflow_def_name),
            state => 'done',
            related_id => $service_provider->id,
        });

        diag('Check if service workflow is done');
        $service_workflow = Entity::Workflow->find(hash=>{
            workflow_name => $agg_rule_ids->{agg_rule2_id}.'_'.($service_wf->workflow_def_name),
            state => 'done',
            related_id => $service_provider->id,
        });

        # Modify node rule2 to avoid a new triggering
        my $node_rule2 = Entity::Rule::NodemetricRule->get(id => $node_rule_ids->{node_rule2_id});
        $node_rule2->setAttr(name => 'formula', value => '! ('.$node_rule2->formula.')');
        $node_rule2->save();

        # Modify service rule2 to avoid a new triggering
        my $agg_rule2 = Entity::Rule::AggregateRule->get(id => $agg_rule_ids->{agg_rule2_id});
        $agg_rule2->setAttr(name => 'formula', value => 'not ('.$agg_rule2->formula.')');
        $agg_rule2->save();

        # Launch Orchestrator
        $rulesengine->oneRun();

        expectedException {
            VerifiedNoderule->find(hash => {
                verified_noderule_node_id    => $node->id,
                verified_noderule_nodemetric_rule_id => $node_rule_ids->{node_rule2_id},
                verified_noderule_state              => 'verified',
            });
        } 'Kanopya::Exception::Internal::NotFound',
        'Check node rule 2 is not verified after formula has changed';

        diag('Check if service rule 2 is not verified after formula has changed');
        Entity::Rule::AggregateRule->find(hash => {
            aggregate_rule_id => $agg_rule_ids->{agg_rule2_id},
            aggregate_rule_last_eval => 0,
        });

        expectedException {
            WorkflowNoderule->find(hash=>{
                node_id => $node->id,
                nodemetric_rule_id  => $node_rule2->id,
                workflow_id => $node_workflow->id,
            });
        } 'Kanopya::Exception::Internal::NotFound',
        'Check node WorkflowNoderule has been deleted';

        expectedException {
            WorkflowNoderule->find(hash=>{
                node_id => $node->id,
                nodemetric_rule_id  => $agg_rule2->id,
                workflow_id => $service_workflow->id,
            });
        } 'Kanopya::Exception::Internal::NotFound',
        'Check service WorkflowNoderule has been deleted';

        diag('Check node metric workflow def');
        my $wf1 = Entity->get(id=>$node_rule2->id)->workflow_def;

        diag('Check service metric workflow def');
        my $wf2 = Entity->get(id=>$agg_rule2->id)->workflow_def;

        $node_rule2->delete();
        expectedException {
            Entity::WorkflowDef->get(id => $wf1->id);
        } 'Kanopya::Exception::Internal::NotFound',
        'Node workflow def is deleted';

        $agg_rule2->delete();
        expectedException {
            Entity::WorkflowDef->get(id => $wf2->id);
        } 'Kanopya::Exception::Internal::NotFound',
        'Service workflow def is deleted';
    } 'Ending of triggered SCO workflow (node and service scope)';
}

sub check_rule_verification {
    my %args = @_;

    diag('# Service rule 1 verification');
    Entity::Rule::AggregateRule->find(hash => {
        aggregate_rule_id => $args{agg_rule1_id},
        aggregate_rule_last_eval => 0,
    });

    diag('# Service rule 2 verification');
    Entity::Rule::AggregateRule->find(hash => {
        aggregate_rule_id => $args{agg_rule2_id},
        aggregate_rule_last_eval => 1,
    });

    diag('# Node rule 1 verification');
    expectedException {
        VerifiedNoderule->find(hash => {
            verified_noderule_node_id    => $args{node_id},
            verified_noderule_nodemetric_rule_id => $args{node_rule1_id},
            verified_noderule_state              => 'verified',
        });
    } 'Kanopya::Exception::Internal::NotFound', 'Node rule 1 is not verified';

    diag('# Node rule 2 verification');
    VerifiedNoderule->find(hash => {
        verified_noderule_node_id    => $args{node_id},
        verified_noderule_nodemetric_rule_id => $args{node_rule2_id},
        verified_noderule_state              => 'verified',
    });
}

sub clean_infra {
    my @cms = Entity::Clustermetric->search (hash => {
        clustermetric_service_provider_id => $service_provider->id
    });

    my @cm_ids = map {$_->id} @cms;
    while (@cms) { (pop @cms)->delete(); };

    diag('Check if all aggregrate combinations have been deleted');
    my @acs = Entity::Combination::AggregateCombination->search (hash => {
        service_provider_id => $service_provider->id
    });
    if ( scalar @acs == 0 ) {
        diag('## checked');
    }
    else {
        die 'All aggregate combinations have not been deleted';
    }

    diag('Check if all aggregrate rules have been deleted');
    my @ars = Entity::Rule::AggregateRule->search (hash => {
        service_provider_id => $service_provider->id
    });
    if ( scalar @ars == 0 ) {
        diag('## checked');
    }
    else {
        die 'All aggregate rules have not been deleted';
    }

    diag('Check if all rrd have been deleted');
    my $one_rrd_remove = 0;
    for my $cm_id (@cm_ids) {
        if (defined open(FILE,'/var/cache/kanopya/monitor/timeDB_'.$cm_id.'.rrd')) {
            $one_rrd_remove++;
        }
        close(FILE);
    }
    if ($one_rrd_remove == 0) {
        diag('## checked');
    }
    else {
         die "All rrd have not been removed, still $one_rrd_remove rrd";
    }
}

sub _service_rule_objects_creation {
    my %args = @_;
    my @indicators = @{$args{indicators}};

    my $rule1;
    my $rule2;

    my $service_provider = Entity::ServiceProvider::Externalcluster->find(
        hash => {externalcluster_name => 'Test Service Provider'}
    );

    my $cm1 = Entity::Clustermetric->new(
        clustermetric_service_provider_id => $service_provider->id,
        clustermetric_indicator_id => ((pop @indicators)->id),
        clustermetric_statistics_function_name => 'mean',
        clustermetric_window_time => '1200',
    );

    my $cm2 = Entity::Clustermetric->new(
        clustermetric_service_provider_id => $service_provider->id,
        clustermetric_indicator_id => ((pop @indicators)->id),
        clustermetric_statistics_function_name => 'std',
        clustermetric_window_time => '1200',
    );

    my $acomb1 = Entity::Combination::AggregateCombination->new(
        service_provider_id             =>  $service_provider->id,
        aggregate_combination_formula   => 'id'.($cm1->id).' + id'.($cm2->id),
    );

    my $acomb2 = Entity::Combination::AggregateCombination->new(
        service_provider_id             =>  $service_provider->id,
        aggregate_combination_formula   => 'id'.($cm1->id).' + id'.($cm1->id),
    );

    my $ac1 = Entity::AggregateCondition->new(
        aggregate_condition_service_provider_id => $service_provider->id,
        left_combination_id => $acomb1->id,
        comparator => '>',
        threshold => '0',
    );

    my $ac2 = Entity::AggregateCondition->new(
        aggregate_condition_service_provider_id => $service_provider->id,
        left_combination_id => $acomb2->id,
        comparator => '<',
        threshold => '0',
    );

    $rule1 = Entity::Rule::AggregateRule->new(
        service_provider_id => $service_provider->id,
        formula => 'id'.$ac1->id.' && id'.$ac2->id,
        state => 'enabled'
    );

    $rule2 = Entity::Rule::AggregateRule->new(
        service_provider_id => $service_provider->id,
        formula => 'id'.$ac1->id.' || id'.$ac2->id,
        state => 'enabled'
    );

    return {
        agg_rule1_id => $rule1->id,
        agg_rule2_id => $rule2->id,
    };
}

sub _node_rule_objects_creation {
    my %args = @_;
    my @indicators = @{$args{indicators}};
    my $rule1;
    my $rule2;

    my $service_provider = Entity::ServiceProvider::Externalcluster->find(
        hash => {externalcluster_name => 'Test Service Provider'}
    );

    # Create nodemetric rule objects
    my $ncomb1 = Entity::Combination::NodemetricCombination->new(
        service_provider_id             => $service_provider->id,
        nodemetric_combination_formula  => 'id'.((pop @indicators)->id).' + id'.((pop @indicators)->id),
    );

    my $ncomb2 = Entity::Combination::NodemetricCombination->new(
        service_provider_id             => $service_provider->id,
        nodemetric_combination_formula  => 'id'.((pop @indicators)->id).' + id'.((pop @indicators)->id),
    );

    my $nc1 = Entity::NodemetricCondition->new(
        nodemetric_condition_service_provider_id => $service_provider->id,
        left_combination_id => $ncomb1->id,
        nodemetric_condition_comparator => '>',
        nodemetric_condition_threshold => '0',
    );

    my $nc2 = Entity::NodemetricCondition->new(
        nodemetric_condition_service_provider_id => $service_provider->id,
        left_combination_id => $ncomb2->id,
        nodemetric_condition_comparator => '<',
        nodemetric_condition_threshold => '0',
    );

    $rule1 = Entity::Rule::NodemetricRule->new(
        service_provider_id => $service_provider->id,
        formula => 'id'.$nc1->id.' && id'.$nc2->id,
        state => 'enabled'
    );

    $rule2 = Entity::Rule::NodemetricRule->new(
        service_provider_id => $service_provider->id,
        formula => 'id'.$nc1->id.' || id'.$nc2->id,
        state => 'enabled'
    );

    return {
        node_rule1_id => $rule1->id,
        node_rule2_id => $rule2->id,
    };
}
