#!/usr/bin/perl -w

=head1 SCOPE

Live migration of virtual machines

=head1 PRE-REQUISITE

One IAAS Opennebula with 2 hypervisors (each >= 2048 Mb)
4 vms (512 Mb Ram each) on the first hypervisor (BOTH in Kanopya.Database and in real infrastructure)

=cut

use strict;
use warnings;
use Test::More 'no_plan';
use Test::Exception;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({
    level=>'DEBUG',
    file=>'/vagrant/live_migration.log',
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

my $testing = 0;

my $executor;

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

    $one = Entity::Component::Opennebula3->find(hash => {});
    my @hvs = $one->hypervisors;
    ($hv1, $hv2) = ($hvs[0], $hvs[1]);

    diag('Remove operations and locks (from a previous failed test)');
    _remove_operations_and_locks();
    diag('Test of live migration normal case');
    lm_normal();
    diag('Test of live migration limit case (live migration with JUST enough place)');
    lm_limit();
    diag('Test of sequential live migration with NOT enough place for one VM (from Kanopya view)');
    lm_sequential_no_place_kanopya();
    diag('Test of successive live migrations with NOT enough place for all VMs (from Kanopya view)');
    lm_successive_no_place_kanopya();
    # TODO : test of no place with over commitment
    diag("Test of live migration on an hypervisor deactivated");
    lm_hypervisor_deactivated();
    diag('Test of live migration of a VM down');
    lm_vm_down();
    diag("Test of live migration on an hypervisor down");
    lm_hypervisor_down();
    # hosts down are resubmitted at end of test
    # to avoid run of related workflows by a _executor_wait() of later test case
    diag('Resubmit host down');
    _resubmit_hosts();

    if ($testing == 1) {
        $adm->rollbackTransaction;
    }
}

sub lm_normal {
    my @hv1_vms = $hv1->virtual_machines;
    my $vm1_hv1 = $hv1_vms[0];
    $vm1_hv1->migrate(hypervisor => $hv2);
    Kanopya::Tools::Execution->executeAll();

    is ($vm1_hv1->reload->hypervisor->id, $hv2->id, 'Live migration of 1 VM (basic case)');
}

sub lm_limit {
    lives_ok {
        # now we should have 3 VMs on hv1 and 1 VM on hv2
        # we try to migrate (sequentially) all VMs from hv1 to hv2
        my $hv1_initial_ram = $hv1->host_ram;
        $hv1->setAttr(
            name    => 'host_ram',
            value   => 2048 * 1024 * 1024
        );
        $hv1->save();

        my @hv1_vms = $hv1->virtual_machines;
        my $vm1_hv1 = $hv1_vms[0];
        my $vm2_hv1 = $hv1_vms[1];
        my $vm3_hv1 = $hv1_vms[2];

        diag('#Live migrations');
        # 1st migration
        $vm1_hv1->migrate(hypervisor => $hv2);
        Kanopya::Tools::Execution->executeAll();
        die '## VM1 has not migrated' if ( $vm1_hv1->reload->hypervisor->id != $hv2->id );
        # 2nd migration
        $vm2_hv1->migrate(hypervisor => $hv2);
        Kanopya::Tools::Execution->executeAll();
        die '## VM2 has not migrated' if ( $vm2_hv1->reload->hypervisor->id != $hv2->id );
        # 3rd migration
        $vm3_hv1->migrate(hypervisor => $hv2);
        Kanopya::Tools::Execution->executeAll();
        die '## VM3 has not migrated' if ( $vm3_hv1->reload->hypervisor->id != $hv2->id );

        # hv1 host is returned to it's initial state
        $hv1->setAttr(
            name    => 'host_ram',
            value   => $hv1_initial_ram
        );
        $hv1->save();
    } 'Live migration limit case (live migration with just enough place)';
}

sub lm_sequential_no_place_kanopya {
    lives_ok {
        # now we should have 0 VM on hv1 and 4 VMs on hv2
        # we want to live migrate 2 VMs with not to have enough place for 2 SEQUENTIAL live migrations
        my $hv1_initial_ram = $hv1->host_ram;
        $hv1->setAttr(
            name    => 'host_ram',
            value   => 800 * 1024 * 1024
        );
        $hv1->save();

        # 2 sequential migrations
        diag('#Live migrations');
        my @hv2_vms = $hv2->virtual_machines;
        my $vm1_hv2 = $hv2_vms[0];
        my $vm2_hv2 = $hv2_vms[1];
        # 1st migration : VM should migrate
        $vm1_hv2->migrate(hypervisor => $hv1);
        Kanopya::Tools::Execution->executeAll();
        die '## VM1 has not migrated' if ( $vm1_hv2->reload->hypervisor->id != $hv1->id );
        # 2nd migration : VM should not migrate
        $vm2_hv2->migrate(hypervisor => $hv1);
        die '## VM2 has migrated' if( $vm2_hv2->reload->hypervisor->id != $hv2->id );
        Kanopya::Tools::Execution->executeAll();

        # hv1 host is returned to it's initial state
        $hv1->setAttr(
            name    => 'host_ram',
            value   => $hv1_initial_ram
        );
        $hv1->save();
    } 'Sequential live migrations of 2 VMs with only enough place for one (from Kanopya view)';
}

sub lm_successive_no_place_kanopya {
    lives_ok {
        # now we should have 1 VM on hv1 and 3 VMs on hv2
        # we want to live migrate 2 VMs with not to have enough place for 2 SUCCESSIVE live migrations
        my $hv1_initial_ram = $hv1->host_ram;
        $hv1->setAttr(
            name    => 'host_ram',
            value   => 1300 * 1024 * 1024
        );
        $hv1->save();

        # 2 successive migrations
        diag('#Live migrations');
        my @hv2_vms = $hv2->virtual_machines;
        my $vm1_hv2 = $hv2_vms[0];
        my $vm2_hv2 = $hv2_vms[1];
        $vm1_hv2->migrate(hypervisor => $hv1);
        $vm2_hv2->migrate(hypervisor => $hv1);
        Kanopya::Tools::Execution->executeAll();

        # one of the VMs should migrate and another not (we don't know which VM will migrate or not)
        my $ok1 = ($vm1_hv2->reload->hypervisor->id == $hv1->id);# 1st VM has migrated on hv1
        my $ko1 = ($vm1_hv2->reload->hypervisor->id == $hv2->id);# 1st VM has not migrated
        my $ok2 = ($vm2_hv2->reload->hypervisor->id == $hv1->id);# 2nd VM has migrated on hv1
        my $ko2 = ($vm2_hv2->reload->hypervisor->id == $hv2->id);# 2nd VM has not migrated
        if ( not (($ok1 && $ko2) or ($ko1 && $ok2)) ) {# VMs are on the same hypervisor
            if ($ko1 && $ko2) {
                die 'No VM has migrated';
            }
            else {
                die 'All VMs has migrated';
            }
        }

        # hv1 host is returned to it's initial state
        $hv1->setAttr(
            name    => 'host_ram',
            value   => $hv1_initial_ram
        );
        $hv1->save();
    } 'Successive live migrations of 2 VMs with only enough place for one (from Kanopya view)';
}

sub lm_hypervisor_deactivated {
    # now we should have 2 VMs on hv1 and 2 VMs on hv2
    # we want to live migrate a VM (vm1_hv1) on a host deactivated (hv2)
    $hv2->setAttr(
        name    => 'active',
        value   => 0
    );
    $hv2->save();

    # migration
    diag('#Live migration');
    my @hv1_vms = $hv1->virtual_machines;
    my $vm1_hv1 = $hv1_vms[0];
    $vm1_hv1->migrate(hypervisor => $hv2);
    Kanopya::Tools::Execution->executeAll();

    # VM1 should not migrate on hv2 (it should stay on hv1)
    my $vm1_hv1_hyp = $vm1_hv1->reload->hypervisor->id;
    is ($vm1_hv1_hyp, $hv1->id, 'Live migration on an hypervisor deactivated (from Kanopya view)');

    # hv2 is returned to it's initial state
    $hv2->setAttr(
        name    => 'active',
        value   => 1
    );
    $hv2->save();
}

sub lm_vm_down {
    # now we should have 2 VMs on hv1 and 2 VMs on hv2 and hosts are up
    # we want to live migrate a VM down (vm1_hv1) from hv1 to hv2
    my @hv1_vms = $hv1->virtual_machines;
    my $vm1_hv1 = $hv1_vms[0];
    my $evm1_hv1 = EFactory::newEEntity(data => $vm1_hv1);

    # shutdown VM
    my $openNebulaIaas = $hv1->vmm->iaas;
    my $eopenNebulaIaas = EFactory::newEEntity(data => $openNebulaIaas);
    diag('#Shutdown VM');
    my $cmd1 = $eopenNebulaIaas->one_command('onevm shutdown '. $vm1_hv1->onevm_id);
    $eopenNebulaIaas->getEContext->execute(command => $cmd1);
    sleep(30);
    diag('## VM shut down');

    # migration
    diag('#Live migration');
    $vm1_hv1->migrate(hypervisor => $hv2);
    Kanopya::Tools::Execution->executeAll();

    # VM1 should not migrate on hv2 (it should stay on hv1)
    my $vm1_hv1_hyp = $vm1_hv1->reload->hypervisor->id;
    is ($vm1_hv1_hyp, $hv1->id, 'Live migration of a VM down (shut down)');
}

sub lm_hypervisor_down {
    # now we should have 2 VMs on hv1 and 2 VMs on hv2
    # we want to live migrate a VM (vm1_hv1) on a host down (hv2)
    my $ehv2 = EFactory::newEEntity(data => $hv2);
    eval {
        $ehv2->getContext->execute(command => 'ifdown eth0 ; ifdown eth1');
    };

    # migration
    diag('#Live migration');
    my @hv1_vms = $hv1->virtual_machines;
    my $vm2_hv1 = $hv1_vms[1];
    $vm2_hv1->migrate(hypervisor => $hv2);
    Kanopya::Tools::Execution->executeAll();

    # VM2 should not migrate on hv2 (it should stay on hv1)
    my $vm2_hv1_hyp = $vm2_hv1->reload->hypervisor->id;
    is ($vm2_hv1_hyp, $hv1->id, 'Live migration on an hypervisor down (not responding)');
}

# to remove operations and locks before a test (for eg if a previous test was stopped with CTRL+C)
sub _remove_operations_and_locks {
    my @locks = EntityLock->search(hash => {});
    while (@locks) {
        (pop @locks)->delete();
    }

    my @ops = Entity::Operation->search(hash => {});
    while (@ops) {
        (pop @ops)->delete();
    }
}