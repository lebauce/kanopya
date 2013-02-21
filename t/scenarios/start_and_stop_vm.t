#!/usr/bin/perl -w

=head1 SCOPE

TODO

=head1 PRE-REQUISITE

These test needs
1 opennebula
1 hypervisor up
1 host free with etherwake
vm cluster down
each hypervisor can contains 2 vms but not 3 vms

=cut

use strict;
use warnings;
use Test::More 'no_plan';
use Test::Exception;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({
    level=>'DEBUG',
    file=>'start_and_stop_vm.log',
    layout=>'%F %L %p %m%n'
});

use BaseDB;
use Entity;
use Entity::Component::Virtualization::Opennebula3;
use Entity::Workflow;
use Entity::WorkflowDef;
use Kanopya::Config;

use Kanopya::Tools::Execution;

my $testing = 0;

my ($hv1, $hv2);
my ($vm1, $vm2, $vm3, $vm4);
my $one;
my $hv_cluster;
my $vm_cluster;

main();

sub main {
    BaseDB->authenticate( login =>'admin', password => 'K4n0pY4' );

    if($testing == 1) {
        BaseDB->beginTransaction;
    }

    #get orchestrator configuration

    _check_init();
    start_vm_cluster();
    add_1_vm_in_first_hv();
    add_3_rd_vm_will_deploy_2_nd_hv();
    add_4_th_vm_will_deploy_2_nd_hv();
    add_5_th_vm_refused();
    stop_2_vms();
    stop_2nd_hv_with_hv();
    stop_vm_cluster();
#    stop_2nd_hv();

    if ($testing == 1) {
        BaseDB->rollbackTransaction;
    }
}

sub start_vm_cluster {
    lives_ok {
        $vm_cluster->start();
        Kanopya::Tools::Execution->executeAll();

        my @vms = $hv1->virtual_machines;
        my $num_vms = scalar @vms;

        if ($num_vms != 1) {
            die "Error 1 vm expected, got $num_vms";
        }

        my $vm = pop @vms;

        _check_good_hypervisor(vm => $vm, hypervisor => $hv1);

    } 'Start vm cluster ';
}

sub add_1_vm_in_first_hv {
    lives_ok {
        $vm_cluster->addNode;
        Kanopya::Tools::Execution->executeAll();

        my @vms = $hv1->virtual_machines;
        my $num_vms = scalar @vms;

        if ($num_vms != 2) {
            die "Error 2 vm expected, got $num_vms";
        }

        _check_good_hypervisor(vm => (pop @vms), hypervisor => $hv1);
        _check_good_hypervisor(vm => (pop @vms), hypervisor => $hv1);

    } 'Add one vm to vm cluster on the first hypervisor';
}

sub add_3_rd_vm_will_deploy_2_nd_hv {
    lives_ok {
        my @hv1_vms = $hv1->virtual_machines;
        $vm_cluster->addNode;
        Kanopya::Tools::Execution->executeAll();
        _check_good_hypervisor(vm => (pop @hv1_vms), hypervisor => $hv1);
        _check_good_hypervisor(vm => (pop @hv1_vms), hypervisor => $hv1);

        my @hvs = $one->hypervisors;
        if (scalar @hvs != 2) {
            die "Hypervisor 2 did not boot";
        }
        my $hv = pop @hvs;

        if ($hv->id == $hv1->id) {
            $hv2 = pop@hvs;
        }
        else {
            $hv2 = $hv;
        }

        my @hv2_vms = $hv2->virtual_machines;
        if (scalar @hv2_vms != 1) {
            die "Error 1 vm expected, on hv2, got ".(scalar @hv2_vms);
        }
    } 'Add one vm to vm cluster, starts automatically a seconde hypervisor';
}

sub add_4_th_vm_will_deploy_2_nd_hv {
    lives_ok {
        $vm_cluster->addNode;
        Kanopya::Tools::Execution->executeAll();

        my @hv1_vms = $hv1->virtual_machines;
        my @hv2_vms = $hv2->virtual_machines;

        if ((scalar @hv1_vms) != 2) {
            die "Error 2 vm expected, on hv1, got".(scalar @hv1_vms);
        }

        if ((scalar @hv2_vms) != 2) {
            die "Error 1 vm expected, on hv2, got".(scalar @hv2_vms);
        }
     } 'Add one vm to vm cluster, deploy on the second hypervisor';
}

sub add_5_th_vm_refused {
    lives_ok {
        $vm_cluster->addNode;
        Kanopya::Tools::Execution->executeAll();


        my @hv1_vms = $hv1->virtual_machines;
        my @hv2_vms = $hv2->virtual_machines;

        if (scalar @hv1_vms != 2) {
            die "Error 2 vm expected, on hv1, got".(scalar @hv1_vms);
        }

        if (scalar @hv2_vms != 2) {
            die "Error 2 vm expected, on hv2, got".(scalar @hv2_vms);
        }

        #TODO Check operation failure

    } 'Add one vm to vm cluster, hypervisor cluster is full, no free host, no vm';
}

sub stop_2_vms {
    lives_ok {
        my @hv1_vms = $hv1->virtual_machines;
        my @hv2_vms = $hv2->virtual_machines;

        (pop @hv1_vms)->node->remove;
        (pop @hv2_vms)->node->remove;

        Kanopya::Tools::Execution->executeAll();

        @hv1_vms = $hv1->reload->virtual_machines;
        @hv2_vms = $hv2->reload->virtual_machines;

        if (scalar @hv1_vms != 1) {
            die "Error 1 vm expected, on hv1, got ".(scalar @hv1_vms);
        }

        if (scalar @hv2_vms != 1) {
            die "Error 1 vm expected, on hv2, got ".(scalar @hv2_vms);
        }
    } 'Stop one vm on each hypervisor';
}

sub stop_2nd_hv_with_hv {
    lives_ok {
        $hv2->node->remove();

        Kanopya::Tools::Execution->executeAll();

        my @hvs = $one->hypervisors;

        if (scalar @hvs != 1) {
            die "Hypervisor 2 has not been removed";
        }

        my @hv1_vms = $hv1->virtual_machines;

        if (scalar @hv1_vms != 2) {
            die "Error 2 vm expected, on hv1, got".(scalar @hv1_vms);
        }
    } 'Stop second hypervisor, migrates the vm on the first one';
}

sub stop_vm_cluster {
    lives_ok {
        $vm_cluster->stop;
        Kanopya::Tools::Execution->executeAll();

        my @hv1_vms = $hv1->virtual_machines;

        if (scalar @hv1_vms != 0) {
            die "Error 0 vm expected, on hv1, got".(scalar @hv1_vms);
        }
    } 'Stop vm cluster no more vms';
}

sub _check_init {
    $one = Entity::Component::Virtualization::Opennebula3->find(hash => {});

    my @hvs = $one->hypervisors;
    my $hv_num = scalar @hvs;

    if ($hv_num != 1) {
        throw Kanopya::Exception(error => "You need exactly 1 hypervisor for this test,
                                           you have $hv_num hypervisor in the IAAS");
    }

    $hv1 = (pop @hvs);

    $hv_cluster = $hv1->node->inside;

    my $hv_ecluster = EFactory::newEEntity(data => $hv_cluster);
    my $host = $hv_ecluster->addNode;
    my @spms = $one->service_provider_managers;

    $vm_cluster = $spms[0]->service_provider;

}

sub _check_good_hypervisor {
    my %args = @_;
    my $vm = $args{vm};
    my $hv = $args{hypervisor};

    if (!($vm->reload->hypervisor->id == $hv->id)) {
        throw Kanopya::Exception(error => 'vm not on its hypervisor');
    }
    diag('# vm on its hypervisor');
};

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
