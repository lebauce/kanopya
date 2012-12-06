#!/usr/bin/perl

use strict;
use warnings;
use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Data::Dumper;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'/tmp/rules_on_state.log', layout=>'%F %L %p %m%n'});
my $log = get_logger("");

lives_ok {
    use Administrator;
    use Aggregator;
    use Orchestrator;
    use Executor;
    use Monitor::Collector;
    use Entity;
    use Entity::Component::Opennebula3;
    use Entity::ServiceProvider::Outside::Externalcluster;
    use Entity::Connector::MockMonitor;
    use Entity::Clustermetric;
    use Entity::AggregateCondition;
    use Entity::Combination::AggregateCombination;
    use Entity::AggregateRule;
    use Entity::Combination::NodemetricCombination;
    use Entity::NodemetricCondition;
    use Entity::NodemetricRule;
    use VerifiedNoderule;
    use Entity::Workflow;
    use Entity::WorkflowDef;
    use Kanopya::Config;
} 'All uses';

Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
my $adm = Administrator->new;
#$adm->beginTransaction;

my $aggregator;
my $orchestrator;
my $executor;
my $collector;
my ($hv1, $hv2);
my $one;
main();

sub main {
    eval{

        # These test needs :
        # One IAAS Opennebula with 2 hypervisors
        # 4 vms on the first hypervisor

        my $config = Kanopya::Config::get('monitor');
        $config->{time_step} = 5;

        Kanopya::Config::set(
            subsystem => 'monitor',
            config    => $config,
        );

        $executor     = Executor->new();
        $aggregator   = Aggregator->new();
        $orchestrator = Orchestrator->new();
        $collector     = Monitor::Collector->new();
        #get orchestrator configuration

        $one = Entity::Component::Opennebula3->find(hash => {});
        my @hvs = $one->hypervisors;
        ($hv1, $hv2) = ($hvs[0], $hvs[1]);

        remove_operations_and_locks();
        split_2_2();
        check_no_operation_and_no_lock();
        maintenance_hypervisor();
        check_no_operation_and_no_lock();
        split_2_2();
        check_no_operation_and_no_lock();
        resubmit_hypervisor();
        check_no_operation_and_no_lock();
        split_2_2();
        check_no_operation_and_no_lock();
        resubmit_vm_on_state();
        split_2_2();
        check_no_operation_and_no_lock();
        resubmit_hv_on_state();
        check_no_operation_and_no_lock();

    };
    if($@) {
        my $error = $@;
        print $error."\n";
    #    test_rrd_remove();
        $adm->rollbackTransaction;
    }
}

sub resubmit_hv_on_state {

    my @hvs = $one->hypervisors;
    is (scalar @hvs, 2, '2 hypervisors in the infra');

    my ($hv1, $hv2) = @hvs;
    my @hv1_vms = $hv1->virtual_machines;
    my @hv2_vms = $hv2->virtual_machines;
    is (scalar @hv1_vms, 2, 'Hv1 has 2 vms');
    is (scalar @hv2_vms, 2, 'Hv2 has 2 vms');

    my $hv_cluster = $hv1->node->inside;

    # Get indicators
    my $indic = Entity::CollectorIndicator->find (
        hash => { 'indicator.indicator_label' => 'state/Up' }
    );

    #  Nodemetric combination
    my $ncomb = Entity::Combination::NodemetricCombination->new(
        service_provider_id             => $hv_cluster->id,
        nodemetric_combination_formula  => 'id'.($indic->id),
    );

    my $ncond = Entity::NodemetricCondition->new(
        nodemetric_condition_service_provider_id => $hv_cluster->id,
        left_combination_id             => $ncomb->id,
        nodemetric_condition_comparator => '==',
        nodemetric_condition_threshold  => '0',
    );

    my $rule = Entity::NodemetricRule->new(
        nodemetric_rule_service_provider_id => $hv_cluster->id,
        nodemetric_rule_formula => 'id'.$ncond->id,
        nodemetric_rule_state => 'enabled'
    );

    my $node = $hv1->node;

    for my $hv_t (@hvs) {
        $collector->deleteRRD(set_name => 'state', host_name => $hv_t->host_hostname);
    }

    $node->setAttr(name => 'node_state', value => 'in:'.time());
    $node->save();

    my %indicators;
    $indicators{$indic->indicator->indicator_oid} = $indic->indicator;

    $collector->update();
    sleep(4);
    $collector->update();


    my $nodes_metrics = $hv_cluster->getNodesMetrics(
        indicators => \%indicators,
        time_span  => 1200,
    );

    is ($nodes_metrics ->{$hv1->host_hostname}->{'Host is up'}, 1, 'Hv1 is up');
    is ($hv1->active, 1, 'Hv1 is activated');

    $orchestrator->manage_aggregates();

    $node->setAttr(name => 'node_state', value => 'broken:'.time());
    $node->save();

    $collector->update();
    for my $i (1..5) {
        sleep(4);
        $collector->update();
    }

    $nodes_metrics = $hv_cluster->getNodesMetrics(
        indicators => \%indicators,
        time_span  => 1200,
    );

    is ($nodes_metrics ->{$hv1->host_hostname}->{'Host is up'}, 0, 'Hv1 is broken');

    dies_ok {
        VerifiedNoderule->find( hash => {
            verified_noderule_externalnode_id       => $hv1->id,
            verified_noderule_nodemetric_rule_id    => $rule->id,
        });
    } 'Rule not verified';

    $orchestrator->manage_aggregates();

    lives_ok {
        VerifiedNoderule->find( hash => {
            verified_noderule_externalnode_id       => $hv1->node->id,
            verified_noderule_nodemetric_rule_id    => $rule->id,
            verified_noderule_state                 => 'verified',
        });
    } 'Rule verified';

    my $wf_manager = $hv_cluster->findRelated(
                         filters    => ['service_provider_managers'],
                         hash       => { manager_type => 'workflow_manager' }
                     )->manager;


    my $workflow_def = Entity::WorkflowDef->find(hash => {workflow_def_name => 'ResubmitHypervisor'});

    $wf_manager->associateWorkflow(
        new_workflow_name       => $rule->id.'_'.($workflow_def->workflow_def_name),
        origin_workflow_def_id  => $workflow_def->id,
        rule_id                 => $rule->id,
        specific_params         => { delay => 60 },
    );

    $orchestrator->manage_aggregates();

    my @operations = Entity::Operation->search(hash => {}, order_by => 'execution_rank asc');
    is (scalar @operations, 1, '1 operation enqueued');
    is ( (shift @operations)->type, 'ResubmitHypervisor', 'operation ResubmitHypervisor enqueued');
    $executor->oneRun();
    @operations = Entity::Operation->search(hash => {}, order_by => 'execution_rank asc');
    shift @operations; # Remove old ResubmitHypervisor operation
    is (scalar @operations, 6, '6 operations enqueued');

    is ( (shift @operations)->type, 'ResubmitNode', 'operation ResubmitNode enqueued');
    is ( (shift @operations)->type, 'ScaleCpuHost', 'operation ScaleCpuHost enqueued');
    is ( (shift @operations)->type, 'ScaleMemoryHost', 'operation ScaleMemoryHost enqueued');
    is ( (shift @operations)->type, 'ResubmitNode', 'operation ResubmitNode enqueued');
    is ( (shift @operations)->type, 'ScaleCpuHost', 'operation ScaleCpuHost enqueued');
    is ( (shift @operations)->type, 'ScaleMemoryHost', 'operation ScaleMemoryHost enqueued');

    executor_real_infra();

    $orchestrator->manage_aggregates();
    sleep(10);

    # With 60 sec delay, workflow is not relaunched
    $orchestrator->manage_aggregates();
    @operations = Entity::Operation->search(hash => {});
    is (scalar @operations, 0, 'no operation waiting for delay');

    @hv1_vms = $hv1->virtual_machines;
    @hv2_vms = $hv2->virtual_machines;
    is (scalar @hv1_vms, 0, 'Hv1 has 0 vms');
    is (scalar @hv2_vms, 4, 'Hv2 has 4 vms');

    sleep(55);
    $orchestrator->manage_aggregates();
    @operations = Entity::Operation->search(hash => {});
    is (scalar @operations, 1, 'And of delay, workflow re-enqueud');
    while (@operations) { (pop @operations)->delete(); }
    $ncomb->delete();
}

sub resubmit_vm_on_state {
    print "resubmit_vm_on_state \n";

    my @spms = $one->service_provider_managers;
    my $vm_cluster = $spms[0]->service_provider;

    # Get indicators
    my $indic = Entity::CollectorIndicator->find (
        hash => { 'indicator.indicator_label' => 'state/Up' }
    );

    #  Nodemetric combination
    my $ncomb = Entity::Combination::NodemetricCombination->new(
        service_provider_id             => $vm_cluster->id,
        nodemetric_combination_formula  => 'id'.($indic->id),
    );

    my $ncond = Entity::NodemetricCondition->new(
        nodemetric_condition_service_provider_id => $vm_cluster->id,
        left_combination_id             => $ncomb->id,
        nodemetric_condition_comparator => '==',
        nodemetric_condition_threshold  => 0,
    );

    my $rule = Entity::NodemetricRule->new(
        nodemetric_rule_service_provider_id => $vm_cluster->id,
        nodemetric_rule_formula => 'id'.$ncond->id,
        nodemetric_rule_state => 'enabled'
    );

    my @vms = $one->opennebula3_vms;
    my $vm = $vms[0];
    my $node = $vm->node;

    for my $vm_t (@vms) {
        $collector->deleteRRD(set_name => 'state', host_name => $vm_t->host_hostname);
    }

    $node->setAttr(name => 'node_state', value => 'in:'.time());
    $node->save();

    my %indicators;
    $indicators{$indic->indicator->indicator_oid} = $indic->indicator;

    $collector->update();

    sleep(4);

    $collector->update();

    my $nodes_metrics = $vm_cluster->getNodesMetrics(
        indicators => \%indicators,
        time_span  => 1200,
    );

    is ($nodes_metrics ->{$vm->host_hostname}->{'Host is up'}, 1, 'Host is up');

    $orchestrator->manage_aggregates();

    $node->setAttr(name => 'node_state', value => 'broken:'.time());
    $node->save();

    $collector->update();
    for my $i (1..5) {
        sleep(4);
        $collector->update();
    }

    $nodes_metrics = $vm_cluster->getNodesMetrics(
        indicators => \%indicators,
        time_span  => 1200,
    );

    is ($nodes_metrics ->{$vm->host_hostname}->{'Host is up'}, 0, 'Host is down');

    dies_ok {
        VerifiedNoderule->find( hash => {
            verified_noderule_externalnode_id       => $vm->id,
            verified_noderule_nodemetric_rule_id    => $rule->id,
        });
    } 'Rule not verified';

    $orchestrator->manage_aggregates();

    lives_ok {
        VerifiedNoderule->find( hash => {
            verified_noderule_externalnode_id       => $vm->node->id,
            verified_noderule_nodemetric_rule_id    => $rule->id,
            verified_noderule_state                 => 'verified',
        });
    } 'Rule verified';

    my $wf_manager = $vm_cluster->findRelated(
                         filters    => ['service_provider_managers'],
                         hash       => { manager_type => 'workflow_manager' }
                     )->manager;


    my $workflow_def = Entity::WorkflowDef->find(hash => {workflow_def_name => 'ResubmitNode'});

    $wf_manager->associateWorkflow(
        new_workflow_name       => $rule->id.'_'.($workflow_def->workflow_def_name),
        origin_workflow_def_id  => $workflow_def->id,
        rule_id                 => $rule->id,
        specific_params         => { delay => 60 },
    );

    $orchestrator->manage_aggregates();

    my @operations = Entity::Operation->search(hash => {}, order_by => 'execution_rank asc');
    is (scalar @operations, 3, '3 operations enqueued');

    is ( (shift @operations)->type, 'ResubmitNode', 'operation ResubmitNode enqueued');
    is ( (shift @operations)->type, 'ScaleCpuHost', 'operation ScaleCpuHost enqueued');
    is ( (shift @operations)->type, 'ScaleMemoryHost', 'operation ScaleMemoryHost enqueued');

    executor_real_infra();

    my ($state, $foo) = $vm->getNodeState();
    is ($state, 'in', 'Node in' );


    $orchestrator->manage_aggregates();
    sleep(10);

    # With 60 sec delay, workflow is not relaunched
    $orchestrator->manage_aggregates();
    @operations = Entity::Operation->search(hash => {});
    is (scalar @operations, 0, 'no operation waiting for delay');

    sleep(55);
    $orchestrator->manage_aggregates();
    @operations = Entity::Operation->search(hash => {});
    is (scalar @operations, 3, 'And of delay, workflow re-enqueued');
    while (@operations) { (pop @operations)->delete(); }
    $ncomb->delete();
}

sub remove_operations_and_locks {
    my @locks = EntityLock->search(hash => {});
    while (@locks) {
        (pop @locks)->delete();
    }

    my @ops = Entity::Operation->search(hash => {});
    while (@ops) {
        (pop @ops)->delete();
    }

}
sub resubmit_hypervisor {

    my @hv1_vms = $hv1->virtual_machines;
    my @hv2_vms = $hv2->virtual_machines;
    is (scalar @hv1_vms, 2, '1st hv has 2 vms');
    is (scalar @hv2_vms, 2, '2nd hv has 2 vms');

    $hv2->resubmitVms;
    lives_ok { $executor->oneRun; } 'EResubmitHypervisor execution';

    my @ops = Entity::Operation->search(hash => {}, order_by => 'execution_rank ASC');

    my $id = 0;

    is ($ops[$id++]->type, 'ResubmitHypervisor', 'Operation ResubmitHypervisor');
    is ($ops[$id++]->type, 'ResubmitNode', 'Operation ResubmitNode');
    is ($ops[$id++]->type, 'ScaleCpuHost', 'Operation ScaleCpuHost');
    is ($ops[$id++]->type, 'ScaleMemoryHost', 'Operation ScaleMemoryHost');
    is ($ops[$id++]->type, 'ResubmitNode', 'Operation ResubmitNode');
    is ($ops[$id++]->type, 'ScaleCpuHost', 'Operation ScaleCpuHost');
    is ($ops[$id++]->type, 'ScaleMemoryHost', 'Operation ScaleMemoryHost');

    executor_real_infra();

    check_no_operation_and_no_lock();

    is (scalar $hv1->virtual_machines, 4, 'Hv1 has 4 vms');
    is (scalar $hv2->virtual_machines, 0, 'Hv2 has 0 vms');
}

sub maintenance_hypervisor {

    my @hv1_vms = $hv1->virtual_machines;
    my @hv2_vms = $hv2->virtual_machines;
    is (scalar @hv1_vms, 2, 'Hv1 has 2 vms');
    is (scalar @hv2_vms, 2, 'Hv2 has 2 vms');

    $hv2->maintenance;

    lives_ok { $executor->oneRun; } 'EFlushHypervisor execution';

    my @ops = Entity::Operation->search(hash => {}, order_by => 'execution_rank ASC');

    is ($ops[0]->type, 'FlushHypervisor', 'Operation FlushHypervisor');
    is ($ops[1]->type, 'MigrateHost', 'Operation MigrateHost');
    is ($ops[2]->type, 'MigrateHost', 'Operation MigrateHost');
    is ($ops[3]->type, 'DeactivateHost', 'Operation DeactivateHost');

    executor_real_infra();

    @hv1_vms = $hv1->virtual_machines;
    @hv2_vms = $hv2->virtual_machines;
    is (scalar @hv1_vms, 4, 'Hv1 has 4 vms');
    is (scalar @hv2_vms, 0, 'Hv2 has 0 vms');

    $hv2 = $hv2->reload;
    is($hv2->active, 0, 'hypervisor 2 has been deactivated');
    $hv2->setAttr( name => 'active', value => '1');
    $hv2->save();

    is($hv2->reload->active, 1, 'hypervisor 2 has been re-activated');
}

sub check_no_operation_and_no_lock {
    my @ops = Entity::Operation->search(hash => {});
    is (@ops, 0, 'no more operation enqueued');
    my @locks = EntityLock->search(hash => {});
    is (@locks, 0, 'no more locks enqueued');
    remove_operations_and_locks();
}


sub split_2_2 {
    my @vms = $one->opennebula3_vms;

    if ($hv1->virtual_machines > $hv2->virtual_machines) {
        while ($hv1->virtual_machines != $hv2->virtual_machines) {
            my @vms = $hv1->virtual_machines;
            my $vm = (pop @vms);
            $vm->migrate(hypervisor => $hv2);

            executor_real_infra();
            is ($vm->reload->hypervisor->id, $hv2->id, 'Check vm has migrated');
        }
    }
    elsif ($hv1->virtual_machines < $hv2->virtual_machines) {
        while ($hv1->virtual_machines != $hv2->virtual_machines) {
            my @vms = $hv2->virtual_machines;
            my $vm = (pop @vms);
            $vm->migrate(hypervisor => $hv1);

            executor_real_infra();
            is ($vm->reload->hypervisor->id, $hv1->id, 'Check vm has migrated');
        }
    }

    is ( scalar $hv1->virtual_machines, 2, 'Check split');
    is ( scalar $hv2->virtual_machines, 2, 'Check split');
}

sub executor_real_infra {
    my %args = @_;
    lives_ok {
        my $timeout = $args{timeout} || 300;
        my $operation;
        while ($timeout > 0) {
            eval {
                $operation = Entity::Operation->find(hash => {});
            };
            if ($@) {
                last;
            }
            else {
                sleep 5;
                $timeout -= 5;
                $executor->oneRun;
            }
        }
    } 'Waiting maximum 300 seconds for the host to start';
}

