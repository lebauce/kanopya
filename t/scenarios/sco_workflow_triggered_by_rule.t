#!/usr/bin/perl


use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Data::Dumper;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'/tmp/orchestrator_test.log', layout=>'%F %L %p %m%n'});


lives_ok {
    use Administrator;

    use Executor;
    use Orchestrator;
    use Aggregator;
    use Entity::CollectorIndicator;
    use Entity::ServiceProvider::Outside::Externalcluster;
    use Entity::Connector::MockMonitor;
    use Entity::Connector::Sco;
    use Entity::Workflow;
    use Entity::Operation;
    use Entity::Combination;
    use Entity::Combination::NodemetricCombination;
    use Entity::NodemetricCondition;
    use Entity::NodemetricRule;
    use VerifiedNoderule;
    use WorkflowNoderule;
    use Entity::Clustermetric;
    use Entity::AggregateCondition;
    use Entity::Combination::AggregateCombination;
    use Entity::AggregateRule;
} 'All uses';

Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
my $adm = Administrator->new;
$adm->beginTransaction;

eval{
    my $executor = Executor->new();
    my $aggregator= Aggregator->new();

    my $external_cluster_mockmonitor = Entity::ServiceProvider::Outside::Externalcluster->new(
            externalcluster_name => 'Test Monitor',
    );

    my $mock_monitor = Entity::Connector::MockMonitor->new(
            service_provider_id => $external_cluster_mockmonitor->id,
    );

    my $service_provider = Entity::ServiceProvider::Outside::Externalcluster->new(
            externalcluster_name => 'Test Service Provider',
    );

    # Create one node
    my $node = Externalnode->new(
        externalnode_hostname => 'test_node',
        service_provider_id   => $service_provider->id,
        externalnode_state    => 'up',
    );

    lives_ok{
        $service_provider->addManager(
            manager_id   => $mock_monitor->id,
            manager_type => 'collector_manager',
        );
    } 'Add mock monitor to service provider';

    my @indicators = Entity::CollectorIndicator->search (hash => {collector_manager_id => $mock_monitor->id});

    my $agg_rule_ids  = service_rule_objects_creation(indicators => \@indicators);
    my $node_rule_ids = node_rule_objects_creation(indicators => \@indicators);

    $aggregator->update();

    # Launch orchestrator with no workflow to trigger
    my $orchestrator = Orchestrator->new();
    $orchestrator->manage_aggregates();

    check_rule_verification(
            agg_rule1_id  => $agg_rule_ids->{agg_rule1_id},
            agg_rule2_id  => $agg_rule_ids->{agg_rule2_id},
            node_rule1_id => $node_rule_ids->{node_rule1_id},
            node_rule2_id => $node_rule_ids->{node_rule2_id},
            node_id       => $node->id,
    );

    #Create a SCO workflow
    my $external_cluster_sco = Entity::ServiceProvider::Outside::Externalcluster->new(
            externalcluster_name => 'Test SCO Workflow Manager',
    );

    my $sco = Entity::Connector::Sco->new(
            service_provider_id => $external_cluster_sco->id,
    );

    lives_ok{
        $service_provider->addManager(
            manager_id   => $sco->id,
            manager_type => 'workflow_manager',
        );
    } 'Add workflow manager to service provider';

    my $node_wf;
    lives_ok {
        $node_wf = $sco->createWorkflow(
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
    } 'Create a new node workflow';

    my $service_wf;
    lives_ok {
        $service_wf = $sco->createWorkflow(
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
    } 'Create a new service workflow';


    lives_ok {
        $sco->associateWorkflow (
            new_workflow_name => $node_rule_ids->{node_rule2_id}.'_'.($node_wf->workflow_def_name),
            origin_workflow_def_id => $node_wf->id,
            specific_params => {},
            rule_id         =>  $node_rule_ids->{node_rule2_id},
        ) } 'Associate node workflow to node rule 2';

    lives_ok {
        $sco->associateWorkflow (
            new_workflow_name => $agg_rule_ids->{agg_rule2_id}.'_'.($service_wf->workflow_def_name),
            origin_workflow_def_id => $service_wf->id,
            specific_params => {specific_attribute => 'hello world!'},
            rule_id         => $agg_rule_ids->{agg_rule2_id},
        ) } 'Associate service workflow to service rule 2';

    #Launch orchestrator a workflow must be enqueued
    $orchestrator->manage_aggregates();

    my $workflow;
    lives_ok {
        $workflow = Entity::Workflow->find(hash=>{
            workflow_name => $node_rule_ids->{node_rule2_id}.'_'.($node_wf->workflow_def_name),
            state => 'running',
            related_id => $service_provider->id,
        });
    } 'Check triggered node workflow';

    my $service_workflow;
    lives_ok {
        $service_workflow = Entity::Workflow->find(hash=>{
            workflow_name => $agg_rule_ids->{agg_rule2_id}.'_'.($service_wf->workflow_def_name),
            state => 'running',
            related_id => $service_provider->id,
        });
    } 'Check triggered service workflow';

    lives_ok {
        WorkflowNoderule->find(hash=>{
            externalnode_id => $node->id,
            nodemetric_rule_id  => $node_rule_ids->{node_rule2_id},
            workflow_id => $workflow->id,
        });
    } 'Check WorkflowNoderule creation';

    lives_ok {
        Entity::Operation->find( hash => {
            type => 'LaunchSCOWorkflow',
            state => 'ready',
            workflow_id => $workflow->id,
        });
    } 'Check enqueued operation';

    lives_ok {
        Entity::Operation->find( hash => {
            type => 'LaunchSCOWorkflow',
            state => 'ready',
            workflow_id => $service_workflow->id,
        });
    } 'Check enqueued operation';

    #Execute operation 2 times (1 time per operation enqueud)
    $executor->oneRun();
    $executor->oneRun();

    #  Check node rule output
    my $sco_operation;
    lives_ok {
        $sco_operation = Entity::Operation->find( hash => {
            type => 'LaunchSCOWorkflow',
            state => 'postreported',
            workflow_id => $workflow->id,
        });
    } 'Check postreported operation';

    my $output_file = '/tmp/'.($sco_operation->getParams->{output_file});
    my $return_file = $sco_operation->getParams->{return_file};

    lives_ok {
        open(FILE,$output_file);
    } 'Open the output file';

    my @lines;
    while (<FILE>) {
        push @lines, $_;
    }

    ok ( $lines[0] eq $node->externalnode_hostname."\n", 'Check file contain line 1');
    ok ( $lines[1] eq $return_file, 'Check file contain line 2');

    close(FILE);

    lives_ok {
        chdir "/tmp";
        rename($output_file,$return_file);
        open(FILE,$return_file);
        close(FILE)
    } 'Rename the output sco node file';


    #  Check service rule output
    my $service_sco_operation;
    lives_ok {
        $service_sco_operation = Entity::Operation->find( hash => {
            type => 'LaunchSCOWorkflow',
            state => 'postreported',
            workflow_id => $service_workflow->id,
        });
    } 'Check postreported service sco operation';

    $output_file = '/tmp/'.($service_sco_operation->getParams->{output_file});
    $return_file = $service_sco_operation->getParams->{return_file};

    lives_ok {
        open(FILE,$output_file);
    } 'Open the output service file';

    @lines= ();
    while (<FILE>) {
        push @lines, $_;
    }

    ok ( $lines[0] eq $service_provider->externalcluster_name." hello world!\n", 'Check service file contain line 1');
    ok ( $lines[1] eq $return_file, 'Check service file contain line 2');

    close(FILE);

    lives_ok {
        chdir "/tmp";
        rename($output_file,$return_file);
        open(FILE,$return_file);
        close(FILE)
    } 'Rename the output sco service file';


    # Modify hoped_execution_time in order to avoid waiting for the delayed time
    $sco_operation->setAttr( name => 'hoped_execution_time', value => time() - 1);
    $sco_operation->save();

    # Modify hoped_execution_time in order to avoid waiting for the delayed time
    $service_sco_operation->setAttr( name => 'hoped_execution_time', value => time() - 1);
    $service_sco_operation->save();

    $executor->oneRun();
    $executor->oneRun();

    dies_ok {
        Entity::Operation->find( hash => {
            type => 'LaunchSCOWorkflow',
            workflow_id => $workflow->id,
        });
    } 'Check node operation has been deleted';

    dies_ok {
        Entity::Operation->find( hash => {
            type => 'LaunchSCOWorkflow',
            workflow_id => $service_workflow->id,
        });
    } 'Check service operation has been deleted';

    lives_ok {
        $workflow = Entity::Workflow->find(hash=>{
            workflow_name => $node_rule_ids->{node_rule2_id}.'_'.($node_wf->workflow_def_name),
            state => 'done',
            related_id => $service_provider->id,
        });
    } 'Check node workflow is done';

    lives_ok {
        $workflow = Entity::Workflow->find(hash=>{
            workflow_name => $agg_rule_ids->{agg_rule2_id}.'_'.($service_wf->workflow_def_name),
            state => 'done',
            related_id => $service_provider->id,
        });
    } 'Check service workflow is done';

    # Modify node rule2 to avoid a new triggering
    my $rule2 = Entity::NodemetricRule->get(id => $node_rule_ids->{node_rule2_id});
    $rule2->setAttr(name => 'nodemetric_rule_formula', value => '! ('.$rule2->nodemetric_rule_formula.')');
    $rule2->save();

    # Modify service rule2 to avoid a new triggering
    my $arule2 = Entity::AggregateRule->get(id => $agg_rule_ids->{agg_rule2_id});
    $arule2->setAttr(name => 'aggregate_rule_formula', value => 'not ('.$arule2->aggregate_rule_formula.')');
    $arule2->save();

    # Launch Orchestrator
    $orchestrator->manage_aggregates();

    dies_ok {
        VerifiedNoderule->find(hash => {
            verified_noderule_externalnode_id    => $node->id,
            verified_noderule_nodemetric_rule_id => $node_rule_ids->{node_rule2_id},
            verified_noderule_state              => 'verified',
        });
    } 'Check node rule 2 is not verified after formula has changed';

    lives_ok {
        Entity::AggregateRule->find(hash => {
            aggregate_rule_id => $agg_rule_ids->{agg_rule2_id},
            aggregate_rule_last_eval => 0,
        });
    } 'Check service rule 2 is not verified after formula has changed';

    dies_ok {
        WorkflowNoderule->find(hash=>{
            externalnode_id => $node->id,
            nodemetric_rule_id  => $rule2->id,
            workflow_id => $workflow->id,
        });
    } 'Check node WorkflowNoderule has been deleted';

    dies_ok {
        WorkflowNoderule->find(hash=>{
            externalnode_id => $node->id,
            nodemetric_rule_id  => $arule2->id,
            workflow_id => $service_workflow->id,
        });
    } 'Check service WorkflowNoderule has been deleted';

    my $wf1;
    my $wf2;
    lives_ok { $wf1 = Entity->get(id=>$rule2->id)->workflow_def } 'Check workflow def';
    lives_ok { $wf2 = Entity->get(id=>$arule2->id)->workflow_def } 'Check workflow def';

    $rule2->delete();
    $arule2->delete();

    dies_ok { WorkflowDef->get(id => $wf1->id)} 'Check workflow def deleted';
    dies_ok { WorkflowDef->get(id => $wf2->id)} 'Check workflow def deleted';

    sub test_rrd_remove {
    my @cms = Entity::Clustermetric->search (hash => {
        clustermetric_service_provider_id => $service_provider->id
    });
    
    my @cm_ids = map {$_->id} @cms;
    while (@cms) { (pop @cms)->delete(); };

    is (scalar Entity::Combination::AggregateCombination->search (hash => {
        service_provider_id => $service_provider->id
    }), 0, 'Check all aggregate combinations are deleted');

    is (scalar Entity::AggregateRule->search (hash => {
        aggregate_rule_service_provider_id => $service_provider->id
    }), 0, 'Check all aggregate rules are deleted');

    my $one_rrd_remove = 0;
    for my $cm_id (@cm_ids) {
        if (defined open(FILE,'/var/cache/kanopya/monitor/timeDB_'.$cm_id.'.rrd')) {
            $one_rrd_remove++;
        }
        close(FILE);
    }
    ok ($one_rrd_remove == 0, "Check all have been removed, still $one_rrd_remove rrd");
}
    #$adm->commitTransaction;
    $adm->rollbackTransaction;
};
if($@) {
    $adm->rollbackTransaction;
    my $error = $@;
    print $error."\n";
    test_rrd_remove();
}

sub service_rule_objects_creation {
    my %args = @_;
    my @indicators = @{$args{indicators}};

    my $rule1;
    my $rule2;

    lives_ok {

        my $service_provider = Entity::ServiceProvider::Outside::Externalcluster->find(
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

        $rule1 = Entity::AggregateRule->new(
            aggregate_rule_service_provider_id => $service_provider->id,
            aggregate_rule_formula => 'id'.$ac1->id.' && id'.$ac2->id,
            aggregate_rule_state => 'enabled'
        );

        $rule2 = Entity::AggregateRule->new(
            aggregate_rule_service_provider_id => $service_provider->id,
            aggregate_rule_formula => 'id'.$ac1->id.' || id'.$ac2->id,
            aggregate_rule_state => 'enabled'
        );
    } 'Create aggregate rules objects';
    return {
        agg_rule1_id => $rule1->id,
        agg_rule2_id => $rule2->id,
    };
}

sub node_rule_objects_creation {
    my %args = @_;
    my @indicators = @{$args{indicators}};
    my $rule1;
    my $rule2;

    lives_ok {
        my $service_provider = Entity::ServiceProvider::Outside::Externalcluster->find(
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

        $rule1 = Entity::NodemetricRule->new(
            nodemetric_rule_service_provider_id => $service_provider->id,
            nodemetric_rule_formula => 'id'.$nc1->id.' && id'.$nc2->id,
            nodemetric_rule_state => 'enabled'
        );

        $rule2 = Entity::NodemetricRule->new(
            nodemetric_rule_service_provider_id => $service_provider->id,
            nodemetric_rule_formula => 'id'.$nc1->id.' || id'.$nc2->id,
            nodemetric_rule_state => 'enabled'
        );

    } 'Create node rules objects';
    return {
        node_rule1_id => $rule1->id,
        node_rule2_id => $rule2->id,
    };
}



sub check_rule_verification {
    my %args = @_;

    lives_ok {
        Entity::AggregateRule->find(hash => {
            aggregate_rule_id => $args{agg_rule1_id},
            aggregate_rule_last_eval => 0,
        });
    } 'Service rule 1 is not verified';

    lives_ok {
        Entity::AggregateRule->find(hash => {
            aggregate_rule_id => $args{agg_rule2_id},
            aggregate_rule_last_eval => 1,
        });
    } 'Service rule 2 is verified';

    dies_ok {
        VerifiedNoderule->find(hash => {
            verified_noderule_externalnode_id    => $args{node_id},
            verified_noderule_nodemetric_rule_id => $args{node_rule1_id},,
            verified_noderule_state              => 'verified',
        })
    } 'Node rule 1 is not verified';

    lives_ok {
        VerifiedNoderule->find(hash => {
            verified_noderule_externalnode_id    => $args{node_id},
            verified_noderule_nodemetric_rule_id => $args{node_rule2_id},,
            verified_noderule_state              => 'verified',
        });
    } 'Node rule 2 is verified';
}
