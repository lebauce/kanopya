#!/usr/bin/perl -w

=head1 SCOPE

TODO

=head1 PRE-REQUISITE

These test needs :
One IAAS Opennebula with 2 hypervisors
4 vms on the first hypervisor

=cut

use strict;
use warnings;
use Test::More 'no_plan';
use Test::Exception;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({
    level=>'DEBUG',
    file=>'/vagrant/rules_on_state.log',
    layout=>'%F %L %p %m%n'
});

use Administrator;
use Aggregator;
use Orchestrator;
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

use Kanopya::Tools::Execution;
use Kanopya::Tools::TestUtils 'expectedException';

my $testing = 0;

my $aggregator;
my $orchestrator;
my $collector;
my ($hv1, $hv2);
my $one;

main();

sub main {
    Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
    my $adm = Administrator->new;

    if($testing == 1) {
        $adm->beginTransaction;
    }

    my $config = Kanopya::Config::get('monitor');
    $config->{time_step} = 5;

    Kanopya::Config::set(
        subsystem => 'monitor',
        config    => $config,
    );

    $aggregator   = Aggregator->new();
    $orchestrator = Orchestrator->new();
    $collector     = Monitor::Collector->new();
    #get orchestrator configuration

    $one = Entity::Component::Opennebula3->find(hash => {});
    my @hvs = $one->hypervisors;
    ($hv1, $hv2) = ($hvs[0], $hvs[1]);

    _remove_operations_and_locks();

    diag('Maintenance hypervisor');
    _split_2_2();
    _check_no_operation_and_no_lock();
    maintenance_hypervisor();

    diag('resubmit_vm_on_state');
    _check_no_operation_and_no_lock();
    _split_2_2();
    _check_no_operation_and_no_lock();
    resubmit_vm_on_state();

    diag('Resubmit hypervisor on state');
    _split_2_2();
    _check_no_operation_and_no_lock();
    resubmit_hv_on_state();

    diag('Resubmit hypervisor');
    _check_no_operation_and_no_lock();
    _split_2_2();
    _check_no_operation_and_no_lock();
    resubmit_hypervisor();
    _check_no_operation_and_no_lock();

    if ($testing == 1) {
        $adm->rollbackTransaction;
    }
}

sub resubmit_hv_on_state {
    lives_ok {
        my @hvs = $one->hypervisors;
        die 'There is not 2 hypervisors in the infra' if (scalar @hvs != 2);

        my ($hv1, $hv2) = @hvs;
        my @hv1_vms = $hv1->virtual_machines;
        my @hv2_vms = $hv2->virtual_machines;
        die 'Hv1 has not 2 vms' if (scalar @hv1_vms != 2);
        die 'Hv2 has not 2 vms' if (scalar @hv2_vms != 2);

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
        sleep(5);
        $collector->update();

        my $nodes_metrics = $hv_cluster->getNodesMetrics(
            indicators => \%indicators,
            time_span  => 1200,
        );

        die 'Hv1 is not up' if ($nodes_metrics ->{$hv1->host_hostname}->{'Host is up'} != 1);
        die 'Hv1 is activated' if ($hv1->active != 1);

        $orchestrator->manage_aggregates();

        $node->setAttr(name => 'node_state', value => 'broken:'.time());
        $node->save();

        sleep(5);
        $collector->update();

        $nodes_metrics = $hv_cluster->getNodesMetrics(
            indicators => \%indicators,
            time_span  => 1200,
        );

        die 'Hv1 is not broken' if ($nodes_metrics ->{$hv1->host_hostname}->{'Host is up'} != 0);

        expectedException {
            VerifiedNoderule->find( hash => {
                verified_noderule_externalnode_id       => $hv1->id,
                verified_noderule_nodemetric_rule_id    => $rule->id,
            });
        } 'Kanopya::Exception::DB',
        'Rule not verified';

        $orchestrator->manage_aggregates();

        my $verifNodeRule = VerifiedNoderule->find( hash => {
            verified_noderule_externalnode_id       => $hv1->node->id,
            verified_noderule_nodemetric_rule_id    => $rule->id,
            verified_noderule_state                 => 'verified',
        });
        diag 'Rule verified' if (defined $verifNodeRule);

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
        if (scalar @operations == 1) {
            diag('1 operation enqueued')
        }
        else {
            die '1 operation not enqueued';
        }

        die '### operation ResubmitHypervisor not enqueued' if ( (shift @operations)->type ne 'ResubmitHypervisor');

        Kanopya::Tools::Execution->oneRun();

        @operations = Entity::Operation->search(hash => {}, order_by => 'execution_rank asc');
        shift @operations; # Remove old ResubmitHypervisor operation
        if (scalar @operations == 6) {
            diag('6 operations enqueued');
        }
        else {
            die '6 operations not enqueued';
        }

        die '### operation ResubmitNode not enqueued' if ( (shift @operations)->type ne 'ResubmitNode');
        die '### operation ScaleCpuHost not enqueued' if ( (shift @operations)->type ne 'ScaleCpuHost');
        die '### operation ScaleMemoryHost not enqueued' if ( (shift @operations)->type ne 'ScaleMemoryHost');
        die '### operation ResubmitNode not enqueued' if ( (shift @operations)->type ne 'ResubmitNode');
        die '### operation ScaleCpuHost not enqueued' if ( (shift @operations)->type ne 'ScaleCpuHost');
        die '### operation ScaleMemoryHost not enqueued' if ( (shift @operations)->type ne 'ScaleMemoryHost');

        Kanopya::Tools::Execution->executeAll();

        $orchestrator->manage_aggregates();
        sleep(10);

        # With 60 sec delay, workflow is not relaunched
        $orchestrator->manage_aggregates();
        @operations = Entity::Operation->search(hash => {});
        if (scalar @operations == 0) {
            diag ('no operation waiting for delay');
        }
        else {
            die 'Operation is waiting for delay';
        }

        @hv1_vms = $hv1->virtual_machines;
        @hv2_vms = $hv2->virtual_machines;
        die 'Hv1 has not 0 vm' if (scalar @hv1_vms != 0);
        die 'Hv2 has not 4 vms' if (scalar @hv2_vms != 4);

        sleep(55);

        $orchestrator->manage_aggregates();

        @operations = Entity::Operation->search(hash => {});

        if (scalar @operations == 1) {
            diag ('End of delay, workflow re-enqueud');
        }
        else {
            die 'End of delay, workflow not re-enqueud';
        }

        while (@operations) { (pop @operations)->delete(); }
        $ncomb->delete();
    } 'Resubmit hypervisor on state';
}

sub resubmit_vm_on_state {
    lives_ok {
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
        my $old_ram = $vm->host_ram;
        my $old_cpu = $vm->host_core;

        for my $vm_t (@vms) {
            $collector->deleteRRD(set_name => 'state', host_name => $vm_t->host_hostname);
        }

        $node->setAttr(name => 'node_state', value => 'in:'.time());
        $node->save();

        my %indicators;
        $indicators{$indic->indicator->indicator_oid} = $indic->indicator;

        $collector->update();

        sleep(5);

        $collector->update();

        my $nodes_metrics = $vm_cluster->getNodesMetrics(
            indicators => \%indicators,
            time_span  => 1200,
        );

        die 'Host is not up' if ($nodes_metrics ->{$vm->host_hostname}->{'Host is up'} != 1);

        $orchestrator->manage_aggregates();

        my $evm = EFactory::newEEntity(data => $vm);

        eval {
            $evm->getEContext->execute(command => 'ifconfig eth0 down ; ifconfig eth1 down');
        };
        diag('Vm ifdown');

        $node->setAttr(name => 'node_state', value => 'broken:'.time());
        $node->save();

        $collector->update();

        sleep(5);

        $collector->update();

        $nodes_metrics = $vm_cluster->getNodesMetrics(
            indicators => \%indicators,
            time_span  => 1200,
        );

        if ($nodes_metrics ->{$vm->host_hostname}->{'Host is up'} != 0) {
            diag('Host is down');
        }
        else {
            die 'Host is not down';
        }

        expectedException {
            VerifiedNoderule->find( hash => {
                verified_noderule_externalnode_id       => $vm->id,
                verified_noderule_nodemetric_rule_id    => $rule->id,
            });
        } 'Kanopya::Exception::DB',
        'Rule not verified';

        $orchestrator->manage_aggregates();

        diag('Rule verification');
        my $verifNodeRule = VerifiedNoderule->find( hash => {
            verified_noderule_externalnode_id       => $vm->node->id,
            verified_noderule_nodemetric_rule_id    => $rule->id,
            verified_noderule_state                 => 'verified',
        });
        diag('### Rule verified') if (defined $verifNodeRule);

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
        if (scalar @operations == 3) {
            diag('3 operations enqueued');
        }
        else {
            die '3 operations not enqueued';
        }

        die 'operation ResubmitNode not enqueued' if ( (shift @operations)->type ne 'ResubmitNode');
        die 'operation ScaleCpuHost not enqueued' if ( (shift @operations)->type ne 'ScaleCpuHost');
        die 'operation ScaleMemoryHost not enqueued' if ( (shift @operations)->type ne 'ScaleMemoryHost');

        Kanopya::Tools::Execution->executeAll();

        _check_vm_ram(vm =>$vm, ram => $old_ram);
        _check_vm_cpu(vm =>$vm, cpu => $old_cpu);

        my ($state, $foo) = $vm->getNodeState();

        if ($state eq 'in') {
            diag('Node in');
        }
        else {
            die 'Node not in';
        }

        $orchestrator->manage_aggregates();
        sleep(10);

        # With 60 sec delay, workflow is not relaunched
        $orchestrator->manage_aggregates();
        @operations = Entity::Operation->search(hash => {});
        if (scalar @operations == 0) {
            diag('no operation waiting for delay');
        }
        else {
            die('Operation waiting for delay');
        }

        sleep(55);

        $orchestrator->manage_aggregates();

        @operations = Entity::Operation->search(hash => {});

        if (scalar @operations == 3) {
            diag ('End of delay, workflow re-enqueud');
        }
        else {
            die 'End of delay, workflow not re-enqueud';
        }

        while (@operations) { (pop @operations)->delete(); }
        $ncomb->delete();
    } 'Resubmit vm on state';
}

sub resubmit_hypervisor {
    lives_ok {
        my @hv1_vms = $hv1->virtual_machines;
        my @hv2_vms = $hv2->virtual_machines;

        my @old_rams = map {$_->host_ram} @hv2_vms;
        my @old_cpus = map {$_->host_core} @hv2_vms;


        die '1st hv has not 2 vms' if (scalar @hv1_vms != 2);
        die '2nd hv has not 2 vms' if (scalar @hv2_vms != 2);

        my $ehyp = EFactory::newEEntity(data => $hv2);

        eval {
            $ehyp->getEContext->execute(command => 'ifconfig eth0 down ; ifconfig eth1 down');
        };

        diag('Hypervisor ifdown');

        $hv2->resubmitVms;
        diag('EResubmitHypervisor execution');
        Kanopya::Tools::Execution->oneRun;

        my @ops = Entity::Operation->search(hash => {}, order_by => 'execution_rank ASC');

        my $id = 0;

        die 'No operation ResubmitHypervisor' if ($ops[$id++]->type ne 'ResubmitHypervisor');
        die 'No operation ResubmitNode' if ($ops[$id++]->type ne 'ResubmitNode');
        die 'No operation ScaleCpuHost' if ($ops[$id++]->type ne 'ScaleCpuHost');
        die 'No operation ScaleMemoryHost' if ($ops[$id++]->type ne 'ScaleMemoryHost');
        die 'No operation ResubmitNode' if ($ops[$id++]->type ne 'ResubmitNode');
        die 'No operation ScaleCpuHost' if ($ops[$id++]->type ne 'ScaleCpuHost');
        die 'No operation ScaleMemoryHost' if ($ops[$id++]->type ne 'ScaleMemoryHost');

        Kanopya::Tools::Execution->executeAll();

        _check_no_operation_and_no_lock();

        die 'Hv1 has not 4 vms' if (scalar $hv1->reload->virtual_machines != 4);
        die 'Hv2 has not 0 vm' if (scalar $hv2->reload->virtual_machines != 0);

        for my $i (0..(@hv2_vms-1)) {
            _check_vm_cpu(vm => $hv2_vms[$i], cpu => $old_cpus[$i]);
            _check_vm_ram(vm => $hv2_vms[$i], ram => $old_rams[$i]);
        }
    } 'Resubmit hypervisor';
}

sub maintenance_hypervisor {
    lives_ok {
        my @hv1_vms = $hv1->virtual_machines;
        my @hv2_vms = $hv2->virtual_machines;
        die 'Hv1 has not 2 vms' if (scalar @hv1_vms != 2);
        die 'Hv2 has 2 vms' if (scalar @hv2_vms != 2);

        $hv2->maintenance;
        diag('EFlushHypervisor execution');
        Kanopya::Tools::Execution->oneRun;

        my @ops = Entity::Operation->search(hash => {}, order_by => 'execution_rank ASC');

        die 'Operation 1 is not FlushHypervisor' if ($ops[0]->type ne 'FlushHypervisor');
        die 'Operation 2 is not MigrateHost' if ($ops[1]->type ne 'MigrateHost');
        die 'Operation 3 is not MigrateHost' if ($ops[2]->type ne 'MigrateHost');
        die 'Operation 4 is not DeactivateHost' if ($ops[3]->type ne 'DeactivateHost');

        Kanopya::Tools::Execution->executeAll();

        @hv1_vms = $hv1->virtual_machines;
        @hv2_vms = $hv2->virtual_machines;
        die 'Hv1 has not 4 vms' if (scalar @hv1_vms != 4);
        die 'Hv2 has not 0 vm' if (scalar @hv2_vms != 0);

        $hv2 = $hv2->reload;
        die 'hypervisor 2 has not been deactivated' if ($hv2->active != 0);

        $hv2->setAttr( name => 'active', value => '1');
        $hv2->save();
        die 'hypervisor 2 has not been re-activated' if ($hv2->reload->active != 1);
    } 'Hypervisor maintenance';
}

sub _check_no_operation_and_no_lock {
    my @ops = Entity::Operation->search(hash => {});
    is (@ops, 0, 'no more operation enqueued');
    my @locks = EntityLock->search(hash => {});
    is (@locks, 0, 'no more locks enqueued');
    _remove_operations_and_locks();
}

sub _remove_operations_and_locks {
    my @locks = EntityLock->search(hash => {});
    while (@locks) {
        (pop @locks)->delete();
    }

    my @ops = Entity::Operation->search(hash => {});
    while (@ops) {
	diag("delete op");
        (pop @ops)->delete();
    }

    my @nr = Entity::NodemetricRule->search(hash => {});
    while (@nr) {
        (pop @nr)->delete();
    }
    my @ar = Entity::AggregateRule->search(hash => {});
    while (@ar) {
        (pop @ar)->delete();
    }

}

sub _split_2_2 {
    my @vms = $one->opennebula3_vms;

    if ($hv1->virtual_machines > $hv2->virtual_machines) {
        while ($hv1->virtual_machines != $hv2->virtual_machines) {
            my @vms = $hv1->virtual_machines;
            my $vm = (pop @vms);
            $vm->migrate(hypervisor => $hv2);

            Kanopya::Tools::Execution->executeAll();
            is ($vm->reload->hypervisor->id, $hv2->id, 'Check vm has migrated');
        }
    }
    elsif ($hv1->virtual_machines < $hv2->virtual_machines) {
        while ($hv1->virtual_machines != $hv2->virtual_machines) {
            my @vms = $hv2->virtual_machines;
            my $vm = (pop @vms);
            $vm->migrate(hypervisor => $hv1);

            Kanopya::Tools::Execution->executeAll();
            is ($vm->reload->hypervisor->id, $hv1->id, 'Check vm has migrated');
        }
    }

    is ( scalar $hv1->virtual_machines, 2, 'Check split');
    is ( scalar $hv2->virtual_machines, 2, 'Check split');
}

sub _check_vm_ram {
    my %args = @_;
    my $vm = $args{vm}->reload;
    my $ram = $args{ram};

    if (!($vm->host_ram == $ram)) {
        die 'vm ram value in DB is wrong';
    }

    my $evm = EFactory::newEEntity(data => $vm);

    if (!($evm->getTotalMemory == $ram)) {
        die 'vm real ram value is wrong';
    }

    diag('# vm ram is ok');
}

sub _check_vm_cpu {
    my %args = @_;
    my $vm = $args{vm}->reload;
    my $cpu = $args{cpu};

    if (!($vm->host_core == $cpu)) {
        die 'vm cpu value in DB is wrong';
    }

    my $evm = EFactory::newEEntity(data => $vm);

    if (!($evm->getTotalCpu == $cpu)) {
        die 'real cpu value is wrong';
    }

    diag('# vm cpu is ok');
}