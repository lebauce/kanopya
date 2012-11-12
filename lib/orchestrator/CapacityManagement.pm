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




=pod

=begin classdoc

Capacity Management manages the infrastructure of virtual machine clusters.
It manages the scale-in and the scale-out of virtual machines
It manages the optimization of the infrastructure, which tries to minimize the
number of hypervisors used by the infra.

@since    2012-Jun-10
@instance hash
@self     $self

=end classdoc

=cut

package CapacityManagement;

use strict;
use warnings;
use Data::Dumper;
use Clone qw(clone);
use List::Util;
use Administrator;
use EFactory;
use Message;
use Entity::ServiceProvider::Inside::Cluster;
# logger
use Log::Log4perl "get_logger";
my $log = get_logger("");

=pod

=begin classdoc

@constructor

Create a new instance of the class.
It generates its own representation of the current infrastructure in order to apply algothims
locally before generation Operation Plan.

@return a class instance

=end classdoc

=cut

sub new {
    my $class = shift;
    my %args = @_;

    my $self = {};
    bless $self, $class;

    $self->{_operationPlan} = [];

    # Either the infra is get by params, or it is directly constructed
    if(defined $args{infra}){
        $self->{_infra} = $args{infra};
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

        $self->{_admin} = Administrator->new();
        $self->{_infra} = $self->_constructInfra();

        # Get availble memory for all cloud manager hosts (hypervisors)
        my $overcommitment_factors =  $self->{_cloud_manager}->getOvercommitmentFactors();
        $log->info('Overcommitment cpu    factor <'.($overcommitment_factors->{overcommitment_cpu_factor}).'>');
        $log->info('Overcommitment memory factor <'.($overcommitment_factors->{overcommitment_memory_factor}).'>');

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
    return $self;
}

=pod

=begin classdoc

Variable getter

@return Internal representation of current infrastructure

=end classdoc

=cut

sub getInfra{
    my ($self) = @_;
    return $self->{_infra};
}

=pod

=begin classdoc

Construct the infrastructure data structure used in the class by algorithms.
Use the cloud manager to get the infrastructure information

@return constructed infrastructure.

=end classdoc

=cut

sub _constructInfra{
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => []);
    # OPTION : hv_capacities

    # Get the list of all hypervisors
    my @hypervisors_r = $self->{_cloud_manager}->getHypervisors();
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
            vm_ids  => [],
        };
        my @hypervisor_vms = $hypervisor->getVms();
        for my $vm (@hypervisor_vms) {
            $vms->{$vm->getId} = {
                ram => $vm->host_ram,
                cpu => $vm->host_core,
            };
            push @{$hvs->{$hypervisor->getId}->{vm_ids}}, $vm->getId;
        }
    }

    my $current_infra = {
        vms => $vms,
        hvs => $hvs,
        master_hv => $master_hv,
    };

    return $current_infra;
}

=pod

=begin classdoc

Check if a scale-in is authorized w.r.t. the VM resources and the destination HV resources.

@param vm_id id of the checked vm
@param hv_id id of the hypervisor of the vm
@param resource_type scaled resource
@param wanted_resource value of the resource you want to scale  

@return 1 if scale-in is possible, return 0 if some resources are missing.

=end classdoc

=cut


sub isScalingAuthorized{
    my ($self, %args)   = @_;

    General::checkParams(args     => \%args,
                         required => [ 'vm_id', 'hv_id', 'resource_type', 'wanted_resource' ]);
    #TODO : remove hv_id param since we can get it
    my $vm_id           = $args{vm_id};
    my $hv_id           = $args{hv_id};
    my $resource_type   = $args{resource_type};
    my $wanted_resource = $args{wanted_resource}; # Mem must be in bytes

    my $remaining = $self->_getHvSizeRemaining(
        hv_id => $hv_id,
    );

    my $current_resource;
    my $remaining_resource;

    if($resource_type eq 'ram'){
        $current_resource   = $self->{_infra}->{vms}->{$vm_id}->{ram};
        $remaining_resource = $remaining->{ram};
    }
    elsif($resource_type eq 'cpu'){
        $current_resource   = $self->{_infra}->{vms}->{$vm_id}->{cpu};
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

=pod

=begin classdoc

Check if a migration is authorized w.r.t. the VM resources and the destination HV resources.

@param vm_id id of the vm to migrate
@param hv_id id of the destination hypervisor

@return 1 if migration is possible, return 0 if some resources are missing

=end classdoc

=cut

sub isMigrationAuthorized{
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => ['vm_id','hv_id']);

    my $vm_id = $args{vm_id};
    my $hv_id = $args{hv_id};

    my @resources = keys %{$self->{_infra}->{vms}->{$vm_id}};

    my $remaining_resources = $self->_getHvSizeRemaining(
        hv_id => $hv_id,
    );

    for my $resource (@resources) {
        $log->info("Check $resource, good if :  ".$self->{_infra}->{vms}->{$vm_id}->{$resource}.' < '.$remaining_resources->{$resource});

        if( $self->{_infra}->{vms}->{$vm_id}->{$resource} > $remaining_resources->{$resource}  ) {
            $log->info("Not enough $resource to migrate VM $vm_id (".$self->{_infra}->{vms}->{$vm_id}->{$resource}.") in HV $hv_id (".$remaining_resources->{$resource} );
            return 0;
        }
    }
    return 1;
}

=pod

=begin classdoc

Desc : Main entrance to optimize infra. Will call private methode _optimstep
until optimstep cannot improve the infra (which means cannot empty an HV
from all its VMs).

@return Plan formed by a list of Migration Operation to enqueue

=end classdoc

=cut

sub optimIaas{
    my $self = shift;

    $self->{_operationPlan} = [];
    $log->debug('Infra before optimiaas = '.(Dumper $self->{_infra}));
    my $hv_selected_ids = $self->_separateEmptyHvIds()->{non_empty_hv_ids};
    my $optim;
    my $current_plan = [];
    my $step = 1;
    do{
        $log->info("Loop $step\n");

        $optim = $self->_optimStep(
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
    $log->debug(Dumper $self->{_infra}->{hvs});
    return $self->{_operationPlan};
}

=pod

=begin classdoc

Simplified the migration plan to avoir useless migration and to keep some vms in the master node 

@param plan the orginal migration plan

@return The simplified plan

=end classdoc

=cut

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

        my $hvs = $self->{_infra}->{hvs};
        for my $hv_id (@{$hv_ids}) {
            if ($hvs->{$hv_id}->{hv_capa}->{cpu} <= $hvs->{$master_hv_id}->{hv_capa}->{cpu}
                && $hvs->{$hv_id}->{hv_capa}->{ram} <= $hvs->{$master_hv_id}->{hv_capa}->{ram}) {

                $replace_master_id = $hv_id;
            }
        }
    }

    if (defined $replace_master_id) {
      $log->info("Master id <$master_hv_id> will replace <$replace_master_id> ");
        my $vms_ids  = clone($self->{_infra}->{hvs}->{$replace_master_id}->{vm_ids});
        for my $vm_id (@{$vms_ids}) {
            push @$plan, {vm_id => $vm_id, hv_id => $master_hv_id};
            $self->_migrateVmModifyInfra(
                vm_id       => $vm_id,
                hv_dest_id  => $master_hv_id,
            );
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

    $log->debug("Complete Plan : ");
    $log->debug(Dumper $plan);
    $log->info("Simplified plan migration order @simplified_plan_order");
    $log->info(Dumper $simplified_plan_dest);

    for my $vm_id (@simplified_plan_order){
        $self->_migrateVmOrder(
            vm_id      => $vm_id,
            hv_dest_id => $simplified_plan_dest->{$vm_id},
        );
    }
}

=pod

=begin classdoc

Return the hypervisor ID in which to place the vm. Choose the hypervisor with enough resource 
with minimum size (in order to optimize infrastructure usage) 

@param wanted_values the resource values of the VM

@return The hypervisor id

=end classdoc

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

    if (defined $hv->{hv_id}) {
        $log->debug('Selected hv <' . $hv->{hv_id} . '>');
    }
    else {
        $log->debug('No free hypervisor');
    }

    return $hv->{hv_id};
}

=pod

=begin classdoc

Try to scale the memory of a VM.
    The increasing contains 3 steps :
    1. Increases the size if the current HV of the VM contains enough resource
    2. Migrate the VM in a HV with enought space if the VM does not
       contain enough resource
    3. Migrate another VM of the same HV which free enough space for the scale-in

@param host_id the id of the vm
@param memory the value of the scaled memory

@return List of operations to be enqueued to perform the scale

=end classdoc

=cut

sub scaleMemoryHost{
    my ($self,%args) = @_;
    General::checkParams(args => \%args, required => ['host_id','memory']);

    $self->{_operationPlan} = [];
    #Firstly Check
    my $sign = substr($args{memory},0,1); # get the first value
    my $mem_input;

    if($sign eq '+' || $sign eq '-'){
        $mem_input = substr $args{memory},1; # remove sign
    }
    else {
        $mem_input = $args{memory};
    }

    if ($mem_input =~ /\D/){
        Message->send(
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
    } else {
        Message->send(
            from    => 'Capacity Management',
            level   => 'info',
            content => "Wrong format for scale in memory value (typed : $args{memory})",
        );
        $log->warn("*** Wrong format for scale in memory value (typed : $args{memory})*** ");
        return $self->{_operationPlan};
    }

    if ($memory <= 0) {
        Message->send(
            from    => 'Capacity Management',
            level   => 'info',
            content => "Scale in memory value must be strictly positive (typed : $args{memory}"
        );
        $log->warn("*** Cannot Scale Ram to a negative value (typed : $args{memory})*** ");
    }
    elsif ($args{memory_limit} && ($memory > $args{memory_limit})) {
        Message(
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

=pod

=begin classdoc

Try to scale de num of CPU of a VM.
    The increasing contains 3 steps :
    1. Increases the size if the current HV of the VM contains enough resource
    2. Migrate the VM in a HV with enought space if the VM does not
       contain enough resource
    3. Migrate another VM of the same HV which free enough space for the scale-in

@param host_id the id of the vm
@param vcpu_number the number of scaled vcpu

@return List of operations to be enqueued to perform the scale

=end classdoc

=cut

sub scaleCpuHost{
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => ['host_id','vcpu_number']);
    $self->{_operationPlan} = [];

     my $sign = substr($args{vcpu_number},0,1); # get the first value
     my $vcpu_input;

     if ($sign eq '+' || $sign eq '-') {
         $vcpu_input = substr $args{vcpu_number},1; # remove sign
     }
     else {
         $vcpu_input = $args{vcpu_number};
     }

     # Compute absolute memory instead of relative
    my $cpu;
    if ($sign eq '+') {
        $cpu = $self->{_infra}->{vms}->{$args{host_id}}->{cpu} + $vcpu_input;
    }
    elsif ($sign eq '-') {
        $cpu = $self->{_infra}->{vms}->{$args{host_id}}->{cpu} - $vcpu_input;
    }
    elsif ($sign =~ /\d/) {
        $cpu = $vcpu_input;
    } else {
        Message->send(
            from    => 'Capacity Management',
            level   => 'info',
            content => "Wrong format for scale in memory value (typed : $args{vcpu_number})",
        );

        $log->warn("Wrong format for scale in cpu value (typed : $args{vcpu_number})");
        return $self->{_operationPlan};
    }

    if ($cpu =~ /\D/) {
        Message->send(
            from    => 'Capacity Management',
            level   => 'info',
            content => "Wrong format for scale in cpu value (typed : $args{vcpu_number})",
        );

        $log->warn("Wrong format for cpu value (typed : $args{vcpu_number})");
    }
    elsif ($cpu <= 0) {
        Message->send(
            from    => 'Capacity Management',
            level   => 'info',
            content => "Scale in cpu value must be strictly positive (typed : $args{vcpu_number})",
        );

        $log->warn("Cannot scale CPU to a negative value (typed : $args{vcpu_number})");
    }
    elsif ($args{cpu_limit} && ($cpu > $args{cpu_limit})) {
        Message->send(
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


=pod

=begin classdoc

Try to scale a given metric directly or after migrations

@param vm_id the id of the vm
@param $scale_metric the metric to scale
@param $new_value new value for the metric
@param $hv_selection_ids hypervisor which can be used to migrate vm if necessary

=end classdoc

=cut

sub _scaleMetric {
    my ($self,%args) = @_;

    my $scale_metric     = $args{scale_metric};
    my $vm_id            = $args{vm_id};
    my $new_value        = $args{new_value};
    my $hv_selection_ids = $args{hv_selection_ids};

    my $old_value = $self->{_infra}->{vms}->{$vm_id}->{$scale_metric};
    my $delta     = $new_value - $old_value;

    my $hv_id = $self->_getHvIdFromVmId(vm_id => $vm_id);

    if ($delta < 0 && $new_value > 0) {
        # No scaling problem when size is decreasing
        $self->_scaleOrder(
            vm_id        => $vm_id,
            new_value    => $new_value,
            scale_metric => $scale_metric
        );
    }

    elsif ($delta > 0) {
        # When size is increasing, check the remaining size
        my $size_remaining = $self->_getHvSizeRemaining(
            hv_id => $hv_id,
        );

        # Scale on the same hypervisor
        if ($size_remaining->{$scale_metric} >= $delta) {
            $self->_scaleOrder(
                vm_id => $vm_id, new_value => $new_value, scale_metric => $scale_metric
            );
        }
        else {
            $log->info("Cannot increase $scale_metric, try to migrate the VM");

            # Try to migrate the mv in order to scale it
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
                    scale_metric => $scale_metric,
                );
            }
            else { # Try to migrate another vm
                $log->info("Cannot migrate the VM, try to migrate another VM");

                my $result = $self->_migrateOtherVmToScale(
                    vm_id             => $vm_id,
                    new_value         => $new_value,
                    hv_selection_ids  => $hv_selection_ids,
                    scale_metric      => $scale_metric,
                );

                if ($result == 1) {
                    $self->_scaleOrder(
                        vm_id        => $vm_id,
                        new_value    => $new_value,
                        scale_metric => $scale_metric,
                    );
                }
                else {
                    Message->send(
                        from    => 'Capacity Management',
                        level   => 'info',
                        content => "Not enough place to change $scale_metric OF $vm_id TO VALUE $new_value",
                    );
                    $log->info("Not enough place to change $scale_metric OF $vm_id TO VALUE $new_value");

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

=pod

=begin classdoc

Try to scale the VM on a new hypervisor
Enqueue the start of the new hypervisor before enqueuing the scale. The operation will fail and the
whole workflow will be cancelled if there is no free hv in cloud manager

@param vm_id the id of the vm
@param scale_metric the metric to scale ('cpu' or 'ram')
@param new_value the value of the metric

=end classdoc

=cut

sub _scaleOnNewHV {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => ['vm_id', 'new_value', 'scale_metric']);
    my $vm_id        = $args{vm_id};
    my $new_value    = $args{new_value};
    my $scale_metric = $args{scale_metric};

    my $cluster      = Entity->get(id => $self->{_cluster_id});
    my $opennebula   = $cluster->getManager(manager_type => 'host_manager');
    my $hv_cluster   = $opennebula->getServiceProvider();

    # Add new hypervisor
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

    # Migrate host
    # Host context will be inheritate by postStart node

    push @{$self->{_operationPlan}}, {
        type => 'MigrateHost',
        priority => 1,
        params => {
            context => {
                vm => Entity->get(id=>$vm_id),
            }
        }
    };

    $log->info("=> migration $vm_id to new started HV");

    # Scale host
    if ($scale_metric eq 'ram'){
        $log->info("=> Operation scaling $scale_metric of vm $vm_id to $new_value");
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
    elsif ($scale_metric eq 'cpu') {
        $log->info("=> Operation scaling $scale_metric of vm $vm_id to $new_value");
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


=pod

=begin classdoc

Return occupied size (RAM and CPU) of a hypervisor. Add 32MB margin for each VM

@param hv_id the hypervisor id

@return Occupied size of the hypervisor

=end classdoc

=cut

sub _getHvSizeOccupied{
    my ($self,%args) = @_;
    my $hv_id          = $args{hv_id};

    my $hv_vms = $self->{_infra}->{hvs}->{$hv_id}->{vm_ids};
    my $size   = {cpu => 0, ram => 0};

    for my $vm_id (@$hv_vms) {
        $size->{cpu} += $self->{_infra}->{vms}->{$vm_id}->{cpu};
        $size->{ram} += $self->{_infra}->{vms}->{$vm_id}->{ram} + 32*1024*1024; #ADD MARGIN 32MB per VM
        #TODO margin used originally for Xen. Can be parametered
    }

    my $all_the_ram  = $self->{_infra}->{hvs}->{$hv_id}->{hv_capa}->{ram};
    my $all_the_cpu  = $self->{_infra}->{hvs}->{$hv_id}->{hv_capa}->{cpu};
    $size->{cpu_p} = $size->{cpu} / $all_the_cpu;
    $size->{ram_p} = $size->{ram} / $all_the_ram;
    return $size;
}


=pod

=begin classdoc

Return remaning size (RAM and CPU) of a hypervisor

@param hv_id the hypervisor id

@return Remaining size of the hypervisor

=end classdoc

=cut

sub _getHvSizeRemaining {
    my ($self,%args) = @_;
    my $hv_id        = $args{hv_id};

    my $size = $self->_getHvSizeOccupied(hv_id => $hv_id);

    my $all_the_ram   = $self->{_infra}->{hvs}->{$hv_id}->{hv_capa}->{ram};
    my $all_the_cpu   = $self->{_infra}->{hvs}->{$hv_id}->{hv_capa}->{cpu};

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
        ram           => $remaining_ram,
        cpu           => $remaining_cpu,
        ram_p         => $remaining_ram / $all_the_ram,
        cpu_p         => $remaining_cpu / $all_the_cpu,
        ram_effective => $self->{_infra}->{hvs}->{$hv_id}->{hv_capa}->{ram_effective},
    };

    if (defined  $self->{_infra}->{hvs}->{$hv_id}->{hv_capa}->{ram_free_effective}) {
       $size_rem->{ram_free_effective} = $self->{_infra}->{hvs}->{$hv_id}->{hv_capa}->{ram_free_effective};
    }

    return $size_rem;
}

=pod

=begin classdoc

Return the id of the HV in which the VM runs

@param vm_id the virtual machine id

@return the vm's hypervisor id

=end classdoc

=cut

sub _getHvIdFromVmId{
    my ($self,%args) = @_;
    my $vm_id = $args{vm_id};

    my $hv_id;

    #TODO a specific infrastructure in order to avoid this not optimized loops...
    HV:for my $hv_id_it (keys %{$self->{_infra}->{hvs}}){
        my $vm_ids = $self->{_infra}->{hvs}->{$hv_id_it}->{vm_ids};
        for my $vm_id_it (@$vm_ids){
            if($vm_id == $vm_id_it){
                $hv_id = $hv_id_it;
                last HV;
            }
        }
    }
    return $hv_id;
}


=pod

=begin classdoc

Enqueue a ScaleMemoryHost or a ScaleCpuHost Operation and update locale infra variable

@param vm_id id of the vm
@param scale_metric metric to scale
@param new_value value of the metric to scale

=end classdoc

=cut

sub _scaleOrder{
    my ($self,%args) = @_;

    my $vm_id         = $args{vm_id};
    my $new_value     = $args{new_value};
    my $scale_metric  = $args{scale_metric};

    $self->{_infra}->{vms}->{$vm_id}->{$scale_metric} = $new_value;

    if ($scale_metric eq 'ram') {
        $log->info("=> Operation scaling $scale_metric of vm $vm_id to $new_value");
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
    elsif ($scale_metric eq 'cpu') {
        $log->info("=> Operation scaling $scale_metric of vm $vm_id to $new_value");
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

=pod

=begin classdoc

Modify the internal infrastructure when the algorithms plan a migration operation

@param vm_id id of the vm
@param hv_dest_id id of destination hypervisor 

=end classdoc

=cut

sub _migrateVmModifyInfra{
    my ($self,%args) = @_;
    my $vm_id      = $args{vm_id};
    my $hv_dest_id = $args{hv_dest_id};

    my $hv_from_id;

    # Find vm original hypervisor id
    while (my ($hv_id, $hv) = each %{$self->{_infra}->{hvs}}) {
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
    push @{$self->{_infra}->{hvs}->{$hv_dest_id}->{vm_ids}}, $vm_id;

    $log->info("Infra modified => migration <$vm_id> (ram: ".($self->{_infra}->{vms}->{$vm_id}->{'ram'}).") from <$hv_from_id> to <$hv_dest_id>");

    # Modify available memory
    if (defined $self->{_hvs_mem_available}) {
        $log->debug(Dumper $self->{_hvs_mem_available});
        $self->{_hvs_mem_available}->{$hv_dest_id} -= $self->{_infra}->{vms}->{$vm_id}->{'ram'};
        $self->{_hvs_mem_available}->{$hv_from_id} += $self->{_infra}->{vms}->{$vm_id}->{'ram'};
        $log->debug(Dumper $self->{_hvs_mem_available});
    }

    # Modify RAM effective when overcommitment
    if( defined $self->{_infra}->{hvs}->{$hv_from_id}->{hv_capa}->{ram_effective}) {
        $log->debug("RAM effective before hv <$hv_dest_id> <"
                    .($self->{_infra}->{hvs}->{$hv_dest_id}->{hv_capa}->{ram_effective})
                    ."> ; hv <$hv_from_id> <"
                    .($self->{_infra}->{hvs}->{$hv_from_id}->{hv_capa}->{ram_effective}).">"
        );
        $self->{_infra}->{hvs}->{$hv_dest_id}->{hv_capa}->{ram_effective} -= $self->{_infra}->{vms}->{$vm_id}->{'ram_effective'};
        $self->{_infra}->{hvs}->{$hv_from_id}->{hv_capa}->{ram_effective} += $self->{_infra}->{vms}->{$vm_id}->{'ram_effective'};
        $log->debug("RAM effective before hv <$hv_dest_id> <"
                    .($self->{_infra}->{hvs}->{$hv_dest_id}->{hv_capa}->{ram_effective})
                    ."> ; hv <$hv_from_id> <"
                    .($self->{_infra}->{hvs}->{$hv_from_id}->{hv_capa}->{ram_effective}).">"
        );
    }
}


=pod

=begin classdoc

Add a migration Operation in internal operation plan

@param vm_id id of the vm
@param hv_dest_id the id of destination hypervisor

=end classdoc

=cut

sub _migrateVmOrder{
    my ($self,%args) = @_;
    my $vm_id      = $args{vm_id};
    my $hv_dest_id = $args{hv_dest_id};

    $log->info("Enqueuing MigrateHost of host $vm_id to hypervisor $hv_dest_id");
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
    $log->info("=> migration $vm_id to $hv_dest_id");
}


=pod

=begin classdoc

Migrate a VM in a HV using wanted capacities instead of its actual capacities

@param vm_id id of the vm
@param scale_metric the metric ('cpu' or 'ram')
@param new_value the value of the metric
@param hv_selection_ids hypervisor which can be used to perform the migration

@return 1 if the order has been add to internal operation plan, 0 if it failed

=end classdoc

=cut

sub _migrateVmToScale{
    my ($self,%args) = @_;

    my $vm_id            = $args{vm_id};
    my $new_value        = $args{new_value};
    my $hv_selection_ids = $args{hv_selection_ids};
    my $scale_metric     = $args{scale_metric};

    my $wanted_metrics  = clone($self->{_infra}->{vms}->{$vm_id});
    $wanted_metrics->{$scale_metric} = $new_value;

    my $hv_dest_id = $self->_findMinHVidRespectCapa(
        hv_selection_ids => $hv_selection_ids,
        wanted_metrics   => $wanted_metrics,
    );

    if(defined $hv_dest_id){

        $self->_migrateVmModifyInfra(
            vm_id      => $vm_id,
            hv_dest_id => $hv_dest_id->{hv_id},
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


=pod

=begin classdoc

Find the HV id which can accept the wanted_metrics. Choose the one
with minimum space (average btw RAM and CPU)

@param wanted_metrics values wanted for the vm
@param hv_selection_ids hypervisor which can be used to perform the migration

@return a hash with keys : hv_id => the hypervisor id, min_size_remaining => the 'score' used to 
compare 2 hypervisors

=end classdoc

=cut

sub _findMinHVidRespectCapa{
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => ['hv_selection_ids', 'wanted_metrics']);

    my $hvs_selection_ids = $args{hv_selection_ids};
    my $wanted_metrics    = $args{wanted_metrics};

    my $rep;
    for my $hv_id (@$hvs_selection_ids){

        my $size_remaining = $self->_getHvSizeRemaining(
            hv_id => $hv_id,
        );

        my $total_score = $size_remaining->{cpu_p} + $size_remaining->{ram_p};

        $log->info('HV <'.$hv_id.'> Wanted RAM <'.($wanted_metrics->{ram}).'> got <'.($size_remaining->{ram}).' ('.(100*$size_remaining->{ram_p}).'%) > & CPU <'.($wanted_metrics->{cpu}).'> got <'.($size_remaining->{cpu}).' ('.(100*$size_remaining->{cpu_p}).'%) >');

        my $condition = 1;
        for my $metric (keys %$wanted_metrics) {
            if(defined $size_remaining->{$metric}) {
                $log->info("Check $metric, ok if $wanted_metrics->{$metric} <= $size_remaining->{$metric}");
                $condition &&= $wanted_metrics->{$metric} <= $size_remaining->{$metric};
            }
        }

        if($condition){
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


=pod

=begin classdoc

Migrate another VM in order to relieve hypervisor and allow scale for the current vm

@param vm_id id of the vm
@param scale_metric the metric ('cpu' or 'ram')
@param new_value the value of the metric

@return 1 if operation succeed, 0 if it failed

=end classdoc

=cut

sub _migrateOtherVmToScale{
    my ($self,%args) = @_;

    my $vm_id            = $args{vm_id};
    my $new_value        = $args{new_value};
    my $scale_metric     = $args{scale_metric};
    my $hv_selection_ids = $args{hv_selection_ids};
    
    my $hv_id            = $self->_getHvIdFromVmId(vm_id => $vm_id);

    my $vms_in_hv        = $self->{_infra}->{hvs}->{$hv_id}->{vm_ids};

    my $delta            = $new_value - $self->{_infra}->{vms}->{$vm_id}->{$scale_metric};
    my $remaining_size   = $self->_getHvSizeRemaining(
                               hv_id => $hv_id,
                           );


    #Other vm which could be migrated instead of current vm (according to analyzed metric)
    my @other_vms = grep {
                        $self->{_infra}->{vms}->{$_}->{$scale_metric} + $remaining_size->{$scale_metric} >= $delta   #otherwise too small
                        && $self->{_infra}->{vms}->{$_}->{$scale_metric} < $new_value #otherwise the other one could have been migrated
                        &&  $_ != $vm_id
                    } @$vms_in_hv;


    $log->info("HV <$hv_id> Remaining size = $remaining_size->{$scale_metric}, Need size = $delta, potential VM to scale (according to $scale_metric) => VM_ids :  @other_vms");


    #Find one with other metric OK
    my @sorted_vms = sort {
        $self->{_infra}->{vms}->{$b}->{$scale_metric} <=> $self->{_infra}->{vms}->{$a}->{$scale_metric}
    } @other_vms;

    my $hv_dest_id;
    my $vm_to_migrate_id;

    while ((!defined $hv_dest_id) && (scalar @sorted_vms > 0)) {
        $vm_to_migrate_id = pop @sorted_vms;
        $log->info("Check $vm_to_migrate_id migration possibility...");

        # remove vm HV from selection

        my $vm_hv_id  = $self->_getHvIdFromVmId(
                            vm_id => $vm_to_migrate_id,
                        );

        my @selection = grep {$_ != $vm_hv_id} @$hv_selection_ids;

        $log->info(Dumper \@selection);

        $hv_dest_id = $self->_findMinHVidRespectCapa(
            hv_selection_ids => \@selection,,
            wanted_metrics   =>  $self->{_infra}->{vms}->{$vm_to_migrate_id},
        );
    }

    if (defined $hv_dest_id) {
        $self->_migrateVmModifyInfra(
            vm_id      => $vm_to_migrate_id,
            hv_dest_id => $hv_dest_id->{hv_id},
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


=pod

=begin classdoc

Desc : Process one step of optimisation which try to free one HV
Method 1 : will try to migrate the VMs of the HV which has the less number
of VMs
Method 2 : will try to migrate the VMs of the HV whose larger VM is minimal
(which is called a minimax operator).

The size of the VM is computed as an aggreation of its RAM usage and
its CPU usage

=end classdoc

=cut

sub _optimStep{
    my ($self,%args) = @_;
    my $current_plan    = $args{current_plan};
    my $hv_selected_ids = $args{hv_selected_ids};
    my $methode         = $args{methode};

    my $min_vm_hv;
    if($methode == 1) {
        $min_vm_hv = $self->_findHvIdWithMinNumVms(hvs => $self->{_infra}->{hvs}, hv_selected_ids => $hv_selected_ids);
    }
    elsif($methode == 2) {
        $min_vm_hv = $self->_findHvIdWithMinVmSize(hv_selected_ids => $hv_selected_ids);
    }

    my @hv_selection_ids;

    # Try to empty all the minimal hv
    my $num_failed = 0;
    for my $hv_id (@{$min_vm_hv->{id}}){

        # remove $hv_id to find an other hv to migrate the vm
        # TODO More test too choose between these 2 heuristics :

        # In the loop of same HV size, let the empty HV in available HV or not
        # Yes => Empty HV will receive biggest VM when no more space left from an HV
        # which would not have been able to empty anyway => once this HV used it
        # enables to empty the next HV Or perhaps next HV could have been empty
        #
        # => option selected 

        @hv_selection_ids = grep { $_ != $hv_id } @$hv_selected_ids;

        # No => Decrease the num of free HV => Decrease processing time ?
        # => To study
        #@hv_selection_ids = grep { $_ != $hv_id } @hv_selection_ids;

        $log->debug("List of HVs available to free <$hv_id> : @hv_selection_ids");
        # Migrate all vms of the selected hv

        my @vmlist = @{$self->{_infra}->{hvs}->{$hv_id}->{vm_ids}};
        $log->info("List of VMs to migrate = @vmlist");

        for my $vm_to_migrate_id (@vmlist){
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


=pod

=begin classdoc

    Return a hash table indicating which hypervisors are empty and which hypervisors are not
    empty 

=end classdoc

=cut

sub _separateEmptyHvIds {
    my $self  = shift;
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


=pod

=begin classdoc

    Return id of Hypervisors which have the minimul number of VMs

=end classdoc

=cut

sub _findHvIdWithMinVmSize{
    my ($self,%args) = @_;

    my $hv_selected_ids = $args{hv_selected_ids};

    my $hv_index        = $hv_selected_ids->[0];
    my $vm_ids          = $self->{_infra}->{hvs}->{$hv_index}->{vm_ids};

    my @vm_sizes = map {
        $self->_computeRelativeResourceSize(vm_id => $_);
    } (@$vm_ids);

    my $n_vm             = List::Util::max @vm_sizes;
    my $rep = {
        id    => [$hv_index],
        count => $n_vm,
    };

    for my $hv_index_s (1..@$hv_selected_ids-1){

        my $hv_index        = $hv_selected_ids->[$hv_index_s];
        my $vm_ids          = $self->{_infra}->{hvs}->{$hv_index}->{vm_ids};

        my @vm_sizes = map {
            $self->_computeRelativeResourceSize(vm_id => $_);
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


=pod

=begin classdoc

    Public method calling private method _computeInfraChargeStat

=end classdoc

=cut

sub computeInfraChargeStat{
    my $self = shift;
    return $self->_computeInfraChargeStat();
}


=pod

=begin classdoc

    Compute the average load of the HVs and the num of free HV

=end classdoc

=cut

sub _computeInfraChargeStat{
    my $self = @_;

    my $num_of_hv = (scalar (keys %{$self->{_infra}->{hvs}}));
    my $num_of_empty_hv = 0;
    my $stat;

    $stat->{cpu_p}  = 0;
    $stat->{ram_p}  = 0;

    while (my($hv_id,$v) = each(%{$self->{_infra}->{hvs}})) {
        my @vm_list = @{$self->{_infra}->{hvs}->{$hv_id}->{vm_ids}};
        if (@vm_list == 0) {
            $num_of_empty_hv++;
        }
        else {
            my $size = $self->_getHvSizeOccupied(
                    hv_id => $hv_id,
            );
            $stat->{cpu_p} += $size->{cpu_p};
            $stat->{ram_p} += $size->{ram_p};
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

=pod

=begin classdoc

    Compute the relative size of a vm w.r.t. its hypervisor

=end classdoc

=cut

sub _computeRelativeResourceSize{
    my ($self,%args) = @_;
    my $vm_id = $args{vm_id};
    my $hv_id = $self->_getHvIdFromVmId(vm_id => $vm_id);

    my $cpu_relative = $self->{_infra}->{vms}->{$vm_id}->{cpu} / $self->{_infra}->{hvs}->{$hv_id}->{hv_capa}->{cpu};
    my $ram_relative = $self->{_infra}->{vms}->{$vm_id}->{ram} / $self->{_infra}->{hvs}->{$hv_id}->{hv_capa}->{ram};
    return List::Util::max ($cpu_relative, $ram_relative);
}

=pod

=begin classdoc

    Return the ids of the HV with minimum number of VMs and the value
    
    @return the ids of the HV with minimum number of VMs and the value
    
=end classdoc

=cut

sub _findHvIdWithMinNumVms{
    my ($self, %args) = @_;
    my $hv_selected_ids = $args{hv_selected_ids};

    my $hv_index = $hv_selected_ids->[0];
    my $vm_ids   = $self->{_infra}->{hvs}->{$hv_index}->{vm_ids};

    my $rep = {
        id    => [$hv_index],
        count => scalar @$vm_ids,
    };

    for my $hv_index_s (1..@$hv_selected_ids-1){
        my $hv_index = $hv_selected_ids->[$hv_index_s];
        my $vm_ids   = $self->{_infra}->{hvs}->{$hv_index}->{vm_ids};
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

=pod

=begin classdoc

    Migrate all vms of an hypervisor

    @param hv_id the id of the hypervisor

    @return hash with operation plan and the number of vm remaining

=end classdoc

=cut

sub flushHypervisor {
    my ($self,%args) = @_;
    General::checkParams(args => \%args, required => ['hv_id']);

    $self->{_operationPlan} = [];
    my $flush_results = $self->_getFlushHypervisorPlan(hv_id => $args{hv_id});

    $self->_applyMigrationPlan(
        plan => $flush_results->{operation_plan}
    );

    return { num_failed     => $flush_results->{num_failed},
             operation_plan => $self->{_operationPlan}
           };
}

=pod

=begin classdoc

    Migrate all vms of an hypervisor

    @param hv_id the id of the hypervisor

    @return hash with operation plan and the number of vm remaining

=end classdoc

=cut


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
    
    # Migrate all the vm of the selected hv
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
