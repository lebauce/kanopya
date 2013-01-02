#!/usr/bin/perl -w

=head1 SCOPE

TODO

=head1 PRE-REQUISITE

TODO

=cut

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({
    level=>'DEBUG',
    file=>'/tmp/orchestrator_test.log',
    layout=>'%F %L %p %m%n'
});

use Administrator;

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

use Kanopya::Tools::Execution;
use Kanopya::Tools::TestUtils;

my $testing = 1;

my $service_provider;

main();

sub main {
    Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
    my $adm = Administrator->new;

    if ($testing == 1) {
        $adm->beginTransaction;
    }

    sco_workflow_triggered_by_rule();
    test_rrd_remove();

    if ($testing == 1) {
        $adm->rollbackTransaction;
    }
}

sub sco_workflow_triggered_by_rule {
    my $aggregator= Aggregator->new();

    my $external_cluster_mockmonitor = Entity::ServiceProvider::Outside::Externalcluster->new(
            externalcluster_name => 'Test Monitor',
    );

    my $mock_monitor = Entity::Connector::MockMonitor->new(
            service_provider_id => $external_cluster_mockmonitor->id,
    );

    $service_provider = Entity::ServiceProvider::Outside::Externalcluster->new(
            externalcluster_name => 'Test Service Provider',
    );

    # Create one node
    my $node = Externalnode->new(
        externalnode_hostname => 'test_node',
        service_provider_id   => $service_provider->id,
        externalnode_state    => 'up',
    );

    diag('Add mock monitor to service provider');
    $service_provider->addManager(
        manager_id      => $mock_monitor->id,
        manager_type    => 'collector_manager',
        no_default_conf => 1,
    );

    my @indicators = Entity::CollectorIndicator->search (hash => {collector_manager_id => $mock_monitor->id});

    my $agg_rule_ids  = _service_rule_objects_creation(indicators => \@indicators);
    my $node_rule_ids = _node_rule_objects_creation(indicators => \@indicators);

    $aggregator->update();

    # Launch orchestrator with no workflow to trigger
    my $orchestrator = Orchestrator->new();
    $orchestrator->manage_aggregates();

    diag('Check rules verification');
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

    diag('Add workflow manager to service provider');
    $service_provider->addManager(
        manager_id   => $sco->id,
        manager_type => 'workflow_manager',
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
    $orchestrator->manage_aggregates();

    diag('Check triggered node workflow');
    my $node_workflow = Entity::Workflow->find(hash=>{
        workflow_name => $node_rule_ids->{node_rule2_id}.'_'.($node_wf->workflow_def_name),
        state => 'running',
        related_id => $service_provider->id,
    });
    diag('Triggered node workflow checked');

    diag('Check triggered service workflow');
    my $service_workflow = Entity::Workflow->find(hash=>{
        workflow_name => $agg_rule_ids->{agg_rule2_id}.'_'.($service_wf->workflow_def_name),
        state => 'running',
        related_id => $service_provider->id,
    });
    diag('## checked');

    diag('Check WorkflowNoderule creation');
    WorkflowNoderule->find(hash=>{
        externalnode_id => $node->id,
        nodemetric_rule_id  => $node_rule_ids->{node_rule2_id},
        workflow_id => $node_workflow->id,
    });
    diag('## checked');

    diag('Check triggered node enqueued operation');
    Entity::Operation->find( hash => {
        type => 'LaunchSCOWorkflow',
        state => 'ready',
        workflow_id => $node_workflow->id,
    });
    diag('## checked');

    diag('Check triggered service enqueued operation');
    Entity::Operation->find( hash => {
        type => 'LaunchSCOWorkflow',
        state => 'ready',
        workflow_id => $service_workflow->id,
    });
    diag('## checked');

    #Execute operations enqueued
    Kanopya::Tools::Execution->executeAll();

    #  Check node rule output
    diag('Check postreported operation');
    my $sco_operation = Entity::Operation->find( hash => {
        type => 'LaunchSCOWorkflow',
        state => 'postreported',
        workflow_id => $node_workflow->id,
    });
    diag('## checked');

    my $output_file = '/tmp/'.($sco_operation->getParams->{output_file});
    my $return_file = $sco_operation->getParams->{return_file};

    diag('Open the output file');
    open(FILE,$output_file);

    my @lines;
    while (<FILE>) {
        push @lines, $_;
    }

    diag('Check if node file contain line 1');
    if ( $lines[0] eq $node->externalnode_hostname."\n") {
        diag('## checked');
    }
    else {
        die 'Node file does not contain line 1';
    }

    diag('Check if node file contain line 2');
    if ( $lines[1] ne $return_file) {
        diag('## checked');
    }
    else {
        die 'Node file does not contain line 2';
    }

    close(FILE);

    diag('Rename the output sco node file');
    chdir "/tmp";
    rename($output_file,$return_file);
    open(FILE,$return_file);
    close(FILE);

    #  Check service rule output
    diag('Check postreported service sco operation');
    my $service_sco_operation = Entity::Operation->find( hash => {
        type => 'LaunchSCOWorkflow',
        state => 'postreported',
        workflow_id => $service_workflow->id,
    });
    diag('## checked');

    $output_file = '/tmp/'.($service_sco_operation->getParams->{output_file});
    $return_file = $service_sco_operation->getParams->{return_file};

    diag('Open the output service file');
    open(FILE,$output_file);

    @lines= ();
    while (<FILE>) {
        push @lines, $_;
    }

    diag('Check if service file contain line 1');
    if ( $lines[0] eq $service_provider->externalcluster_name." hello world!\n") {
        diag('## checked');
    }
    else {
        die 'Service file does not contain line 1';
    }

    diag('Check if service file contain line 2');
    if ( $lines[1] eq $return_file) {
        diag('## checked');
    }
    else {
        die 'Service file does not contain line 2';
    }

    close(FILE);

    diag('Rename the output sco service file');
    chdir "/tmp";
    rename($output_file,$return_file);
    open(FILE,$return_file);
    close(FILE);

    # Modify hoped_execution_time in order to avoid waiting for the delayed time
    $sco_operation->setAttr( name => 'hoped_execution_time', value => time() - 1);
    $sco_operation->save();

    # Modify hoped_execution_time in order to avoid waiting for the delayed time
    $service_sco_operation->setAttr( name => 'hoped_execution_time', value => time() - 1);
    $service_sco_operation->save();

    Kanopya::Tools::Execution->executeAll();

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
    diag('## checked');

    diag('Check if service workflow is done');
    $service_workflow = Entity::Workflow->find(hash=>{
        workflow_name => $agg_rule_ids->{agg_rule2_id}.'_'.($service_wf->workflow_def_name),
        state => 'done',
        related_id => $service_provider->id,
    });
    diag('## checked');

    # Modify node rule2 to avoid a new triggering
    my $node_rule2 = Entity::NodemetricRule->get(id => $node_rule_ids->{node_rule2_id});
    $node_rule2->setAttr(name => 'nodemetric_rule_formula', value => '! ('.$node_rule2->nodemetric_rule_formula.')');
    $node_rule2->save();

    # Modify service rule2 to avoid a new triggering
    my $agg_rule2 = Entity::AggregateRule->get(id => $agg_rule_ids->{agg_rule2_id});
    $agg_rule2->setAttr(name => 'aggregate_rule_formula', value => 'not ('.$agg_rule2->aggregate_rule_formula.')');
    $agg_rule2->save();

    # Launch Orchestrator
    $orchestrator->manage_aggregates();

    expectedException {
        VerifiedNoderule->find(hash => {
            verified_noderule_externalnode_id    => $node->id,
            verified_noderule_nodemetric_rule_id => $node_rule_ids->{node_rule2_id},
            verified_noderule_state              => 'verified',
        });
    } 'Kanopya::Exception::Internal::NotFound',
    'Check node rule 2 is not verified after formula has changed';

    diag('Check if service rule 2 is not verified after formula has changed');
    Entity::AggregateRule->find(hash => {
        aggregate_rule_id => $agg_rule_ids->{agg_rule2_id},
        aggregate_rule_last_eval => 0,
    });
    diag('## checked');

    expectedException {
        WorkflowNoderule->find(hash=>{
            externalnode_id => $node->id,
            nodemetric_rule_id  => $node_rule2->id,
            workflow_id => $node_workflow->id,
        });
    } 'Kanopya::Exception::Internal::NotFound',
    'Check node WorkflowNoderule has been deleted';

    expectedException {
        WorkflowNoderule->find(hash=>{
            externalnode_id => $node->id,
            nodemetric_rule_id  => $agg_rule2->id,
            workflow_id => $service_workflow->id,
        });
    } 'Kanopya::Exception::Internal::NotFound',
    'Check service WorkflowNoderule has been deleted';

    diag('Check node metric workflow def');
    my $wf1 = Entity->get(id=>$node_rule2->id)->workflow_def;
    diag('## checked');

    diag('Check service metric workflow def');
    my $wf2 = Entity->get(id=>$agg_rule2->id)->workflow_def;
    diag('## checked');

    $node_rule2->delete();
    expectedException {
        WorkflowDef->get(id => $wf1->id);
    } 'Kanopya::Exception::Internal::NotFound',
    'Node workflow def is deleted';

    $agg_rule2->delete();
    expectedException {
        WorkflowDef->get(id => $wf2->id);
    } 'Kanopya::Exception::Internal::NotFound',
    'Service workflow def is deleted';
}

sub check_rule_verification {
    my %args = @_;

    lives_ok {
        diag('# Service rule 1 verification');
        Entity::AggregateRule->find(hash => {
            aggregate_rule_id => $args{agg_rule1_id},
            aggregate_rule_last_eval => 0,
        });
        diag('## verified');

        diag('# Service rule 2 verification');
        Entity::AggregateRule->find(hash => {
            aggregate_rule_id => $args{agg_rule2_id},
            aggregate_rule_last_eval => 1,
        });
        diag('## verified');

        diag('# Node rule 1 verification');
        VerifiedNoderule->find(hash => {
            verified_noderule_externalnode_id    => $args{node_id},
            verified_noderule_nodemetric_rule_id => $args{node_rule1_id},,
            verified_noderule_state              => 'verified',
        });
        diag('## verified');

        diag('# Node rule 2 verification');
        VerifiedNoderule->find(hash => {
            verified_noderule_externalnode_id    => $args{node_id},
            verified_noderule_nodemetric_rule_id => $args{node_rule2_id},,
            verified_noderule_state              => 'verified',
        });
        diag('## verified');
    } 'Rules verification';
}

sub test_rrd_remove {
    lives_ok {
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
        my @ars = Entity::AggregateRule->search (hash => {
            aggregate_rule_service_provider_id => $service_provider->id
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
             "All rrd have not been removed, still $one_rrd_remove rrd";
        }
    } 'Test rrd remove';
}

sub _service_rule_objects_creation {
    my %args = @_;
    my @indicators = @{$args{indicators}};

    my $rule1;
    my $rule2;

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

    return {
        node_rule1_id => $rule1->id,
        node_rule2_id => $rule2->id,
    };
}