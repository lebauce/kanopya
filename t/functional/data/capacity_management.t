#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Data::Dumper;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'/tmp/capacity_management.log', layout=>'%F %L %p %m%n'});
my $log = get_logger("");


lives_ok {
    use Administrator;
    use Entity::Kernel;
    use Entity::Component;
    use Entity::ServiceProvider::Outside::Externalcluster;
    use CapacityManagement;
    use Entity::Component::Opennebula3;
    use ComponentType;

} 'All uses';

Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
my $adm = Administrator->new;
$adm->{db}->txn_begin;

my @vms;
my $coef = 1024**3;
my $service_provider;
my $service_provider_hypervisors;
my $one;

eval{
    lives_ok {
        $service_provider = Entity::ServiceProvider::Outside::Externalcluster->new(
                externalcluster_name => 'Test Service Provider',
        );

        $service_provider_hypervisors = Entity::ServiceProvider::Outside::Externalcluster->new(
                externalcluster_name => 'Test Hypervisor Externacluster',
        );

        $one = $service_provider_hypervisors->addComponentFromType(
            component_type_id => ComponentType->find(
                hash => {
                    component_name => 'Opennebula',
                }
            )->id,
        );

        # Create entity with random arguments because only used for their ids
        for my $i (1..3) {
            push @vms, Entity::Host->new(
                kernel_id => Entity::Kernel->find(hash => {})->id,
                host_core => 1,
                host_ram => 1,
                host_manager_id =>Entity::Component->find(hash => {})->id,
                host_serial_number => 'sn',
            );
        }
    } 'Fake service provider and nodes creation for scale operations';

     lives_ok{
        $service_provider->addManager(
            manager_id   => $one->id,
            manager_type => 'host_manager',
        );
    } 'Add opennebula to service provider';


    test_hypervisor_selection();
    test_migration_authorization();
    test_scale_memory();
    test_scale_cpu();
    test_optimiaas();

    $adm->{db}->txn_rollback;
};
if($@) {
    $adm->{db}->txn_rollback;
    my $error = $@;
    print $error."\n";
}

sub test_migration_authorization {
    my $cm = CapacityManagement->new(infra => getTestInfraForScaling());

    ok (
        $cm->isMigrationAuthorized(vm_id => $vms[2]->id, hv_id => 1) == 0
        && $cm->isMigrationAuthorized(vm_id => $vms[1]->id, hv_id => 2) == 1,
        'Check Migration authorization'
    );
}

sub test_hypervisor_selection {
    my %args = @_;

    my $infra = getTestInfraForScaling();
    my $cm    = CapacityManagement->new(infra => $infra);

    my %wanted_values;

    %wanted_values = ( cpu => 1, ram => 6*$coef);
    ok (
        $cm->getHypervisorIdForVM ( wanted_values => \%wanted_values) == 2,
        'Check vm placement 1/6'
    );

    %wanted_values = ( cpu => 1, ram => 1*$coef);
    ok (
        $cm->getHypervisorIdForVM ( wanted_values => \%wanted_values) == 1,
        'Check vm placement 2/6'
    );

    %wanted_values = ( cpu => 1, ram => 8*$coef);
    ok (
        !defined $cm->getHypervisorIdForVM ( wanted_values => \%wanted_values),
        'Check vm placement 3/6'
    );

    %wanted_values = ( cpu => 6, ram => 1*$coef);
    ok (
        $cm->getHypervisorIdForVM ( wanted_values => \%wanted_values) == 2,
        'Check vm placement 4/6'
    );

    %wanted_values = ( cpu => 1, ram => 1*$coef);
    ok (
        $cm->getHypervisorIdForVM ( wanted_values => \%wanted_values) == 1,
        'Check vm placement 5/6'
    );

    %wanted_values = ( cpu => 8, ram => 1*$coef);
    ok (
        !defined $cm->getHypervisorIdForVM ( wanted_values => \%wanted_values),
        'Check vm placement 6/6'
    );
}

sub getTestInfraForOptimiaas {
    my %args = @_;

    my $infra = {
          vms => {
                     $vms[0]->id => {cpu => 1, ram => 3*$coef},
                     $vms[1]->id => {cpu => 1, ram => 2*$coef},
                     $vms[2]->id => {cpu => 1, ram => 2*$coef},
                     $vms[3]->id => {cpu => 1, ram => 2*$coef},
                     $vms[4]->id => {cpu => 1, ram => 2*$coef},
                     $vms[5]->id => {cpu => 1, ram => 3*$coef},
                     $vms[6]->id => {cpu => 1, ram => 4*$coef},
                     $vms[7]->id => {cpu => 1, ram => 1*$coef},
                     $vms[8]->id => {cpu => 1, ram => 3*$coef},
                     $vms[9]->id => {cpu => 1, ram => 5*$coef},
                   },

          hvs => {  1 => {vm_ids  => [$vms[0]->id,],
                        hv_capa => {cpu => 10,ram => 9.5*$coef}},
                    2 => {vm_ids  => [$vms[2]->id],
                          hv_capa => {cpu => 10,ram => 9.5*$coef}},
                    3 => {vm_ids  => [$vms[1]->id],
                          hv_capa => {cpu => 10,ram => 9.5*$coef}},
                    4 => {vm_ids  => [$vms[6]->id,$vms[7]->id],
                          hv_capa => {cpu => 10,ram => 9.5*$coef}},
                    5 => {vm_ids  => [$vms[4]->id,$vms[8]->id],
                          hv_capa => {cpu => 10,ram => 9.5*$coef}},
                    6 => {vm_ids  => [$vms[5]->id],
                          hv_capa => {cpu => 10,ram => 9.5*$coef}},
                    7 => {vm_ids  => [$vms[3]->id,$vms[9]->id],
                          hv_capa => {cpu => 10,ram => 9.5*$coef}},
                   },

          master_hv => 1,
        };

    return  $infra;
}

sub getTestInfraForScaling {
    my %args = @_;

    my $infra = {
          vms => {
                     $vms[0]->id => {cpu => 6, ram => 6*1024*1024*1024},
                     $vms[1]->id => {cpu => 2, ram => 2*1024*1024*1024},
                     $vms[2]->id => {cpu => 3, ram => 3*1024*1024*1024},
                   },
          hvs => {  1 => {vm_ids  => [$vms[0]->id,$vms[1]->id],
                        hv_capa => {cpu => 10,ram => 10*1024*1024*1024}},
                    2 => {vm_ids  => [$vms[2]->id],
                          hv_capa => {cpu => 10,ram => 10*1024*1024*1024}},
                   }
        };

    return  $infra;
}

sub test_scale_cpu {
    my %args = @_;

    my $infra = getTestInfraForScaling();
    my $cm = CapacityManagement->new(infra=>$infra);

    ok ( scalar @{$cm->scaleCpuHost(host_id => $vms[1]->id, vcpu_number => 2)} == 0,
         'Scale in cpu - case: same value'
     );

    my @operations = @{$cm->scaleCpuHost(host_id => $vms[1]->id, vcpu_number => '+1')};

    ok (
      scalar @operations == 1
      && $operations[0]->{type} eq 'ScaleCpuHost'
      && $operations[0]->{params}->{cpu_number} == 3
      && $operations[0]->{params}->{context}->{host}->id == $vms[1]->id,
    'Scale in cpu - case: authorized'
    );

    @operations = @{$cm->scaleCpuHost(host_id => $vms[1]->id, vcpu_number => '+2')};

    ok (
        scalar @operations == 2
        && $operations[0]->{type} eq 'MigrateHost'
        && $operations[0]->{params}->{context}->{host}->id == 2
        && $operations[0]->{params}->{context}->{vm}->id == $vms[1]->id
        && $operations[1]->{type} eq 'ScaleCpuHost'
        && $operations[1]->{params}->{cpu_number} == 5
        && $operations[1]->{params}->{context}->{host}->id == $vms[1]->id,
        'Scale in cpu - case: need migration of the vm'
    );

    @operations = @{$cm->scaleCpuHost(host_id => $vms[1]->id, vcpu_number => '+3')};

    ok (
        $operations[0]->{type} eq 'MigrateHost'
        && $operations[0]->{params}->{context}->{host}->id == 1
        && $operations[0]->{params}->{context}->{vm}->id == $vms[2]->id
        && $operations[1]->{type} eq 'ScaleCpuHost'
        && $operations[1]->{params}->{cpu_number} == 8
        && $operations[1]->{params}->{context}->{host}->id == $vms[1]->id,
      'Scale in cpu - case: need migration of another vm'
    );
}

sub test_optimiaas {
    @vms = ();
    my %vm_index;

    # Create entity with random arguments because only used for their ids
    lives_ok {
        for my $i (1..10) {
            my $e = Entity::Host->new(
                        kernel_id          => Entity::Kernel->find(hash => {})->id,
                        host_core          => 1,
                        host_ram           => 1,
                        host_manager_id    => Entity::Component->find(hash => {})->id,
                        host_serial_number => 'sn',
                    );
            push @vms, $e;
            $vm_index{$e->id} = $i;

        }
    } 'Fake service provider and nodes creation for optimiaas';

    my $infra      = getTestInfraForOptimiaas();
    my $cm         = CapacityManagement->new(infra=>$infra);
    my $operations = $cm->optimIaas();

    ok (
        scalar @{$operations} == 8,
        'Check 8 migrations after optimiaas'
    );

    my %waited_migrations = ( 1 => 6, 2 => 1, 3 => 4, 4 => 1,
                              5 => 4, 6 => 6, 9 => 6, 10 => 1,
                            );

    for my $operation (@{$operations}) {
        ok (
            $operation->{type} eq 'MigrateHost'
            && $operation->{params}->{context}->{host}->id == $waited_migrations{$vm_index{$operation->{params}->{context}->{vm}->id}},
            'Check migration vm '.($vm_index{$operation->{params}->{context}->{vm}->id})
        );
    }
}

sub test_scale_memory {
    my %args = @_;

    my $infra = getTestInfraForScaling(vms => \@vms);
    my $cm    = CapacityManagement->new(infra=>$infra);

    ok (
        $cm->isScalingAuthorized(vm_id => $vms[1]->id, hv_id => 1, resource_type => 'ram', wanted_resource => 3*$coef) == 1
        && $cm->isScalingAuthorized(vm_id => $vms[1]->id, hv_id => 1, resource_type => 'ram', wanted_resource => 5*$coef) == 0,
        'Check scale memory authorization'
    );

    ok (
        scalar @{$cm->scaleMemoryHost(host_id => $vms[1]->id, memory => 2*$coef)} == 0,
        'Scale in memory - case: same value'
    );

    my @operations = @{$cm->scaleMemoryHost(host_id => $vms[1]->id, memory => '+'.($coef))};

    ok (
        scalar @operations == 1
        && $operations[0]->{type} eq 'ScaleMemoryHost'
        && $operations[0]->{params}->{memory} == 3*$coef
        && $operations[0]->{params}->{context}->{host}->id == $vms[1]->id,
        'Scale in memory - case: authorized'
    );

    @operations = @{$cm->scaleMemoryHost(host_id => $vms[1]->id, memory => '+'.(2*$coef))};

    ok (
        scalar @operations == 2
        && $operations[0]->{type} eq 'MigrateHost'
        && $operations[0]->{params}->{context}->{host}->id == 2
        && $operations[0]->{params}->{context}->{vm}->id == $vms[1]->id
        && $operations[1]->{type} eq 'ScaleMemoryHost'
        && $operations[1]->{params}->{memory} == 5*$coef
        && $operations[1]->{params}->{context}->{host}->id == $vms[1]->id,
        'Scale in memory - case: need migration of the vm'
    );

    @operations = @{$cm->scaleMemoryHost(host_id => $vms[1]->id, memory => '+'.(3*$coef))};

    ok (
        $operations[0]->{type} eq 'MigrateHost'
        && $operations[0]->{params}->{context}->{host}->id == 1
        && $operations[0]->{params}->{context}->{vm}->id == $vms[2]->id
        && $operations[1]->{type} eq 'ScaleMemoryHost'
        && $operations[1]->{params}->{memory} == 8*$coef
        && $operations[1]->{params}->{context}->{host}->id == $vms[1]->id,
        'Scale in memory - case: need migration of another vm'
    );

    $cm->{_cluster_id} = $service_provider->id;
    @operations = @{$cm->scaleMemoryHost(host_id => $vms[1]->id, memory => '+'.(3*$coef))};

    ok (
        $operations[0]->{type} eq 'AddNode'
        && $operations[0]->{params}->{context}->{cluster}->id eq $service_provider_hypervisors->id
        && $operations[1]->{type} eq 'PreStartNode'
        && $operations[2]->{type} eq 'StartNode'
        && $operations[3]->{type} eq 'PostStartNode'
        && $operations[4]->{type} eq 'MigrateHost'
        && $operations[4]->{params}->{context}->{vm}->id == $vms[1]->id
        && $operations[5]->{type} eq 'ScaleMemoryHost'
        && $operations[5]->{params}->{memory} == 11*$coef
        && $operations[5]->{params}->{context}->{host}->id == $vms[1]->id,
        'Scale in memory - case: need to start a new hypervisor'
    );
}
