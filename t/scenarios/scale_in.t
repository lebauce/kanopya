#!/usr/bin/perl -w

=head1 SCOPE

Scale in CPU and memory of virtual machines

=head1 PRE-REQUISITE

These test needs 4 vms and 2 hosts
2 hypervisors have 3 GB RAM in KDb and 8 cores
4 vms have 512 MB RAM and can be scaled up to 2 GB
4 vms have 1 core in KDb and can be scaled to 4 cores
4 vms are on hypervisor 1

=cut

use strict;
use warnings;
use Test::More 'no_plan';
use Test::Exception;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({
    level=>'DEBUG',
    file=>'/vagrant/scale_in.log',
    layout=>'%F %L %p %m%n'
});
my $log = get_logger("");

use Administrator;
use Executor;
use Entity;
use Entity::Component::Opennebula3;
use Entity::Workflow;
use Entity::WorkflowDef;
use Kanopya::Config;
use Kanopya::Tools::Register;
use Kanopya::Tools::Retrieve;

my $testing = 0;

Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
my $adm = Administrator->new;
if($testing == 1) {
    $adm->beginTransaction;
}

my $executor;
my ($hv1, $hv2);
my ($vm1, $vm2, $vm3, $vm4);
my $one;
my $coef = 1024**3;
main();

if($testing == 1) {
    $adm->rollbackTransaction;
}

sub main {
    $executor     = Executor->new();
    #get orchestrator configuration

    _check_init();
    diag('Scale Memory');
    scale_memory_place_ok();
    scale_memory_need_to_migrate();
    scale_memory_need_to_migrate_other();
    scale_memory_no_place();
    _reinit_infra_memory();
    diag('Scale CPU');
    scale_cpu_place_ok();
    scale_cpu_need_to_migrate();
    scale_cpu_need_to_migrate_other();
    scale_cpu_no_place();
    _reinit_infra_cpu();
}

sub scale_memory_place_ok {
    # 2 vms are memory scaled and there is enough space on their hypervisor to accept the scale.
    lives_ok {
        $vm1->scale(
            scalein_type  => 'memory',
            scalein_value => 1*$coef,
        );

        _executor_real_infra();
        _check_vm_ram(vm => $vm1, ram => 1*$coef);
        _check_good_hypervisor(
            vm => $vm1,
            hypervisor => $hv1,
        );

        $vm2->scale(
            scalein_type  => 'memory',
            scalein_value => 1*$coef,
        );

        _executor_real_infra();
        _check_vm_ram(vm => $vm2, ram => 1*$coef);
        _check_good_hypervisor(
            vm => $vm2,
            hypervisor => $hv1,
        );
    } 'Scales memory in same hypervisor';
}

sub scale_memory_need_to_migrate {
    lives_ok {
        $vm3->scale(
            scalein_type  => 'memory',
            scalein_value => 2*$coef,
        );
        _executor_real_infra();
        _check_vm_ram(vm => $vm3, ram => 2*$coef);
        _check_good_hypervisor(
            vm => $vm3,
            hypervisor => $hv2,
        );
    } 'Scales memory which need to migrate the vm';
}

sub scale_memory_need_to_migrate_other {
    lives_ok {
        $vm1->scale(
            scalein_type  => 'memory',
            scalein_value => 1.5*$coef,
        );
        _executor_real_infra();

        _check_vm_ram(vm => $vm1, ram => 1.5*$coef);
        _check_good_hypervisor(
            vm => $vm1,
            hypervisor => $hv1,
        );

        $vm4->scale(
            scalein_type  => 'memory',
            scalein_value => 1.5*$coef,
        );

        _executor_real_infra();

        _check_vm_ram(vm => $vm4, ram => 1.5*$coef);

        _check_good_hypervisor(
            vm => $vm2,
            hypervisor => $hv2,
        );

        _check_good_hypervisor(
            vm => $vm4,
            hypervisor => $hv1,
        );

    } 'Scales memory which need to migrate another vm';
}

sub scale_memory_no_place {
    lives_ok {
        $vm3->scale(
            scalein_type  => 'memory',
            scalein_value => 2.5*$coef,
        );
        _executor_real_infra();
        _check_vm_ram(vm => $vm3, ram => 2*$coef);
        _check_good_hypervisor(
            vm => $vm3,
            hypervisor => $hv2,
        );
    } 'Scales memory fail (no place)';
}

sub scale_cpu_place_ok {
    # 2 vms are cpu scaled and there is enough space on their hypervisor to accept the scale.
    lives_ok {
        $vm1->scale(
            scalein_type  => 'cpu',
            scalein_value => 1*$coef,
        );

        _executor_real_infra();
        _check_vm_cpu(vm => $vm1, cpu => 1*$coef);
        _check_good_hypervisor(
            vm => $vm1,
            hypervisor => $hv1,
        );

        $vm2->scale(
            scalein_type  => 'cpu',
            scalein_value => 1*$coef,
        );

        _executor_real_infra();
        _check_vm_cpu(vm => $vm2, cpu => 1*$coef);
        _check_good_hypervisor(
            vm => $vm2,
            hypervisor => $hv1,
        );
    } 'Scales cpu in same hypervisor';
}

sub scale_cpu_need_to_migrate {
    lives_ok {
        $vm3->scale(
            scalein_type  => 'cpu',
            scalein_value => 2*$coef,
        );
        _executor_real_infra();
        _check_vm_cpu(vm => $vm3, cpu => 2*$coef);
        _check_good_hypervisor(
            vm => $vm3,
            hypervisor => $hv2,
        );
    } 'Scales cpu which need to migrate the vm';
}

sub scale_cpu_need_to_migrate_other {
    lives_ok {
        $vm1->scale(
            scalein_type  => 'cpu',
            scalein_value => 1.5*$coef,
        );
        _executor_real_infra();

        _check_vm_cpu(vm => $vm1, cpu => 1.5*$coef);
        _check_good_hypervisor(
            vm => $vm1,
            hypervisor => $hv1,
        );

        $vm4->scale(
            scalein_type  => 'cpu',
            scalein_value => 1.5*$coef,
        );

        _executor_real_infra();

        _check_vm_cpu(vm => $vm4, cpu => 1.5*$coef);

        _check_good_hypervisor(
            vm => $vm2,
            hypervisor => $hv2,
        );

        _check_good_hypervisor(
            vm => $vm4,
            hypervisor => $hv1,
        );

    } 'Scales cpu which need to migrate another vm';
}

sub scale_cpu_no_place {
    lives_ok {
        $vm3->scale(
            scalein_type  => 'cpu',
            scalein_value => 2.5*$coef,
        );
        _executor_real_infra();
        _check_vm_cpu(vm => $vm3, cpu => 2*$coef);
        _check_good_hypervisor(
            vm => $vm3,
            hypervisor => $hv2,
        );
    } 'Scales cpu fail (no place)';
}

sub _check_vm_ram {
    my %args = @_;
    my $vm = $args{vm}->reload;
    my $ram = $args{ram};

    if (!($vm->host_ram == $ram)) {
        throw Kanopya::Exception(error => 'vm ram value in DB is wrong');
    }

    my $evm = EFactory::newEEntity(data => $vm);

    if (!($evm->getTotalMemory == $ram)) {
        throw Kanopya::Exception(error => 'vm real ram value is wrong');
    }
    diag('# vm ram is ok');
}

sub _check_vm_cpu {
    my %args = @_;
    my $vm = $args{vm}->reload;
    my $cpu = $args{cpu};

    if (!($vm->host_cpu == $cpu)) {
        throw Kanopya::Exception(error => 'vm cpu value in DB is wrong');
    }

    my $evm = EFactory::newEEntity(data => $vm);

    if (!($evm->getTotalMemory == $cpu)) {
        throw Kanopya::Exception(error => 'vm real cpu value is wrong');
    }
    diag('# vm cpu is ok');
}

sub _check_good_hypervisor {
    my %args = @_;
    my $vm = $args{vm};
    my $hv = $args{hypervisor};

    if (!($vm->reload->hypervisor->id == $hv->id)) {
        throw Kanopya::Exception(error => 'vm not on its hypervisor');
    }
    diag('# vm on its hypervisor');
}

sub _reinit_infra_memory {
    for my $vm ($vm1,$vm2,$vm3,$vm4) {
        $vm->scale(
            scalein_type  => 'memory',
            scalein_value => 0.5*$coef,
        );
        $vm->migrate(hypervisor => $hv1);
    }
    _executor_real_infra();
}

sub _reinit_infra_cpu {
    for my $vm ($vm1,$vm2,$vm3,$vm4) {
        $vm->scale(
            scalein_type  => 'cpu',
            scalein_value => 0.5*$coef,
        );
        $vm->migrate(hypervisor => $hv1);
    }
    _executor_real_infra();
}

sub _check_init {
        $one = Entity::Component::Opennebula3->find(hash => {});
        my @hvs = $one->hypervisors;
        if ((scalar $hvs[0]->virtual_machines == 4) && (scalar $hvs[1]->virtual_machines == 0)) {
            ($hv1, $hv2) = ($hvs[0], $hvs[1]);
        } 
        elsif ((scalar $hvs[1]->virtual_machines == 4) && (scalar $hvs[0]->virtual_machines == 0)) {
            ($hv1, $hv2) = ($hvs[1], $hvs[0]);
        }
        else {
            throw Kanopya::Exception(error => 'Wrong infrastructure : 4 Vms not on the same hypervisor');
        }

        $hv1->setAttr(name => 'host_ram',value => 3*$coef);
        $hv1->save();
        $hv2->setAttr(name => 'host_ram',value => 3*$coef);
        $hv2->save();

        my $hv1_ram  = $hv1->reload->host_ram;
        my $hv1_core = $hv1->reload->host_core;
        my $hv2_ram  = $hv2->reload->host_ram;
        my $hv2_core = $hv2->reload->host_core;

        if (!(($hv1_ram == 3*$coef) &&
              ($hv2_ram == 3*$coef) &&
              ($hv1_core == 8)        &&
              ($hv2_core == 8) ) ) {
            throw Kanopya::Exception(error => "Wrong infrastructure : Ram / Cpu not initialized correctly
              ($hv1_ram == ".3*$coef.") && ($hv2_ram == ".3*$coef.") && ($hv1_core == 8) && ($hv2_core == 8) ) )
            ");
        }

        my @vms = $hv1->virtual_machines;
        $vm1 = $vms[0];
        $vm2 = $vms[1];
        $vm3 = $vms[2];
        $vm4 = $vms[3];
        _check_vm_ram(vm => $vm1, ram => 0.5*$coef);
        _check_vm_ram(vm => $vm2, ram => 0.5*$coef);
        _check_vm_ram(vm => $vm3, ram => 0.5*$coef);
        _check_vm_ram(vm => $vm4, ram => 0.5*$coef);
}

sub _executor_real_infra {
    my %args = @_;

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
            $log->info("sleep 5 ($timeout)");
        }
    }

    if ($timeout <= 0) {
        throw Kanopya::Exception(error => 'Execution timed out');
    }
}