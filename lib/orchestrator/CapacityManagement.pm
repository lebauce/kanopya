#    Copyright © 2012 Hedera Technology SAS
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

=head1 NAME

CapacityManagement

=head1 SYNOPSIS

    use CapacityManagement;

    # Creates orchestrator
    my $cm = CapacityManagement->new(cluster_id => );
    $cm->scaleCpuHost(host_id =>,vcpu_number => );
    $cm->scaleMemoryHost(host_id =>,memory => );
    $cm->optimIaas();

=head1 DESCRIPTION

Capacity Management manage the infrastructure of virtual machine clusters.
It manages the scale-in and the scale-out of virtual machines
It manages the optimization of the infrastructure, which try to minimize the
number of hypervisors used by the infra.

=head1 METHODS

=cut

package CapacityManagement;

use strict;
use warnings;
use Data::Dumper;
use Clone qw(clone);
use List::Util;
use Administrator;
use EFactory;
use Entity::ServiceProvider::Inside::Cluster;
# logger
use Log::Log4perl "get_logger";
my $log = get_logger("");

sub new {
    my $class = shift;
    my %args = @_;

    my $self = {};
    bless $self, $class;

    if(defined $args{test}){
        General::checkParams(args => \%args, required => ['infra']);

        $self->{_infra} = $args{infra};
        $self->{_test}  = 1;
    }
    else {
        General::checkParams(args => \%args, optional => { cluster_id            => undef,
                                                           hypervisor_cluster_id => undef,
                                                           cloud_manager         => undef });

        if (defined $args{cloud_manager}){
            $self->{_cloud_manager} = $args{cloud_manager};
        }
        elsif ( defined $self->{_cluster_id} ) {
            my $cluster = Entity::ServiceProvider::Inside::Cluster->get(id => $self->{_cluster_id});
            $self->{_cloud_manager} = $cluster->getManager(manager_type => 'host_manager');
        }
        elsif ( defined  $self->{_hypervisor_cluster_id} ) {
            my $hypervisor = Entity->get(id => $self->{_hypervisor_cluster_id});
            $self->{_cloud_manager} = $hypervisor->getComponent(name => 'Opennebula', version => 3);
        }
        else {
            throw Kanopya::Exception(error => 'No cloud manager, nor cluster, nor hypervisor id, Capacity Manager cannot construct infra');
        }

        $self->{_admin}                 = Administrator->new();
        $self->{_infra}                 = $self->_constructInfra();
        $self->{_operationPlan}         = [];

        # Get availble memory for all cloud manager hosts (hypervisors)
        $self->{_hvs_mem_available} = undef;

        my $overcommitment_factors =  $self->{_cloud_manager}->getOvercommitmentFactors();
        $log->info('Overcommitment cpu    factor <'.($overcommitment_factors->{overcommitment_cpu_factor}).'>');
        $log->info('Overcommitment memory factor <'.($overcommitment_factors->{overcommitment_memory_factor}).'>');

        $self->{_hvs_mem_available} = {};

        # Add extra information to hypervisors
        my $hypervisors = $self->{_cloud_manager}->getHypervisors();
        for my $hypervisor (@$hypervisors) {
            my $ehypervisor = EFactory::newEEntity(data => $hypervisor);
            my $hypervisor_available_memory = $ehypervisor->getAvailableMemory;

            $self->{_hvs_mem_available}->{$hypervisor->id} = $hypervisor_available_memory->{mem_theoretically_available};
            $self->{_infra}->{hvs}->{$hypervisor->id}->{hv_capa}->{ram_effective} = $hypervisor_available_memory->{mem_effectively_available};

        # Manage CPU Overcommitment when cloud_manager is defined

            $self->{_infra}->{hvs}->{$hypervisor->id}
                                  ->{hv_capa}->{cpu} *= $overcommitment_factors->{overcommitment_cpu_factor};
        }

        # Add extra information to VMs

        my @vm_ids = keys %{$self->{_infra}->{vms}};
        for my $vm_id (@vm_ids) {
            $log->debug("try to get vm Entity $vm_id");
            my $vm   = Entity->get(id => $vm_id);
            my $e_vm = EFactory::newEEntity(data => $vm);
            #TODO: This can take some time => need a method whichs retrieve information in one shot
            $self->{_infra}->{vms}->{$vm_id}->{ram_effective} = $e_vm->getRamUsedByVm->{total};
        }
    }
    $log->debug(Dumper $self->{_infra});
    return $self;
}

sub getInfra{
    my ($self) = @_;
    return $self->{_infra};
}


=head2 _constructInfra

    Class : Private

    Desc : Construct the infrastructure data structure used by algorithms

=cut

sub _constructInfra{
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => []);
    # OPTION : hv_capacities

    my $opennebula;
    if ( defined $self->{_cluster_id} ) {
        my $cluster = Entity::ServiceProvider::Inside::Cluster->get(id => $self->{_cluster_id});
        $opennebula    = $cluster->getManager(manager_type => 'host_manager');
    }
    elsif ( defined  $self->{_hypervisor_cluster_id} ) {
        my $hypervisor = Entity->get(id => $self->{_hypervisor_cluster_id});
        $opennebula    = $hypervisor->getComponent(name => 'Opennebula', version => 3);
    }
    else {
        throw Kanopya::Exception(error => 'No cluster or hypervisor id, Capacity Manager cannot construct infra');
    }

    # Get the list of all hypervisors
    my @hypervisors_r = $opennebula->getHypervisors();
    my $master_hv;

    my ($hvs, $vms);
    for my $hypervisor (@hypervisors_r) {

        if( $hypervisor->node->master_node == 1 ) {
            $master_hv = $hypervisor->getId;
        }

        $hvs->{$hypervisor->getId} = {
            hv_capa => {
                ram => $hypervisor->host_ram,
                cpu => $hypervisor->host_core,
            },
            vm_ids => [],
        };
        my @hypervisor_vms = $hypervisor->getVms();
        for my $vm (@hypervisor_vms) {
            $vms->{$vm->getId} = {
                ram => $vm->host_ram,
                cpu => $vm->host_core,
            };
            push @{$hvs->{$hypervisor->getId}->{vm_ids}}, $vm->getId;

#            my $msg = "Warning capacity management detect an inconcistency in DB VM <$vm_id> in hypervisor <$hvid>";
#            $self->{_admin}->addMessage(
#               from    => 'Capacity Management',
#               level   => 'info',
#               content =>$msg,
#            );
#            $log->warn($msg);
        }
    }

    my $current_infra = {
        vms => $vms,
        hvs => $hvs,
        master_hv => $master_hv,
    };

    return $current_infra;
}

=head2 isScalingAuthorized

    Class : Public

    Desc : Check if a scale-in is authorized w.r.t. the VM resources and the
           destination HV resources.
           Return 1 if scale-in is possible, return 0 if some resources are
           missing
=cut

sub isScalingAuthorized{
    my ($self, %args)   = @_;

    General::checkParams(args     => \%args,
                         required => [ 'vm_id', 'hv_id', 'resource_type', 'wanted_resource' ]);

    my $vm_id           = $args{vm_id};
    my $hv_id           = $args{hv_id};
    my $resource_type   = $args{resource_type};
    my $wanted_resource = $args{wanted_resource}; # MEM MUST BE IN BYTES

    my $infra          = $self->{_infra};

    my $remaining = $self->_getHvSizeRemaining(
        infra => $infra,
        hv_id => $hv_id,
    );

    my $current_resource;
    my $remaining_resource;

    if($resource_type eq 'ram'){
        $current_resource   = $infra->{vms}->{$vm_id}->{ram};
        $remaining_resource = $remaining->{ram};
    }
    elsif($resource_type eq 'cpu'){
        $current_resource   = $infra->{vms}->{$vm_id}->{cpu};
        $remaining_resource = $remaining->{cpu};
    }

    my $delta    = $wanted_resource - $current_resource;
    $log->info("**** [scale-in $resource_type]  Remaining <$remaining_resource> in HV <$hv_id>, need <$delta> more to have <$wanted_resource> ****");
    if ($remaining_resource < $delta) {
        $log->info('not enough resource');
        return 0;
    }
    else{
        $log->info('scaling authorized by capacity management');
        return 1;
    }
}

=head2 isMigrationAuthorized

    Class : Public

    Desc : Check if a migration is authorized w.r.t. the VM resources and the
           destination HV resources.
           Return 1 if migration is possible, return 0 if some resources are
           missing
=cut

sub isMigrationAuthorized{
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => ['vm_id','hv_id']);

    my $vm_id = $args{vm_id};
    my $hv_id = $args{hv_id};

    my $infra  = $self->{_infra};
    my $cpu    = $infra->{vms}->{$vm_id}->{cpu};
    my $ram    = $infra->{vms}->{$vm_id}->{ram};

    my $remaining_resources = $self->_getHvSizeRemaining(
        infra => $infra,
        hv_id => $hv_id,
    );

    if($cpu > $remaining_resources->{cpu}){
        $log->info("Not enough CPU to migrate VM $vm_id ($cpu CPU) in HV $hv_id (".$remaining_resources->{cpu}." CPU)");
        return 0;
    }
    elsif($ram > $remaining_resources->{ram}){
        $log->info("Not enough MEM to migrate VM $vm_id ($ram MB) in HV $hv_id (".$remaining_resources->{ram}." MB)");
        return 0;
    }
    else{
        return 1;
    }
}

=head2 optimIaas

    Class : Private

    Desc : Main entrance to optimize infra. Will call private methode _optimstep
    until optimstep cannot improve the infra (which means cannot empty an HV
    from all its VMs).

=cut

sub optimIaas{
    my ($self,%args) = @_;
    my $infra = $self->{_infra};

    $log->debug('Infra before optimiaas = '.(Dumper $infra));
    my $hv_selected_ids = $self->_separateEmptyHvIds()->{non_empty_hv_ids};
    my $optim;
    my $current_plan = [];
    my $step = 1;
    do{
        $log->info("Loop $step\n");

        $optim = $self->_optimStep(
            infra           => $infra,
            hv_selected_ids => $hv_selected_ids,
            methode         => 2,
            current_plan    => $current_plan,
        );
        $step++;

        $hv_selected_ids = $self->_separateEmptyHvIds()->{non_empty_hv_ids};
    } while ($optim == 1);

    $self->_applyMigrationPlan(
        plan => $current_plan
    );
    $log->debug(Dumper $infra->{hvs});
    return $self->{_operationPlan};
}

sub _applyMigrationPlan{
    # Keep only one migration per VM

    my ($self,%args) = @_;
    General::checkParams(args => \%args, required => ['plan']);

    my $plan = $args{plan};

    # Trick to avoid empty master node (useless)
    # TODO refactoring a better algorithm to avoid this configuration

    my $replace_master_id;
    my $master_hv_id = $self->{_infra}->{master_hv};
    $log->info(Dumper $self->{_infra});

    if( scalar (@{$self->{_infra}->{hvs}->{$master_hv_id}->{vm_ids}} ) == 0 ) {

        $log->info('Master node seems empty, try to empty another HV');

        my $hv_ids = $self->_separateEmptyHvIds()->{non_empty_hv_ids};

        for my $hv_id (@{$hv_ids}) {
            if ( $self->{_infra}->{hvs}->{$hv_id}->{hv_capa}->{cpu} <= $self->{_infra}->{hvs}->{$master_hv_id}->{hv_capa}->{cpu}
                 && $self->{_infra}->{hvs}->{$hv_id}->{hv_capa}->{ram} <= $self->{_infra}->{hvs}->{$master_hv_id}->{hv_capa}->{ram} ) {

                $replace_master_id = $hv_id;
            }
        }
    }

    if (defined $replace_master_id) {
      $log->info("Master id <$master_hv_id> will replace <$replace_master_id> ");
        for my $vm_id (@{$self->{_infra}->{hvs}->{$replace_master_id}->{vm_ids}}) {
            $log->info("$vm_id -> $master_hv_id");
            push @$plan, {vm_id => $vm_id, hv_id => $master_hv_id};
        }
    }
    my @simplified_plan_order; # The order of VM migration
    my $simplified_plan_dest;  # The destination of the VM

    #Check each operation and keep the last one for each VM
    for my $operation (@$plan){
        if(!defined $simplified_plan_dest->{$operation->{vm_id}}){
            push @simplified_plan_order, $operation->{vm_id};
        }
        $simplified_plan_dest->{$operation->{vm_id}} = $operation->{hv_id};
    }

    $log->debug("*** Complete Plan : ");
    $log->debug(Dumper $plan);
    $log->info("*** SIMPLIFIED PLAN MIGRATION ORDER @simplified_plan_order");
    $log->info(Dumper $simplified_plan_dest);



    for my $vm_id (@simplified_plan_order){
        $self->_migrateVmOrder(
            vm_id      => $vm_id,
            hv_dest_id => $simplified_plan_dest->{$vm_id},
        );
    }
}

=head2 getHypervisorIdForVM

    Class : Public

    Desc : Return the hypervisor ID in which to place the vm. Choose the hypervisor
    with enough resource with minimum size (in order to optimize infrastructure usage)


=cut

sub getHypervisorIdForVM{
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => ['wanted_values']);
    # Option : blacklisted_hv_ids
    # Option : selected_hv_ids
    # Wanted values : { cpu => num_of_proc, ram => value_in_bytes}
    my $wanted_values      = $args{wanted_values};
    my $blacklisted_hv_ids = $args{blacklisted_hv_ids};
    my $selected_hv_ids    = $args{selected_hv_ids};

    if (! $self->{_infra}->{hvs}) {
        throw Kanopya::Exception::Internal(error => "Could not find an usable hypervisor");
    }

    if (! defined $selected_hv_ids){
        my @keys_array = keys %{$self->{_infra}->{hvs}};
        $selected_hv_ids = \@keys_array;
    }

    my %hv_selection_ids;
    for my $hv_id (@{$selected_hv_ids}) {
        $hv_selection_ids{$hv_id} = undef;
    }

    for my $blacklisted_hv_id (@{$blacklisted_hv_ids}) {
        delete $hv_selection_ids{$blacklisted_hv_id};
    }
    my @hv_selection_ids_keys = keys %hv_selection_ids;

    my $hv = $self->_findMinHVidRespectCapa(
        hv_selection_ids => \@hv_selection_ids_keys,
        wanted_metrics   => $wanted_values,
    );

    $log->debug('Selected hv <' . $hv->{hv_id} . '>');
    return $hv->{hv_id};
}

=head2 scaleMemoryHost

    Class : Public

    Desc : Try to scale the memory of a VM.
    The increasing contains 3 steps :
    1. Increases the size if the current HV of the VM contains enough resource
    2. Migrate the VM in a HV with enought space if the VM does not
       contain enough resource
    3. Migrate another VM of the same HV which free enough space for the scale-in


=cut

sub scaleMemoryHost{
    my ($self,%args) = @_;
    General::checkParams(args => \%args, required => ['host_id','memory']);

    #Firstly Check
    my $sign = substr($args{memory},0,1); # get the first value
    my $mem_input;

    if($sign eq '+' || $sign eq '-'){
        $mem_input = substr $args{memory},1; # remove sign
    }
    else {
        $mem_input = $args{memory};
    }

    if($mem_input =~ /\D/){
        $self->{_admin}->addMessage(
                           from    => 'Capacity Management',
                           level   => 'info',
                           content => "Wrong format for scale in memory value (typed : $args{memory})",
                        );
        $log->warn("*** Wrong format for scale in memory value (typed : $args{memory})*** ");
        return $self->{_operationPlan};
    }

    # Compute absolute memory instead of relative
    my $memory;
    if($sign eq '+'){
        $memory = $self->{_infra}->{vms}->{$args{host_id}}->{ram} + $mem_input;
    } elsif ($sign eq '-') {
        $memory = $self->{_infra}->{vms}->{$args{host_id}}->{ram} - $mem_input;
    } elsif ($sign =~ /\d/) {
        $memory = $mem_input;
    }else{
        $self->{_admin}->addMessage(
                            from    => 'Capacity Management',
                            level   => 'info',
                            content => "Wrong format for scale in memory value (typed : $args{memory})",
                         );
        $log->warn("*** Wrong format for scale in memory value (typed : $args{memory})*** ");
        return $self->{_operationPlan};
    }

    if($memory <= 0 ){
        $self->{_admin}->addMessage(
                             from    => 'Capacity Management',
                             level   => 'info',
                             content => "Scale in memory value must be strictly positive (typed : $args{memory}");
        $log->warn("*** Cannot Scale Ram to a negative value (typed : $args{memory})*** ");
    }
    elsif ($args{memory_limit} && ($memory > $args{memory_limit})) {
            $self->{_admin}->addMessage(
                                from    => 'Capacity Management',
                                level   => 'info',
                                content => "Scale in is limited to <".($args{memory_limit})."> B, (<$memory> B requested)",
                             );
        $log->warn("Scale in is limited to <".($args{memory_limit})."> B, (<$memory> B requested)");
    }
    else {
        my @hv_selection_ids = keys %{$self->{_infra}->{hvs}};
        $log->info("Call scaleMemoryMetric for host $args{host_id} and new value = $args{memory}");
        $self->_scaleMetric(
            vm_id            => $args{host_id},
            new_value        => $memory,
            hv_selection_ids => \@hv_selection_ids,
            scale_metric     => 'ram',
        );
    }
    return $self->{_operationPlan};
};


=head2 scaleCpuHost

    Class : Public

    Desc : Try to scale de num of CPU of a VM.
    The increasing contains 3 steps :
    1. Increases the size if the current HV of the VM contains enough resource
    2. Migrate the VM in a HV with enought space if the VM does not
       contain enough resource
    3. Migrate another VM of the same HV which free enough space for the scale-in


=cut


sub scaleCpuHost{
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => ['host_id','vcpu_number']);


     my $sign = substr($args{vcpu_number},0,1); # get the first value
     my $vcpu_input;

     if($sign eq '+' || $sign eq '-'){
         $vcpu_input = substr $args{vcpu_number},1; # remove sign
     } else {
         $vcpu_input = $args{vcpu_number};
     }


     # Compute absolute memory instead of relative
    my $cpu;
    if($sign eq '+'){
        $cpu = $self->{_infra}->{vms}->{$args{host_id}}->{cpu} + $vcpu_input;
    } elsif ($sign eq '-') {
        $cpu = $self->{_infra}->{vms}->{$args{host_id}}->{cpu} - $vcpu_input;
    } elsif ($sign =~ /\d/) {
        $cpu = $vcpu_input;
    }else{
        $self->{_admin}->addMessage(
                            from    => 'Capacity Management',
                            level   => 'info',
                            content => "Wrong format for scale in memory value (typed : $args{vcpu_number})",
                         );
        $log->warn("*** Wrong format for scale in cpu value (typed : $args{vcpu_number})*** ");
        return $self->{_operationPlan};
    }



    if($cpu =~ /\D/){
        $self->{_admin}->addMessage(
                            from    => 'Capacity Management',
                            level   => 'info',
                            content => "Wrong format for scale in cpu value (typed : $args{vcpu_number})",
                         );
        $log->warn("*** WRONG FORMAT FOR CPU VALUE (typed : $args{vcpu_number}) *** ");
    }
    elsif($cpu <= 0 ){
        $self->{_admin}->addMessage(
                             from    => 'Capacity Management',
                             level   => 'info',
                             content => "Scale in cpu value must be strictly positive (typed : $args{vcpu_number})",
                         );
        $log->warn("*** Cannot scale CPU to a negative value (typed : $args{vcpu_number}) *** ");
    }
    elsif ($args{cpu_limit} && ($cpu > $args{cpu_limit})) {
            $self->{_admin}->addMessage(
                                from    => 'Capacity Management',
                                level   => 'info',
                                content => "Scale in is limited to $args{cpu_limit} CPU, ($cpu CPU requested)",
                             );
        $log->warn("Scale in is limited to $args{cpu_limit} CPU, ($cpu CPU requested)");
    }
    else {
        my @hv_selection_ids = keys %{$self->{_infra}->{hvs}};
        $log->info("Call scaleCpuMetric for host $args{host_id} and new value = $cpu");
        $self->_scaleMetric(
            vm_id            => $args{host_id},
            new_value        => $cpu,
            hv_selection_ids => \@hv_selection_ids,
            scale_metric     => 'cpu',
        );
    }
    return $self->{_operationPlan};
};

=head2 _scaleMetric

    Class : Private

    Desc : Try to scale a given metric of a VM

=cut


sub _scaleMetric {
    my ($self,%args) = @_;

    my $scale_metric     = $args{scale_metric};
    my $vm_id            = $args{vm_id};
    my $new_value        = $args{new_value};
    my $hv_selection_ids = $args{hv_selection_ids};

    my $infra            = $self->{_infra};

    my $old_value = $infra->{vms}->{$vm_id}->{$scale_metric};
    my $delta     = $new_value - $old_value;


    my $hv_id    = $self->_getHvIdFromVmId(
                      hvs   => $infra->{hvs},
                      vm_id => $vm_id,
                   );


    if($delta < 0 && $new_value > 0){
        # NO SCALING PROBLEM WHEN SIZE IS DECREASING
        $self->_scaleOrder(
            vm_id        => $vm_id,
            new_value    => $new_value,
            vms          => $infra->{vms},
            scale_metric => $scale_metric
        );
    }
    elsif($delta > 0){
        # WHEN SIZE IS INCREASING, HAVE TO CHECK THE REMAINING SIZE
        my $size_remaining = $self->_getHvSizeRemaining(
            infra => $infra,
            hv_id => $hv_id,
        );

        if($size_remaining->{$scale_metric} >= $delta){ # CAN SCALE ON THE SAME HV
            $self->_scaleOrder(
            vm_id => $vm_id, new_value => $new_value, vms => $infra->{vms}, scale_metric => $scale_metric
            );
        }
        else{
            $log->info("Cannot increase $scale_metric, try to migrate the VM");
            #TRY TO MIGRATE THE VM IN ORDER TO SCALE IT
            my $result = $self->_migrateVmToScale(
                vm_id             => $vm_id,
                scale_metric      => $scale_metric,
                new_value         => $new_value,
                hv_selection_ids  => $hv_selection_ids,
            );

          if($result == 1){
              $self->_scaleOrder(
                  vm_id        => $vm_id,
                  new_value    => $new_value,
                  vms          => $infra->{vms},
                  scale_metric => $scale_metric,
              );
            }
            else{ # TRY TO MIGRATE ANOTHER VM
                $log->info("Cannot migrate the VM, try to migrate another VM");

                my $result = $self->_migrateOtherVmToScale(
                    infra             => $infra,
                    vm_id             => $vm_id,
                    new_value         => $new_value,
                    hv_selection_ids  => $hv_selection_ids,
                    scale_metric      => $scale_metric,
                );

                if($result == 1){
                    $self->_scaleOrder(
                        vm_id        => $vm_id,
                        new_value    => $new_value,
                        vms          => $infra->{vms},
                        scale_metric => $scale_metric,
                    );
                }
                else{
                    $self->{_admin}->addMessage(
                        from    => 'Capacity Management',
                        level   => 'info',
                        content => "NOT ENOUGH PLACE TO CHANGE $scale_metric OF $vm_id TO VALUE $new_value",
                    );
                    $log->info("NOT ENOUGH PLACE TO CHANGE $scale_metric OF $vm_id TO VALUE $new_value");
                    $self->_scaleOnNewHV(
                         vm_id        => $vm_id,
                         new_value    => $new_value,
                         scale_metric => $scale_metric,
                     );
                 }
            }
        }
    }
}

sub _scaleOnNewHV {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => ['vm_id', 'new_value', 'scale_metric']);
    my $vm_id        = $args{vm_id};
    my $new_value    = $args{new_value};
    my $scale_metric = $args{scale_metric};

    my $cluster    = Entity->get(id => $self->{_cluster_id});
    my $opennebula = $cluster->getManager(manager_type => 'host_manager');
    my $hv_cluster = $opennebula->getServiceProvider();

    #ADD NEW HV
    push @{$self->{_operationPlan}}, {
        type     => 'AddNode',
        priority => '1',
        params   => { context => { cluster => $hv_cluster } },
     };
    push @{$self->{_operationPlan}}, {
        type     => 'PreStartNode',
        priority => '1',
    };
    push @{$self->{_operationPlan}}, {
        type     => 'StartNode',
        priority => '1',
    };
    push @{$self->{_operationPlan}}, {
        type     => 'PostStartNode',
        priority => '1',
    };

    # MIGRATE HOST
    # NO HOST CONTEXT ! WILL BE HERITATE BY POST START NODE
    if(!defined $self->{_test}){
        push @{$self->{_operationPlan}}, {
            type => 'MigrateHost',
            priority => 1,
            params => {
                context => {
                    vm => Entity->get(id=>$vm_id),
                }
            }
        };
    }
    $log->info("=> migration $vm_id to new started HV");

    # SCALE HOST
    if ($scale_metric eq 'ram'){
        $log->info("=> Operation scaling $scale_metric of vm $vm_id to $new_value");
        if(!defined $self->{_test}){
            push @{$self->{_operationPlan}}, {
                type => 'ScaleMemoryHost',
                priority => 1,
                params => {
                    context => {
                        host => Entity->get(id => $vm_id),
                    },
                    memory  => $new_value,
                }
            };
        }
    }
    elsif ($scale_metric eq 'cpu') {
        $log->info("=> Operation scaling $scale_metric of vm $vm_id to $new_value");
        if(!defined $self->{_test}){
            push @{$self->{_operationPlan}}, {
                type => 'ScaleCpuHost',
                priority => 1,
                params => {
                    context => {
                        host => Entity->get(id => $vm_id),
                    },
                    cpu_number => $new_value,
                }
            };
        }
    }
}

=head2 _getHvSizeOccupied

    Class : Private

    Desc : Return occupied  size (RAM and CPU) of a HV

=cut

sub _getHvSizeOccupied{
    my ($self,%args) = @_;
    my $infra          = $args{infra};
    my $hv_id          = $args{hv_id};

    my $hv_vms = $infra->{hvs}->{$hv_id}->{vm_ids};
    my $size   = {cpu => 0, ram => 0};

    for my $vm_id (@$hv_vms){
        $size->{cpu} += $infra->{vms}->{$vm_id}->{cpu};
        $size->{ram} += $infra->{vms}->{$vm_id}->{ram} + 32*1024*1024; #ADD MARGIN 32MB per VM
    }
    my $all_the_ram   = $infra->{hvs}->{$hv_id}->{hv_capa}->{ram};
    my $all_the_cpu   = $infra->{hvs}->{$hv_id}->{hv_capa}->{cpu};
    $size->{cpu_p} = $size->{cpu} / $all_the_cpu;
    $size->{ram_p} = $size->{ram} / $all_the_ram;
    return $size;
}

=head2 _getHvSizeRemaining

    Class : Private

    Desc : Return remaning size (RAM and CPU) of a HV

=cut

sub _getHvSizeRemaining {
   my ($self,%args) = @_;
    my $infra          = $args{infra};
    my $hv_id          = $args{hv_id};

    my $size = $self->_getHvSizeOccupied(infra => $infra, hv_id => $hv_id);


    my $all_the_ram   = $infra->{hvs}->{$hv_id}->{hv_capa}->{ram};
    my $all_the_cpu   = $infra->{hvs}->{$hv_id}->{hv_capa}->{cpu};


    my $remaining_cpu = $all_the_cpu - $size->{cpu};
    my $remaining_ram;

    if(defined $self->{_hvs_mem_available }) {
        $remaining_ram = $self->{_hvs_mem_available}->{$hv_id};
        $log->info("HV <$hv_id> Remaining RAM <$remaining_ram> using real values");
    }
    else {
        $remaining_ram = $all_the_ram - $size->{ram};
        $log->info("HV <$hv_id> Remaining RAM <$remaining_ram> using computed values");
    }

    my $size_rem = {
        ram   => $remaining_ram,
        cpu   => $remaining_cpu,
        ram_p => $remaining_ram / $all_the_ram,
        cpu_p => $remaining_cpu / $all_the_cpu,
    };
    return $size_rem;
}


=head2 _getHvIdFromVmId

    Class : Private

    Desc : Return the id of the HV in which the VM runs

=cut

sub _getHvIdFromVmId{
    my ($self,%args) = @_;
    my $hvs   = $args{hvs};
    my $vm_id = $args{vm_id};

    my $hv_id;

    HV:for my $hv_id_it (keys %$hvs){
        my $vm_ids = $hvs->{$hv_id_it}->{vm_ids};
        for my $vm_id_it (@$vm_ids){
            if($vm_id == $vm_id_it){
                $hv_id = $hv_id_it;
                last HV;
            }
        }
    }

    return $hv_id;
}

=head2 _scaleMetric

    Class : Private

    Desc : Enqueue a ScaleMemoryHost or a ScaleCpuHost Operation and update locale infra variable

=cut

sub _scaleOrder{
    my ($self,%args) = @_;
    my $vm_id             = $args{vm_id};
    my $new_value         = $args{new_value};
    my $vms               = $args{vms};
    my $scale_metric      = $args{scale_metric};
    $vms->{$vm_id}->{$scale_metric} = $new_value;


    if ($scale_metric eq 'ram'){
        $log->info("=> Operation scaling $scale_metric of vm $vm_id to $new_value");
        if(!defined $self->{_test}){
            push @{$self->{_operationPlan}}, {
                type => 'ScaleMemoryHost',
                priority => 1,
                params => {
                    context => {
                        host => Entity->get(id => $vm_id),
                    },
                    memory  => $new_value,
                }
            };
        }
    }
    elsif ($scale_metric eq 'cpu') {
        $log->info("=> Operation scaling $scale_metric of vm $vm_id to $new_value");
        if(!defined $self->{_test}){
            push @{$self->{_operationPlan}}, {
                type => 'ScaleCpuHost',
                priority => 1,
                params => {
                    context => {
                        host => Entity->get(id => $vm_id),
                    },
                    cpu_number => $new_value,
                }
            };
        }
    }
}

sub _migrateVmModifyInfra{
    my ($self,%args) = @_;
    my $vm_id      = $args{vm_id};
    my $hv_dest_id = $args{hv_dest_id};
    my $hvs        = $args{hvs};

    my $hv_from_id;

    # FIND VM HOST ID
    while (my ($hv_id, $hv) = each %$hvs) {
        my $count = 0;
        my $index_search;
        for my $vm_id_p (@{$hv->{vm_ids}}){
            if($vm_id == $vm_id_p){
                $index_search = $count;
                last;
            }
            $count++
        }
        if(defined $index_search){
            $hv_from_id = $hv_id;
            splice @{$hv->{vm_ids}}, $index_search,1;
        }
    }
    push @{$hvs->{$hv_dest_id}->{vm_ids}}, $vm_id;

    $log->info("Infra modified => migration <$vm_id> (ram: ".($self->{_infra}->{vms}->{$vm_id}->{'ram'}).") from <$hv_from_id> to <$hv_dest_id>");
    # Modify available memory
    if (defined $self->{_hvs_mem_available}) {
        $log->info(Dumper $self->{_hvs_mem_available});
        $self->{_hvs_mem_available}->{$hv_dest_id} -= $self->{_infra}->{vms}->{$vm_id}->{'ram'};
        $self->{_hvs_mem_available}->{$hv_from_id} += $self->{_infra}->{vms}->{$vm_id}->{'ram'};
        $log->info(Dumper $self->{_hvs_mem_available});
    }
}


=head2 _migrateVmOrder

    Class : Private

    Desc : Enqueue the migration Operation and update the local infra variable

=cut

sub _migrateVmOrder{
    my ($self,%args) = @_;
    my $vm_id      = $args{vm_id};
    my $hv_dest_id = $args{hv_dest_id};

    $log->info("Enqueuing MigrateHost of host $vm_id to hypervisor $hv_dest_id");
    if(!defined $self->{_test}){
        push @{$self->{_operationPlan}}, {
            type => 'MigrateHost',
            priority => 1,
            params => {
               context => {
                   vm           => Entity->get(id=>$vm_id),
                   host         => Entity->get(id=>$hv_dest_id),
               }
            }
          };
    }
    $log->info("=> migration $vm_id to $hv_dest_id");
}

=head2 _migrateVmToScale

    Class : Private

    Desc : Migrate a VM in a HV using wanted capacities instead of its actual capacities

=cut

sub _migrateVmToScale{
    my ($self,%args) = @_;

    my $vm_id            = $args{vm_id};
    my $new_value        = $args{new_value};
    my $hv_selection_ids = $args{hv_selection_ids};
    my $scale_metric     = $args{scale_metric};

    my $infra            = $self->{_infra};

    my $wanted_metrics  = clone($infra->{vms}->{$vm_id});
    $wanted_metrics->{$scale_metric} = $new_value;

    my $hv_dest_id = $self->_findMinHVidRespectCapa(
        hv_selection_ids => $hv_selection_ids,
        wanted_metrics   => $wanted_metrics,
    );

    if(defined $hv_dest_id){

        $self->_migrateVmModifyInfra(
            vm_id      => $vm_id,
            hv_dest_id => $hv_dest_id->{hv_id},
            hvs        => $infra->{hvs}
        );

        $self->_migrateVmOrder(
            vm_id      => $vm_id,
            hv_dest_id => $hv_dest_id->{hv_id},
        );
        return 1;
    }
    else{
        return 0;
    }
}

=head2 _findMinHVidRespectCapa

    Class : Private

    Desc : Find the HV id which can accept the wanted_metrics. Choose the one
    with minimum space (average btw RAM and CPU)

=cut

sub _findMinHVidRespectCapa{
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => ['hv_selection_ids', 'wanted_metrics']);

    my $hvs_selection_ids = $args{hv_selection_ids};
    my $wanted_metrics    = $args{wanted_metrics};

    my $infra             = $self->{_infra};

    my $rep;
    for my $hv_id (@$hvs_selection_ids){

        my $size_remaining = $self->_getHvSizeRemaining(
            infra => $infra,
            hv_id => $hv_id,
        );

        my $total_score = $size_remaining->{cpu_p} + $size_remaining->{ram_p};

        $log->info(Dumper $size_remaining);
        $log->info('HV <'.$hv_id.'> RAM wanted <'.($wanted_metrics->{ram}).'> got '.($size_remaining->{ram}));
        $log->info('HV <'.$hv_id.'> CPU wanted <'.($wanted_metrics->{cpu}).'> got '.($size_remaining->{cpu}));

         if(
               $wanted_metrics->{ram} <= $size_remaining->{ram}
            && $wanted_metrics->{cpu} <= $size_remaining->{cpu}
        ){

            if(defined $rep->{min_size_remaining}){
                if($total_score < $rep->{min_size_remaining}){
                    $rep->{min_size_remaining} = $total_score;
                    $rep->{hv_id}              = $hv_id;
                }
            }
            else{
                $rep->{min_size_remaining} = $total_score,
                $rep->{hv_id}              = $hv_id;
            }
        }
    }

    return $rep
}

=head2 _migrateOtherVmToScale

    Class : Private

    Desc : Return remaning size (RAM and CPU) of a HV

=cut

sub _migrateOtherVmToScale{
    my ($self,%args) = @_;
    my $infra            = $args{infra};
    my $vm_id            = $args{vm_id};
    my $new_value        = $args{new_value};
    my $hv_selection_ids = $args{hv_selection_ids};
    my $scale_metric     = $args{scale_metric};

    my $hv_id            = $self->_getHvIdFromVmId(
                              hvs   => $infra->{hvs},
                              vm_id => $vm_id,
    );

    my $vms_in_hv        = $infra->{hvs}->{$hv_id}->{vm_ids};

    my $delta            = $new_value - $infra->{vms}->{$vm_id}->{$scale_metric};
    my $remaining_size   = $self->_getHvSizeRemaining(
                               infra => $infra,
                               hv_id => $hv_id,
                           );


    #Other vm which could be migrated instead of current vm (according to analyzed metric)
    my @other_vms        = grep {
                                  $infra->{vms}->{$_}->{$scale_metric}  + $remaining_size->{$scale_metric} >= $delta   #otherwise too small
                               && $infra->{vms}->{$_}->{$scale_metric} < $new_value #otherwise the other one could have been migrated
                               &&  $_ != $vm_id
                           } @$vms_in_hv;


    $log->info("HV <$hv_id> Remaining size = $remaining_size->{$scale_metric}, Need size = $delta, potential VM to scale (according to $scale_metric) => VM_ids :  @other_vms");


    #Find one with other metric OK
    my @sorted_vms = sort {$infra->{vms}->{$b}->{$scale_metric} <=> $infra->{vms}->{$a}->{$scale_metric}} @other_vms;
    my $hv_dest_id;
    my $vm_to_migrate_id;

    while((!defined $hv_dest_id) && (scalar @sorted_vms > 0)){


        $vm_to_migrate_id = pop @sorted_vms;
        $log->info("Check $vm_to_migrate_id migration possibility...");

        # remove vm HV from selection

         my $vm_hv_id  = $self->_getHvIdFromVmId(
                              hvs   => $infra->{hvs},
                              vm_id => $vm_to_migrate_id,
         );
        my @selection = grep {$_ != $vm_hv_id} @$hv_selection_ids;

        $log->info(Dumper \@selection);

        $hv_dest_id = $self->_findMinHVidRespectCapa(
            hv_selection_ids => \@selection,,
            wanted_metrics   =>  $infra->{vms}->{$vm_to_migrate_id},
        );
    }

    if(defined $hv_dest_id){

        $self->_migrateVmModifyInfra(
            vm_id      => $vm_to_migrate_id,
            hv_dest_id => $hv_dest_id->{hv_id},
            hvs        => $infra->{hvs}
        );

        $self->_migrateVmOrder(
            vm_id      => $vm_to_migrate_id,
            hv_dest_id => $hv_dest_id->{hv_id},
        );
        return 1;
    }
    else{
        return 0;
    }
}


=head2 _optimStep

    Class : Private

    Desc : Process one step of optimisation which try to free one HV
    Method 1 : will try to migrate the VMs of the HV which has the less number
    of VMs
    Method 2 : will try to migrate the VMs of the HV whose larger VM is minimal
    (which is called a minimax operator).

    The size of the VM is computed as an aggreation of its RAM usage and
    its CPU usage

=cut

sub _optimStep{
    my ($self,%args) = @_;
    my $current_plan    = $args{current_plan};
    my $infra           = $args{infra};
    my $hv_selected_ids = $args{hv_selected_ids};
    my $methode         = $args{methode};


    my $min_vm_hv;
    if($methode == 1) {
        $min_vm_hv = $self->_findHvIdWithMinNumVms(hvs => $infra->{hvs}, hv_selected_ids => $hv_selected_ids);
    }
    elsif($methode == 2) {
        $min_vm_hv = $self->_findHvIdWithMinVmSize(infra => $infra, hv_selected_ids => $hv_selected_ids);
    }

    my @hv_selection_ids;

    #TRY TO EMPTY ALL THE MINIMAL HV
    my $num_failed = 0;
    for my $hv_id (@{$min_vm_hv->{id}}){

        # remove $hv_id to find an other hv to migrate the vm
        # TODO More test too choose between these 2 heuristics :

        # In the loop of same HV size, let the empty HV in available HV or not
        # Yes => Empty HV will receive biggest VM when no more space left from an HV
        # which would not have been able to empty anyway => once this HV used it
        # enables to empty the next HV Or perhaps next HV could have been empty
        #
        # => OPTION SELECTED
        @hv_selection_ids = grep { $_ != $hv_id } @$hv_selected_ids;

        # No => Decrease the num of free HV => Decrease processing time ?
        # => To study
        #@hv_selection_ids = grep { $_ != $hv_id } @hv_selection_ids;


        $log->debug("List of HVs available to free <$hv_id> : @hv_selection_ids");
        # MIGRATE ALL VM OF THE SELECTED HV
        my @vmlist = @{$infra->{hvs}->{$hv_id}->{vm_ids}};
        $log->info("List of VMs to migrate = @vmlist");

        for my $vm_to_migrate_id (@vmlist){
            $log->info("Computing where to migrate VM $vm_to_migrate_id");
            my $hv_dest_id = $self->_findMinHVidRespectCapa(
                hv_selection_ids => \@hv_selection_ids,
                wanted_metrics   => $infra->{vms}->{$vm_to_migrate_id},
            );

            if(defined $hv_dest_id){
                $log->info("Enqueue VM <$vm_to_migrate_id> migration");
                $self->_migrateVmModifyInfra(
                    vm_id       => $vm_to_migrate_id,
                    hv_dest_id  => $hv_dest_id->{hv_id},
                    hvs          => $infra->{hvs}
                );
                push @$current_plan, {vm_id => $vm_to_migrate_id, hv_id => $hv_dest_id->{hv_id}};
            }
            else{
                $log->info("___Cannot migrate VM $vm_to_migrate_id");
                $num_failed++;
            }
        }
    }
    ($num_failed > 0) ? return 0 : return 1;
}

=head2 _separateEmptyHvIds

    Class : Private

    Desc :

=cut

sub _separateEmptyHvIds {
    my ($self,%args) = @_;
    my $hvs = $self->{_infra}->{hvs};
    my @empty_hv_ids;
    my @non_empty_hv_ids;
    my @hv_ids;

    for my $hv_index (keys %$hvs){
        if(scalar @{$hvs->{$hv_index}->{vm_ids}} > 0){
            push @non_empty_hv_ids, $hv_index;
        }
        else {
            push @empty_hv_ids, $hv_index;
        }
        push @hv_ids, $hv_index;
    }
    return { empty_hv_ids     => \@empty_hv_ids,
             non_empty_hv_ids => \@non_empty_hv_ids,
             hv_ids           => \@hv_ids,
    };
}

=head2 _findHvIdWithMinVmSize

    Class : Private

    Desc : Return id of Hypervisors which have the minimul number of VMs

=cut


sub _findHvIdWithMinVmSize{
    my ($self,%args) = @_;
    my $infra           = $args{infra};
    my $hv_selected_ids = $args{hv_selected_ids};

    my $hv_index        = $hv_selected_ids->[0];
    my $vm_ids          = $infra->{hvs}->{$hv_index}->{vm_ids};

    my @vm_sizes = map {
        $self->_computeRelativeResourceSize(vm_id => $_, infra => $infra);
    } (@$vm_ids);


    my $n_vm             = List::Util::max @vm_sizes;


    my $rep = {
        id    => [$hv_index],
        count => $n_vm,
    };

    for my $hv_index_s (1..@$hv_selected_ids-1){

        my $hv_index        = $hv_selected_ids->[$hv_index_s];
        my $vm_ids          = $infra->{hvs}->{$hv_index}->{vm_ids};

        my @vm_sizes = map {
            $self->_computeRelativeResourceSize(vm_id => $_, infra => $infra);
        } (@$vm_ids);

        my $n_vm            = List::Util::max @vm_sizes;


        if ($n_vm< $rep->{count}){
            $rep->{count} = $n_vm;
            $rep->{id}    = [$hv_index];
        }
        elsif ($n_vm == $rep->{count}){
            push @{$rep->{id}}, $hv_index;
        }
    }
    $log->debug("_Size selected = $rep->{count} (hypervisor draw = @{$rep->{id}})");
    return $rep;
}

=head2 computeInfraChargeStat

    Class : Public

    Desc : Public method calling private method _computeInfraChargeStat

=cut

sub computeInfraChargeStat{
    my ($self,%args) = @_;
    my $infra = $self->{_infra};
    return $self->_computeInfraChargeStat(infra => $infra);
}

=head2 _computeInfraChargeStat

    Class : Private

    Desc : Compute the average load of the HVs and the num of free HV

=cut

sub _computeInfraChargeStat{
    my ($self,%args) = @_;
    my $infra = $args{infra};

    my $num_of_hv = (scalar (keys %{$infra->{hvs}}));
    my $num_of_empty_hv = 0;
    my $stat;

    $stat->{cpu_p}  = 0;
    $stat->{ram_p}  = 0;

    while(my($hv_id,$v) = each(%{$infra->{hvs}})){
        my @vm_list = @{$infra->{hvs}->{$hv_id}->{vm_ids}};
        if(@vm_list == 0){
            $num_of_empty_hv++;
        }
        else{
            my $size = $self->_getHvSizeOccupied(
                    infra => $infra,
                    hv_id => $hv_id,
            );
            $stat->{cpu_p}  += $size->{cpu_p};
            $stat->{ram_p}  += $size->{ram_p};
            $log->debug("HV $hv_id : CPU [".($size->{cpu_p}*100)." %] RAM [".($size->{ram_p} * 100)." %]");
        }
    }
   my $hash = {
        num_of_empty_hv => $num_of_empty_hv,
        cpu_p_absolute  => $stat->{cpu_p} / $num_of_hv,
        ram_p_absolute  => $stat->{ram_p} / $num_of_hv,
        cpu_p_relative  => $stat->{cpu_p} / ($num_of_hv - $num_of_empty_hv),
        ram_p_relative  => $stat->{ram_p} / ($num_of_hv - $num_of_empty_hv),
    };
    $log->info("TOTAL CPU USED [".($hash->{cpu_p_relative}*100)." %], RAM USED = [".($hash->{ram_p_relative}*100)." %], HV EMPTY $hash->{num_of_empty_hv}");
    return $hash;
}

=head2 _computeRelativeResourceSize

    Class : Private
=cut

sub _computeRelativeResourceSize{
    my ($self,%args) = @_;
    my $vm_id = $args{vm_id};
    my $infra = $args{infra};
    my $hv_id = $self->_getHvIdFromVmId(
        vm_id => $vm_id,
        hvs   => $infra->{hvs},
    );

    my $cpu_relative = $infra->{vms}->{$vm_id}->{cpu} / $infra->{hvs}->{$hv_id}->{hv_capa}->{cpu};
    my $ram_relative = $infra->{vms}->{$vm_id}->{ram} / $infra->{hvs}->{$hv_id}->{hv_capa}->{ram};
    return List::Util::max ($cpu_relative, $ram_relative);
}

=head2 _findHvIdWithMinNumVms

    Class : Private

    Desc : return the ids of the HV with minimum number of VMs and the value

=cut


sub _findHvIdWithMinNumVms{
    my ($self, %args) = @_;
    my $hvs             = $args{hvs};
    my $hv_selected_ids = $args{hv_selected_ids};

    my $hv_index = $hv_selected_ids->[0];
    my $vm_ids   = $hvs->{$hv_index}->{vm_ids};

    my $rep = {
        id    => [$hv_index],
        count => scalar @$vm_ids,
    };

    for my $hv_index_s (1..@$hv_selected_ids-1){
        my $hv_index = $hv_selected_ids->[$hv_index_s];
        my $vm_ids   = $hvs->{$hv_index}->{vm_ids};
        my $n_vm = scalar (@$vm_ids);
        if ($n_vm< $rep->{count}){
            $rep->{count} = $n_vm;
            $rep->{id}    = [$hv_index];
        }
        elsif ($n_vm == $rep->{count}){
            push @{$rep->{id}}, $hv_index;
        }
    }
    return $rep;
}



sub flushHypervisor {
    my ($self,%args) = @_;
    General::checkParams(args => \%args, required => ['hv_id']);

    my $flush_results = $self->_getFlushHypervisorPlan(hv_id => $args{hv_id});

    $self->_applyMigrationPlan(
        plan => $flush_results->{operation_plan}
    );

    return { num_falied     => $flush_results->{num_failed},
             operation_plan => $self->{_operationPlan}
           };
}

sub _getFlushHypervisorPlan {
    my ($self,%args) = @_;
    General::checkParams(args => \%args, required => ['hv_id']);

    my $hv_id = $args{hv_id};
    # use_empty_hv = 1 in order to allow migration of all the vms in empty hv

    my $hv_selected_ids;

    if ( defined $args{use_empty_hv} && $args{use_empty_hv} == 1) {
        $hv_selected_ids = $self->_separateEmptyHvIds()->{non_empty_hv_ids};
    }
    else {
        $hv_selected_ids = $self->_separateEmptyHvIds()->{hv_ids};
    }

    # Just remove current hv it self
    my @hv_selection_ids = grep { $_ != $hv_id } @$hv_selected_ids;

    $log->debug("List of HVs available to free <$hv_id> : @hv_selection_ids");
    # MIGRATE ALL VM OF THE SELECTED HV
    my @vmlist = @{$self->{_infra}->{hvs}->{$hv_id}->{vm_ids}};
    $log->info("List of VMs to migrate = @vmlist");

    my @operation_plan = ();
    my $num_failed      = 0;
    for my $vm_to_migrate_id (@vmlist) {
        $log->info("Computing where to migrate VM $vm_to_migrate_id");
        my $hv_dest_id = $self->_findMinHVidRespectCapa(
            hv_selection_ids => \@hv_selection_ids,
            wanted_metrics   => $self->{_infra}->{vms}->{$vm_to_migrate_id},
        );

        if(defined $hv_dest_id){
            $log->info("Enqueue VM <$vm_to_migrate_id> migration");
            $self->_migrateVmModifyInfra(
                vm_id       => $vm_to_migrate_id,
                hv_dest_id  => $hv_dest_id->{hv_id},
                hvs         => $self->{_infra}->{hvs}
            );
            push @operation_plan, {vm_id => $vm_to_migrate_id, hv_id => $hv_dest_id->{hv_id}};
        }
        else{
            $log->info("___Cannot migrate VM $vm_to_migrate_id");
            $num_failed++;
        }
    }

    return {
        operation_plan => \@operation_plan,
        num_failed => $num_failed
    };
};

1;
