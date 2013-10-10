#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Data::Dumper;
use JSON;
use File::Temp;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'capacity_management.log', layout=>'%F %L %p %m%n'});
my $log = get_logger("");

my $testing = 0;

use BaseDB;
use Entity::Component;
use Entity::ServiceProvider::Externalcluster;
use CapacityManagement;
use ChocoCapacityManagement;
use Entity::Component::Virtualization::Opennebula3;
use ClassType::ComponentType;

BaseDB->authenticate( login =>'admin', password => 'K4n0pY4' );

BaseDB->beginTransaction;

my @vms;
my @hvs;
my $coef = 1024**3;
my $service_provider;
my $service_provider_hypervisors;
my $one;
my %vm_index;
my %hv_index;
my $cm_class;

main();

sub main {

    if ($testing == 1) {
        BaseDB->beginTransaction;
    }

    $service_provider = Entity::ServiceProvider->new();

    $service_provider_hypervisors = Entity::ServiceProvider->new();

    $one = $service_provider_hypervisors->addComponent(
        component_type_id => ClassType::ComponentType->find(
            hash => {
                component_name => 'Opennebula',
            }
        )->id,
    );

    # Create entity with random arguments because only used for their ids
    @vms = ();
    for my $i (1..10) {
        my $e = Entity::Host->new(
                    host_core          => 1,
                    host_ram           => 1,
                    host_manager_id    => Entity::Component->find(hash => {})->id,
                    host_serial_number => 'sn',
                );
        push @vms, $e;
        $vm_index{$e->id} = $i;
    }

    $service_provider->addManager(
        manager_id   => $one->id,
        manager_type => 'HostManager',
    );


    $cm_class = 'CapacityManagement';
    diag($cm_class);

    test_hypervisor_selection_multi();
    test_hypervisor_selection();
    test_migration_authorization();
    test_scale_memory();
    test_scale_cpu();
    test_optimiaas();
    test_flushhypervisor();
    test_resubmit();
    test_flushhypervisor_need_csp();
    test_scale_in_need_csp();

    $cm_class = 'ChocoCapacityManagement';
    diag($cm_class);

    test_hypervisor_selection_multi();
    test_hypervisor_selection();
    test_migration_authorization();
    test_scale_memory();
    test_scale_cpu();
#    test_optimiaas();
    test_flushhypervisor();
    test_resubmit();
    test_flushhypervisor_need_csp();
    test_scale_in_need_csp();

    if ($testing == 1) {
        BaseDB->rollbackTransaction;
    }
}

sub test_flushhypervisor_need_csp {
    lives_ok {
        my $infra = _getTestInfraForFlushNeedCSP();
        my $cm = $cm_class->new(infra => $infra);
        my $result = $cm->flushHypervisor(hv_id => 3);

        # Flush fails for KanopyaCM but successes with ChocoCM
        if ( $cm_class eq 'CapacityManagement' && ! ($result->{num_failed} == 1)) {
            die "CapacityManagement had to fail flushing ($cm_class, ".$result->{num_failed}.")";
        }

        if ( $cm_class eq 'ChocoCapacityManagement' && ! ($result->{num_failed} == 0)) {
            die "ChocoCapacityManagement had to success flushing ($cm_class, ".$result->{num_failed}.")";
        }

    } 'Flush Hypervisor need CSP';
}

sub test_scale_in_need_csp {
    lives_ok {
        my $infra = _getTestInfraForScaleInNeedCSP();
        my $cm = $cm_class->new(infra => $infra);

        my $operations = $cm->scaleMemoryHost(host_id => $vms[2]->id, memory => 10*$coef);

        my $waited_operations = {
            CapacityManagement      => ['AddNode', 'PreStartNode', 'StartNode', 'PostStartNode', 'MigrateHost', 'ScaleMemoryHost'],
            ChocoCapacityManagement => ['MigrateHost', 'MigrateHost', 'ScaleMemoryHost'],
        };

        if ((scalar @$operations) != (scalar @{$waited_operations->{$cm_class}})) {
            die "Wrong number of operations";
        }

        for my $i (0..(scalar @$operations)-1) {
            if ($operations->[$i]->{type} ne $waited_operations->{$cm_class}->[$i]) {
                die "Wrong operation sequentiality <".$operations->[$i]->{type}."> vs <".$waited_operations->{$cm_class}->[$i].">";
            }
        }

    } 'Scale memory Hypervisor need CSP';
}

sub test_flushhypervisor {

    lives_ok {

        my $infra = _getTestInfraForFlush();
        my $cm    = $cm_class->new(infra => $infra);

        my $res = $cm->flushHypervisor(hv_id => 4);

        if ( not ( $res->{num_failed} == 4 &&
            scalar @{$res->{operation_plan}} == 0)) {
            die 'Error in flush hypervisor - case: no vm can migrate';
        }

        if (! defined $cm->{_infra}->{vms}->{$vms[9]->id}) {
            die 'Error vm should be indexed in vms list'
        }
        if (! defined  $cm->{_infra}->{hvs}->{1}->{vm_ids}->{$vms[9]->id}) {
            die 'Error vm should be indexed in hv vms list'
        }

        # Remove vm 9 (5GB RAM)
        $cm->_removeVmfromInfra(vm_id => $vms[9]->id);
        if (exists $cm->{_infra}->{vms}->{$vms[9]->id}) {
            die 'Error vm still indexed in vms list'
        }
        if (exists $cm->{_infra}->{hvs}->{1}->{vm_ids}->{$vms[9]->id}) {
            die 'Error vm still indexed in hv vms list'
        }

        my $flush_res = $cm->flushHypervisor(hv_id => 4);

        if ($flush_res->{num_failed} != 2) {die 'Error flush hypervisor - Num failed expected 2, got '.$flush_res->{num_failed};}

        my %possible_migrations = (7 => 1, 8 => 1, 5 => 1, 3 => 1);

        for my $operation (@{$flush_res->{operation_plan}}) {
            if (not ( $operation->{type} eq 'MigrateHost'
                && $operation->{params}->{context}->{host}->id == $possible_migrations{$vm_index{$operation->{params}->{context}->{vm}->id}})) {
                die 'Error in flush hypervisor vm '.($vm_index{$operation->{params}->{context}->{vm}->id})
            }
        }

        # Remove 1 vm in hv 1 and one vm in hv 6
        my @keys = keys %{$cm->{_infra}->{hvs}->{1}->{vm_ids}};
        $cm->_removeVmfromInfra(vm_id => pop @keys);

        @keys = keys %{$cm->{_infra}->{hvs}->{6}->{vm_ids}};
        $cm->_removeVmfromInfra(vm_id => pop @keys);

        my @hv_4_vms = keys %{$cm->{_infra}->{hvs}->{4}->{vm_ids}};

        $flush_res = $cm->flushHypervisor(hv_id => 4);

        if ($flush_res->{num_failed} != 0) {die 'Error flush hypervisor - Num failed expected 0, got '.$flush_res->{num_failed};}

        # Check that vm of hv 4 have been plan to be migrated to hv 0 or hv 1
        for my $operation (@{$flush_res->{operation_plan}}) {
            if (not (
                $operation->{type} eq 'MigrateHost'
                && ($operation->{params}->{context}->{host}->id == 1
                    || $operation->{params}->{context}->{host}->id == 6)
                && ($operation->{params}->{context}->{vm}->id == $hv_4_vms[0]
                    || $operation->{params}->{context}->{vm}->id == $hv_4_vms[1])
            )) {
                die 'Error in flush hypervisor vm '.
                    ($vm_index{$operation->{params}->{context}->{vm}->id}).
                    ' on hypervisor '.
                    $operation->{params}->{context}->{host}->id;
            }
        }
    } 'Flush hypervisor';

}
sub test_resubmit {
    lives_ok {
        my $infra = {
            vms => {
                $vms[0]->id => {resources => {cpu => 8, ram => 8*1024*1024*1024}, hv_id => 1},
                $vms[1]->id => {resources => {cpu => 2, ram => 2*1024*1024*1024}, hv_id => 1},
                $vms[2]->id => {resources => {cpu => 1, ram => 1*1024*1024*1024}, hv_id => 2},
            },
            hvs => { 1 => {resources => {cpu => 10,ram => 10*1024*1024*1024}},
                     2 => {resources => {cpu => 10,ram => 10*1024*1024*1024}},
            }
        };

        while (my ($vm_id, $vm) = each(%{$infra->{vms}})) {
            $infra->{hvs}->{$vm->{hv_id}}->{vm_ids}->{$vm_id} = 1;
        }

        my $cm = $cm_class->new(infra => $infra);

        my $hv_resubmit_id = $cm->getHypervisorIdResubmitVM(
                                 vm_id         => $vms[0]->id,
                                 wanted_values => { ram => 8*$coef, cpu => 8 }
                             );

        if ($hv_resubmit_id != 1) {
            die 'Error in resubmition in the same HV (get <'.$hv_resubmit_id.'> instead of 1)';
        }

        $hv_resubmit_id = $cm->getHypervisorIdResubmitVM(
                              vm_id         => $vms[0]->id,
                              wanted_values => { ram => 9*$coef, cpu => 8 }
                          );

        if ($hv_resubmit_id != 2) {
            die 'Error in resubmition in the same HV (get <'.$hv_resubmit_id.'> instead of 2)';
        }


       # Second part Using directly resubmitVm() method

        $infra = _getTestInfraForResubmit();
        $cm = $cm_class->new(infra => $infra);
        my $placement = $cm->resubmitHypervisor(hv_id => 1);

        if ($placement->{$vms[0]->id} != 2) {
            print Dumper $placement;
            die 'Error in resubmition through method resubmitVm() (get <'.$placement->{$vms[0]->id}.'> instead of 2)';
        }
        if ($placement->{$vms[1]->id} != 3) {
            die 'Error in resubmition through method resubmitVm() (get <'.$placement->{$vms[1]->id}.'> instead of 3)';
        }

        $infra = _getTestInfraForResubmit();
        $cm = $cm_class->new(infra => $infra);
        $placement = $cm->resubmitHypervisor(hv_id => 2);

        if ($placement->{$vms[3]->id} != 1) {
            die 'Error in resubmition through method resubmitVm() (get <'.$placement->{$vms[3]->id}.'> instead of 1)';
        }
        if ($placement->{$vms[2]->id} != 3) {
            die 'Error in resubmition through method resubmitVm() (get <'.$placement->{$vms[2]->id}.'> instead of 3)';
        }

        $infra = _getTestInfraForResubmit();
        $cm = $cm_class->new(infra => $infra);

        $placement = $cm->resubmitHypervisor(hv_id => 3);

        if (defined $placement->{$vms[4]->id}) {
            die 'Error in resubmition through method resubmitVm() (get <'.$placement->{$vms[4]->id}.'> instead of no placement)';
        }

    } 'Hypervisor selection for vm resubmition' ;


}

sub test_migration_authorization {
    lives_ok {
        my $cm = $cm_class->new(infra => getTestInfraForScaling());

        if ( not (
             $cm->isMigrationAuthorized(vm_id => $vms[2]->id, hv_id => 1)->{authorization} == 0
             && $cm->isMigrationAuthorized(vm_id => $vms[1]->id, hv_id => 2)->{authorization} == 1)) {
                 die 'Check Migration authorization';
        }
    } 'Migration authorized' ;
}

sub test_hypervisor_selection_multi {
    lives_ok {
        my $infra = getTestInfraForScaling();

        my $vms_wanted_values = {
            2101 => { cpu => 1, ram => 7*$coef },
            1983 => { cpu => 1, ram => 2*$coef },
        };

        my $rep = $cm_class->new(infra => $infra)->getHypervisorIdsForVMs(vms_resources_hash => $vms_wanted_values);

        if ($rep->{2101} != 2) { die 'Error in placement of vm1 (memory)';}
        if ($rep->{1983} != 1) { die 'Error in placement of vm2 (memory)';}

        $vms_wanted_values = {
            2101 => { cpu => 2, ram => 1*$coef },
            1983 => { cpu => 7, ram => 1*$coef },
        };

        $rep = $cm_class->new(infra => getTestInfraForScaling())
                        ->getHypervisorIdsForVMs(vms_resources_hash => $vms_wanted_values);

        if ($rep->{2101} != 1) { die 'Error in placement of vm1 (cpu)';}
        if ($rep->{1983} != 2) { die 'Error in placement of vm2 (cpu)';}

        $vms_wanted_values = {
            2101 => { cpu => 1, ram => 8*$coef }, #-
            1983 => { cpu => 8, ram => 1*$coef }, #-
            2305 => { cpu => 4, ram => 3*$coef }, #2
            1982 => { cpu => 3, ram => 4*$coef }, #2
            2610 => { cpu => 1, ram => 1*$coef }, #1
            1985 => { cpu => 1, ram => 1*$coef }, #1
        };

        $rep = $cm_class->new(infra => getTestInfraForScaling())
                                 ->getHypervisorIdsForVMs(vms_resources_hash => $vms_wanted_values);

        if (defined $rep->{2101}) {die 'Wrong check ram/cpu placement';}
        if (defined $rep->{1983}) {die 'Wrong check ram/cpu placement';}
        if ($rep->{2305} != 2) {die 'Wrong check ram/cpu placement';}
        if ($rep->{1982} != 2) {die 'Wrong check ram/cpu placement';}
        if ($rep->{2610} != 1) {die 'Wrong check ram/cpu placement';}
        if ($rep->{1985} != 1) {die 'Wrong check ram/cpu placement';}
    } 'Selection of hypervisors for multiple vms';
}


sub test_hypervisor_selection {
    my %args = @_;

    lives_ok {

        my $infra = getTestInfraForScaling();
        my $cm = $cm_class->new(infra => $infra);

        my %wanted_values;
        %wanted_values = (cpu => 1, ram => 6*$coef);

        if ($cm->getHypervisorIdForVM(resources => \%wanted_values) != 2) {
            die 'wrong vm placement';
        }

        %wanted_values = (cpu => 1, ram => 1*$coef);

        if ($cm->getHypervisorIdForVM(resources => \%wanted_values) != 1) {
            die 'wrong vm placement';
        }

        %wanted_values = (cpu => 1, ram => 8*$coef);
        if (defined $cm->getHypervisorIdForVM(resources => \%wanted_values)) {
            die 'wrong vm placement';
        }

        %wanted_values = (cpu => 6, ram => 1*$coef);
        if ($cm->getHypervisorIdForVM(resources => \%wanted_values) != 2) {
            die 'wrong vm placement';
        }

        %wanted_values = (cpu => 1, ram => 1*$coef);

        if ($cm->getHypervisorIdForVM(resources => \%wanted_values) != 1) {
            die 'wrong vm placement';
        }

        %wanted_values = (cpu => 8, ram => 1*$coef);
        if (defined $cm->getHypervisorIdForVM(resources => \%wanted_values)) {
            die 'wrong vm placement';
        }
    } 'Hypervisor selection for a Vm';
}


sub _getTestInfraForResubmit {
    my $infra = {
        vms => {
            $vms[0]->id => {resources => {cpu => 1, ram => 2.5*$coef}, hv_id => 1},
            $vms[1]->id => {resources => {cpu => 1, ram => 1*$coef}, hv_id => 1},
            $vms[2]->id => {resources => {cpu => 1, ram => 1*$coef}, hv_id => 2},
            $vms[3]->id => {resources => {cpu => 3, ram => 1*$coef}, hv_id => 2},
            $vms[4]->id => {resources => {cpu => 4, ram => 4*$coef}, hv_id => 3},
        },

        hvs => {
            1 => {resources => {cpu => 5,ram => 5*$coef}},
            2 => {resources => {cpu => 5,ram => 5*$coef}},
            3 => {resources => {cpu => 5,ram => 5*$coef}},
        },
   };
    while (my ($vm_id, $vm) = each(%{$infra->{vms}})) {
        $infra->{hvs}->{$vm->{hv_id}}->{vm_ids}->{$vm_id} = 1;
    }
    return  $infra;
};

sub _getTestInfraForFlushNeedCSP {
    my $infra = {
        vms => {
            $vms[0]->id => {resources => {cpu => 1, ram => 5*$coef}, hv_id => 3},
            $vms[1]->id => {resources => {cpu => 1, ram => 4*$coef}, hv_id => 3},
            $vms[2]->id => {resources => {cpu => 1, ram => 3*$coef}, hv_id => 3},
            $vms[3]->id => {resources => {cpu => 1, ram => 2*$coef}, hv_id => 3},
            $vms[4]->id => {resources => {cpu => 1, ram => 2*$coef}, hv_id => 3},
            $vms[5]->id => {resources => {cpu => 1, ram => 2*$coef}, hv_id => 3},
            $vms[6]->id => {resources => {cpu => 1, ram => 2*$coef}, hv_id => 3},
        },

        hvs => {
            1 => {resources => {cpu => 10,ram => 10*$coef}},
            2 => {resources => {cpu => 10,ram => 10*$coef}},
            3 => {resources => {cpu => 20,ram => 20*$coef}},
        },
   };
    while (my ($vm_id, $vm) = each(%{$infra->{vms}})) {
        $infra->{hvs}->{$vm->{hv_id}}->{vm_ids}->{$vm_id} = 1;
    }
    return  $infra;
};

sub _getTestInfraForScaleInNeedCSP {
    my $infra = {
        vms => {
            $vms[0]->id => {resources => {cpu => 1, ram => 8*$coef}, hv_id => 1},
            $vms[2]->id => {resources => {cpu => 1, ram => 6*$coef}, hv_id => 2},
            $vms[1]->id => {resources => {cpu => 1, ram => 4*$coef}, hv_id => 2},
            $vms[3]->id => {resources => {cpu => 1, ram => 2*$coef}, hv_id => 2},
            $vms[4]->id => {resources => {cpu => 1, ram => 3*$coef}, hv_id => 2},
            $vms[5]->id => {resources => {cpu => 1, ram => 3*$coef}, hv_id => 2},
            $vms[6]->id => {resources => {cpu => 1, ram => 1*$coef}, hv_id => 2},
            $vms[7]->id => {resources => {cpu => 1, ram => 1*$coef}, hv_id => 2},
            $vms[8]->id => {resources => {cpu => 1, ram => 7*$coef}, hv_id => 3},
        },

        hvs => {
            1 => {resources => {cpu => 10,ram => 10*$coef}},
            2 => {resources => {cpu => 10,ram => 20*$coef}},
            3 => {resources => {cpu => 10,ram => 10*$coef}},
        },
   };
    while (my ($vm_id, $vm) = each(%{$infra->{vms}})) {
        $infra->{hvs}->{$vm->{hv_id}}->{vm_ids}->{$vm_id} = 1;
    }
    return  $infra;
}


sub _getTestInfraForScaleInNeedCSP2 {
    my $infra = {
        vms => {
            $vms[0]->id => {resources => {cpu => 1, ram => 8*$coef}, hv_id => 1},
            $vms[1]->id => {resources => {cpu => 1, ram => 2*$coef}, hv_id => 2},
            $vms[2]->id => {resources => {cpu => 1, ram => 6*$coef}, hv_id => 2},
            $vms[3]->id => {resources => {cpu => 1, ram => 2*$coef}, hv_id => 2},
            $vms[4]->id => {resources => {cpu => 1, ram => 8*$coef}, hv_id => 3},
        },

        hvs => {
            1 => {resources => {cpu => 10,ram => 10*$coef}},
            2 => {resources => {cpu => 10,ram => 10*$coef}},
            3 => {resources => {cpu => 10,ram => 10*$coef}},
        },
   };
    while (my ($vm_id, $vm) = each(%{$infra->{vms}})) {
        $infra->{hvs}->{$vm->{hv_id}}->{vm_ids}->{$vm_id} = 1;
    }
    return  $infra;
}

sub _getTestInfraForFlush {
    my $infra = {
        vms => {
            $vms[0]->id => {resources => {cpu => 1, ram => 3*$coef}, hv_id => 6},
            $vms[1]->id => {resources => {cpu => 1, ram => 2*$coef}, hv_id => 1},
            $vms[2]->id => {resources => {cpu => 1, ram => 2*$coef}, hv_id => 4},
            $vms[3]->id => {resources => {cpu => 1, ram => 2*$coef}, hv_id => 1},
            $vms[4]->id => {resources => {cpu => 1, ram => 2*$coef}, hv_id => 4},
            $vms[5]->id => {resources => {cpu => 1, ram => 3*$coef}, hv_id => 6},
            $vms[6]->id => {resources => {cpu => 1, ram => 2*$coef}, hv_id => 4},
            $vms[7]->id => {resources => {cpu => 1, ram => 2*$coef}, hv_id => 4},
            $vms[8]->id => {resources => {cpu => 1, ram => 3*$coef}, hv_id => 6},
            $vms[9]->id => {resources => {cpu => 1, ram => 5*$coef}, hv_id => 1},
        },

        hvs => {
            1 => {resources => {cpu => 10,ram => 9.5*$coef}},
            4 => {resources => {cpu => 10,ram => 9.5*$coef}},
            6 => {resources => {cpu => 10,ram => 9.5*$coef}},
        },
   };
    while (my ($vm_id, $vm) = each(%{$infra->{vms}})) {
        $infra->{hvs}->{$vm->{hv_id}}->{vm_ids}->{$vm_id} = 1;
    }
    return  $infra;
};

sub _getTestInfraForOptimiaas {
    my $infra = {
        vms => {
            $vms[0]->id => {resources => {cpu => 1, ram => 1*$coef}, hv_id => 1},
            $vms[1]->id => {resources => {cpu => 1, ram => 2*$coef}, hv_id => 1},
            $vms[2]->id => {resources => {cpu => 1, ram => 3*$coef}, hv_id => 2},
            $vms[3]->id => {resources => {cpu => 1, ram => 4*$coef}, hv_id => 3},
            $vms[4]->id => {resources => {cpu => 1, ram => 5*$coef}, hv_id => 4},
            $vms[5]->id => {resources => {cpu => 1, ram => 6*$coef}, hv_id => 5},
            $vms[6]->id => {resources => {cpu => 1, ram => 7*$coef}, hv_id => 6},
            $vms[7]->id => {resources => {cpu => 1, ram => 8*$coef}, hv_id => 7},
        },

        hvs => {
            1 => {resources => {cpu => 10,ram => 9.5*$coef}},
            2 => {resources => {cpu => 10,ram => 9.5*$coef}},
            3 => {resources => {cpu => 10,ram => 9.5*$coef}},
            4 => {resources => {cpu => 10,ram => 9.5*$coef}},
            5 => {resources => {cpu => 10,ram => 9.5*$coef}},
            6 => {resources => {cpu => 10,ram => 9.5*$coef}},
            7 => {resources => {cpu => 10,ram => 9.5*$coef}},
        },
    };

    while (my ($vm_id, $vm) = each(%{$infra->{vms}})) {
        $infra->{hvs}->{$vm->{hv_id}}->{vm_ids}->{$vm_id} = 1;
    }
    return  $infra;
}

sub getTestInfraForScaling {

    my $infra = {
        vms => {
            $vms[0]->id => {resources => {cpu => 6, ram => 6*1024*1024*1024}, hv_id => 1},
            $vms[1]->id => {resources => {cpu => 2, ram => 2*1024*1024*1024}, hv_id => 1},
            $vms[2]->id => {resources => {cpu => 3, ram => 3*1024*1024*1024}, hv_id => 2},
        },
        hvs => {
            1 => { resources => {cpu => 10,ram => 10*1024*1024*1024}},
            2 => { resources => {cpu => 10,ram => 10*1024*1024*1024}},
        }
    };

    while (my ($vm_id, $vm) = each(%{$infra->{vms}})) {
        $infra->{hvs}->{$vm->{hv_id}}->{vm_ids}->{$vm_id} = 1;
    }

    return  $infra;
}

sub test_scale_cpu {
    my %args = @_;

    lives_ok {
        my $infra = getTestInfraForScaling();
        my $cm = $cm_class->new(infra=>$infra);

        if (scalar @{$cm->scaleCpuHost(host_id => $vms[1]->id, vcpu_number => 2)} != 0) {
            die 'Error in scale in cpu - case: same value';
        }

        my @operations = @{$cm->scaleCpuHost(host_id => $vms[1]->id, vcpu_number => '+1')};

        if ( not (
          scalar @operations == 1
          && $operations[0]->{type} eq 'ScaleCpuHost'
          && $operations[0]->{params}->{cpu_number} == 3
          && $operations[0]->{params}->{context}->{host}->id == $vms[1]->id)) {
            die 'Error in scale in cpu - case: authorized';
        }

        @operations = @{$cm->scaleCpuHost(host_id => $vms[1]->id, vcpu_number => '+2')};

        if ( not (
            scalar @operations == 2
            && $operations[0]->{type} eq 'MigrateHost'
            && $operations[0]->{params}->{context}->{host}->id == 2
            && $operations[0]->{params}->{context}->{vm}->id == $vms[1]->id
            && $operations[1]->{type} eq 'ScaleCpuHost'
            && $operations[1]->{params}->{cpu_number} == 5
            && $operations[1]->{params}->{context}->{host}->id == $vms[1]->id)) {

            die 'Error in scale in cpu - case: need migration of the vm';
        }

        @operations = @{$cm->scaleCpuHost(host_id => $vms[1]->id, vcpu_number => '+3')};

        if ( not (
            $operations[0]->{type} eq 'MigrateHost'
            && $operations[0]->{params}->{context}->{host}->id == 1
            && $operations[0]->{params}->{context}->{vm}->id == $vms[2]->id
            && $operations[1]->{type} eq 'ScaleCpuHost'
            && $operations[1]->{params}->{cpu_number} == 8
            && $operations[1]->{params}->{context}->{host}->id == $vms[1]->id)) {
            die 'Error scale in cpu - case: need migration of another vm';
        }
    } 'Scale cpu algorithms'
}

sub test_optimiaas {

    my %waited_migrations;
    my $cm;
    # Create entity with random arguments because only used for their ids
    lives_ok {
        my $infra = _getTestInfraForOptimiaas();
        $cm = $cm_class->new(infra=>$infra);
        my $operations = $cm->optimIaas();

        %waited_migrations = (1 => 7, 2 => 6, 3 => 5, 4 => 4);

        if (scalar @{$operations} != scalar (keys %waited_migrations)) {
            die 'Wrong operation number after optimiaas'
        }


        for my $operation (@{$operations}) {
            if ( not (
                $operation->{type} eq 'MigrateHost'
                && $operation->{params}->{context}->{host}->id == $waited_migrations{$vm_index{$operation->{params}->{context}->{vm}->id}}
            )) {
                die 'Error in optimiaas - Check migration '.($vm_index{$operation->{params}->{context}->{vm}->id});
            }
        }
    } 'Optimiaas';
}

sub test_scale_memory {
    my %args = @_;

    lives_ok {

        my $infra = getTestInfraForScaling(vms => \@vms);

        my $cm    = $cm_class->new(infra => $infra);

        if ( not (
            $cm->isScalingAuthorized(vm_id => $vms[1]->id, resource_type => 'ram', wanted_resource => 3*$coef) == 1
            && $cm->isScalingAuthorized(vm_id => $vms[1]->id, resource_type => 'ram', wanted_resource => 5*$coef) == 0))
        {
            die 'Check scale memory authorization';
        }

        if (scalar @{$cm->scaleMemoryHost(host_id => $vms[1]->id, memory => 2*$coef)} != 0) {
            die 'Error in scale in memory - case: same value';
        }

        my @operations = @{$cm->scaleMemoryHost(host_id => $vms[1]->id, memory => '+'.($coef))};

        if ( not (
            scalar @operations == 1
            && $operations[0]->{type} eq 'ScaleMemoryHost'
            && $operations[0]->{params}->{memory} == 3*$coef
            && $operations[0]->{params}->{context}->{host}->id == $vms[1]->id)) {
            die 'Error in scale in memory - case: authorized';
        }

        @operations = @{$cm->scaleMemoryHost(host_id => $vms[1]->id, memory => '+'.(2*$coef))};

        if ( not (
            scalar @operations == 2
            && $operations[0]->{type} eq 'MigrateHost'
            && $operations[0]->{params}->{context}->{host}->id == 2
            && $operations[0]->{params}->{context}->{vm}->id == $vms[1]->id
            && $operations[1]->{type} eq 'ScaleMemoryHost'
            && $operations[1]->{params}->{memory} == 5*$coef
            && $operations[1]->{params}->{context}->{host}->id == $vms[1]->id)) {
                die 'Scale in memory - case: need migration of the vm'
        }

        @operations = @{$cm->scaleMemoryHost(host_id => $vms[1]->id, memory => '+'.(3*$coef))};

        if ( not (
            $operations[0]->{type} eq 'MigrateHost'
            && $operations[0]->{params}->{context}->{host}->id == 1
            && $operations[0]->{params}->{context}->{vm}->id == $vms[2]->id
            && $operations[1]->{type} eq 'ScaleMemoryHost'
            && $operations[1]->{params}->{memory} == 8*$coef
            && $operations[1]->{params}->{context}->{host}->id == $vms[1]->id)) {

            die 'Scale in memory - case: need migration of another vm';
        }

        $cm->{_cluster_id} = $service_provider->id;
        @operations = @{$cm->scaleMemoryHost(host_id => $vms[1]->id, memory => '+'.(3*$coef))};

        if (not (
            $operations[0]->{type} eq 'AddNode'
            && $operations[1]->{type} eq 'PreStartNode'
            && $operations[2]->{type} eq 'StartNode'
            && $operations[3]->{type} eq 'PostStartNode'
            && $operations[4]->{type} eq 'MigrateHost'
            && $operations[4]->{params}->{context}->{vm}->id == $vms[1]->id
            && $operations[5]->{type} eq 'ScaleMemoryHost'
            && $operations[5]->{params}->{memory} == 11*$coef
            && $operations[5]->{params}->{context}->{host}->id == $vms[1]->id)) {

            die 'Scale in memory - case: need to start a new hypervisor';
        }
    } 'Scale memory algorithms';
}

