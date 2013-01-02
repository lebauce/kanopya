#!/usr/bin/perl -w

=head1 SCOPE

Scale in cpu and memory of virtual machines

=head1 PRE-REQUISITE

These test needs 4 vms and 2 hosts
2 hypervisors have 3 GB RAM in Kanopya database and 8 cores
4 vms have 512 MB RAM and can be scaled up to 2 GB
4 vms have 1 core in Kanopya database and can be scaled to 4 cores
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

use Administrator;
use Entity;
use Entity::Component::Opennebula3;
use Entity::Workflow;
use Entity::WorkflowDef;
use Kanopya::Config;

use Kanopya::Tools::Execution;

my $testing = 0;

my ($hv1, $hv2);
my ($vm1, $vm2, $vm3, $vm4);
my $one;
my $coefGb2Bytes = 1024**3;

main();

sub main {
    Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
    my $adm = Administrator->new;

    if($testing == 1) {
        $adm->beginTransaction;
    }

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

    if ($testing == 1) {
        $adm->rollbackTransaction;
    }
}

sub scale_memory_place_ok {
    # 2 vms are memory scaled (vm1 & vm2 : 512 Mb is added on each)
    # there is just enough space on their hypervisor (hv1 : 1 Gb free) to accept the scale
    # (4*512 + 512 + 512 <= 3*1024 Mb)
    lives_ok {
        $vm1->scale(
            scalein_type  => 'memory',
            scalein_value => 1*$coefGb2Bytes,
        );
        Kanopya::Tools::Execution->executeAll();

        _check_vm_ram(vm => $vm1, ram => 1*$coefGb2Bytes);
        _check_good_hypervisor(
            vm => $vm1,
            hypervisor => $hv1,
        );

        $vm2->scale(
            scalein_type  => 'memory',
            scalein_value => 1*$coefGb2Bytes,
        );
        Kanopya::Tools::Execution->executeAll();

        _check_vm_ram(vm => $vm2, ram => 1*$coefGb2Bytes);
        _check_good_hypervisor(
            vm => $vm2,
            hypervisor => $hv1,
        );
    } 'Scales memory in same hypervisor';
}

sub scale_memory_need_to_migrate {
    # 1 vm is memory scaled (vm3 : 0.5 -> 2Gb)
    # there is no space on its hypervisor (hv1 : 0 Gb free)
    # but there is enough space for this VM on the 2nd hypervisor (hv2 : 3 Gb free)
    lives_ok {
        $vm3->scale(
            scalein_type  => 'memory',
            scalein_value => 2*$coefGb2Bytes,
        );
        Kanopya::Tools::Execution->executeAll();

        _check_vm_ram(vm => $vm3, ram => 2*$coefGb2Bytes);
        _check_good_hypervisor(
            vm => $vm3,
            hypervisor => $hv2,
        );
    } 'Scales memory which need to migrate the vm';
}

sub scale_memory_need_to_migrate_other {
    # 2 vms are memory scaled (vm1 : 1 -> 1.5Gb & vm4 : 0.5 -> 1.5Gb )
    # there is not enough space for all VMs on their hypervisor (hv1 : 0.5 Gb free)
    # but there is just enough space for 1 of them (vm2 : 1Gb) on the 2nd hypervisor (hv2 : 1 Gb free)
    lives_ok {
        $vm1->scale(
            scalein_type  => 'memory',
            scalein_value => 1.5*$coefGb2Bytes,
        );
        Kanopya::Tools::Execution->executeAll();

        _check_vm_ram(vm => $vm1, ram => 1.5*$coefGb2Bytes);
        _check_good_hypervisor(
            vm => $vm1,
            hypervisor => $hv1,
        );

        $vm4->scale(
            scalein_type  => 'memory',
            scalein_value => 1.5*$coefGb2Bytes,
        );
        Kanopya::Tools::Execution->executeAll();

        _check_vm_ram(vm => $vm4, ram => 1.5*$coefGb2Bytes);
        _check_good_hypervisor(
            vm => $vm4,
            hypervisor => $hv1,
        );

        # vm2 must migrate
        _check_good_hypervisor(
            vm => $vm2,
            hypervisor => $hv2,
        );
    } 'Scales memory which need to migrate another vm';
}

sub scale_memory_no_place {
    # 1 vm is memory scaled (vm3 : 2 -> 2.5Gb)
    # there is no space, on all hypervisors of the IaaS, to accept the scale
    lives_ok {
        $vm3->scale(
            scalein_type  => 'memory',
            scalein_value => 2.5*$coefGb2Bytes,
        );
        Kanopya::Tools::Execution->executeAll();
        _check_vm_ram(vm => $vm3, ram => 2*$coefGb2Bytes);
        _check_good_hypervisor(
            vm => $vm3,
            hypervisor => $hv2,
        );
    } 'Scales memory fail (no place)';
}

sub scale_cpu_place_ok {
    # 2 vms are cpu scaled (vm1 & vm2 : 2 cores are added on each)
    # there is just enough space on their hypervisor (hv1 : 4 cores free) to accept the scale
    # (4*1 + 2 + 2 <= 8 cores)
    lives_ok {
        $vm1->scale(
            scalein_type  => 'cpu',
            scalein_value => 3,
        );
        Kanopya::Tools::Execution->executeAll();

        _check_vm_core(vm => $vm1, core => 3);
        _check_good_hypervisor(
            vm => $vm1,
            hypervisor => $hv1,
        );

        $vm2->scale(
            scalein_type  => 'cpu',
            scalein_value => 2,
        );
        Kanopya::Tools::Execution->executeAll();

        _check_vm_core(vm => $vm2, core => 3);
        _check_good_hypervisor(
            vm => $vm2,
            hypervisor => $hv1,
        );
    } 'Scales cpu in same hypervisor';
}

sub scale_cpu_need_to_migrate {
    # 1 vm is cpu scaled (vm3 : 1 -> 5 cores)
    # there is no space on its hypervisor (hv1 : 0 core free)
    # but there is enough space for this VM on the 2nd hypervisor (hv2 : 8 cores free)
    lives_ok {
        $vm3->scale(
            scalein_type  => 'cpu',
            scalein_value => 5,
        );
        Kanopya::Tools::Execution->executeAll();

        _check_vm_core(vm => $vm3, core => 5);
        _check_good_hypervisor(
            vm => $vm3,
            hypervisor => $hv2,
        );
    } 'Scales cpu which need to migrate the vm';
}

sub scale_cpu_need_to_migrate_other {
    # 2 vms are cpu scaled (vm1 : 3 -> 4 cores & vm4 : 1 -> 4 cores)
    # there is not enough space for all VMs on their hypervisor (hv1 : 1 core free)
    # but there is just enough space for 1 of them (vm2 : 3 cores) on the 2nd hypervisor (hv2 : 3 cores free)
    lives_ok {
        $vm1->scale(
            scalein_type  => 'cpu',
            scalein_value => 4,
        );
        Kanopya::Tools::Execution->executeAll();

        _check_vm_core(vm => $vm1, core => 4);
        _check_good_hypervisor(
            vm => $vm1,
            hypervisor => $hv1,
        );

        $vm4->scale(
            scalein_type  => 'cpu',
            scalein_value => 4,
        );
        Kanopya::Tools::Execution->executeAll();

        _check_vm_core(vm => $vm4, core => 4);
        _check_good_hypervisor(
            vm => $vm4,
            hypervisor => $hv1,
        );

        _check_good_hypervisor(
            vm => $vm2,
            hypervisor => $hv2,
        );
    } 'Scales cpu which need to migrate another vm';
}

sub scale_cpu_no_place {
    # 1 vm is cpu scaled (vm3 : 5 -> 6 cores)
    # there is no space, on all hypervisors of the IaaS, to accept the scale
    lives_ok {
        $vm3->scale(
            scalein_type  => 'cpu',
            scalein_value => 6,
        );
        Kanopya::Tools::Execution->executeAll();

        _check_vm_core(vm => $vm3, core => 5);
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

sub _check_vm_core {
    my %args = @_;
    my $vm = $args{vm}->reload;
    my $core = $args{core};

    if (!($vm->host_core == $core)) {
        throw Kanopya::Exception(error => 'vm core value in DB is wrong');
    }

    my $evm = EFactory::newEEntity(data => $vm);

    if (!($evm->getTotalMemory == $core)) {
        throw Kanopya::Exception(error => 'vm real core value is wrong');
    }
    diag('# vm core is ok');
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
            scalein_value => 0.5*$coefGb2Bytes,
        );
        $vm->migrate(hypervisor => $hv1);
    }
    Kanopya::Tools::Execution->executeAll();
}

sub _reinit_infra_cpu {
    for my $vm ($vm1,$vm2,$vm3,$vm4) {
        $vm->scale(
            scalein_type  => 'cpu',
            scalein_value => 1,
        );
        $vm->migrate(hypervisor => $hv1);
    }
    Kanopya::Tools::Execution->executeAll();
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

        $hv1->setAttr(name => 'host_ram',value => 3*$coefGb2Bytes);
        $hv1->save();
        $hv2->setAttr(name => 'host_ram',value => 3*$coefGb2Bytes);
        $hv2->save();

        $hv1->setAttr(name => 'host_core',value => 8);
        $hv1->save();
        $hv2->setAttr(name => 'host_core',value => 8);
        $hv2->save();

        my $hv1_ram  = $hv1->reload->host_ram;
        my $hv1_core = $hv1->reload->host_core;
        my $hv2_ram  = $hv2->reload->host_ram;
        my $hv2_core = $hv2->reload->host_core;

        if (!(($hv1_ram == 3*$coefGb2Bytes) &&
              ($hv2_ram == 3*$coefGb2Bytes) &&
              ($hv1_core == 8)        &&
              ($hv2_core == 8) ) ) {
            throw Kanopya::Exception(error => "Wrong infrastructure : Ram / Cpu not initialized correctly
              ($hv1_ram == ".3*$coefGb2Bytes.") && ($hv2_ram == ".3*$coefGb2Bytes.") && ($hv1_core == 8) && ($hv2_core == 8) ) )
            ");
        }

        my @vms = $hv1->virtual_machines;
        $vm1 = $vms[0];
        $vm2 = $vms[1];
        $vm3 = $vms[2];
        $vm4 = $vms[3];

        _check_vm_ram(vm => $vm1, ram => 0.5*$coefGb2Bytes);
        _check_vm_ram(vm => $vm2, ram => 0.5*$coefGb2Bytes);
        _check_vm_ram(vm => $vm3, ram => 0.5*$coefGb2Bytes);
        _check_vm_ram(vm => $vm4, ram => 0.5*$coefGb2Bytes);

        _check_vm_core(vm => $vm1, core => 1);
        _check_vm_core(vm => $vm2, core => 1);
        _check_vm_core(vm => $vm3, core => 1);
        _check_vm_core(vm => $vm4, core => 1);
}