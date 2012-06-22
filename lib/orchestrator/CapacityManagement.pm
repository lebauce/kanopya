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

# logger
use Log::Log4perl "get_logger";
my $log = get_logger("administrator");

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
    else{
        General::checkParams(args => \%args, required => ['cluster_id']);
        $self->{_cluster_id}    = $args{cluster_id};
        $self->{_infra}         = $self->_constructInfra();
        $self->{_admin}         = Administrator->new();
        $self->{_operationPlan} = [];
    }
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

    my $cluster = Entity::ServiceProvider::Inside::Cluster->get(id => $self->{_cluster_id});

    #GET LIST OF ALL HV
    my $hvs;
    my $opennebula   = $cluster->getManager(manager_type => 'host_manager');
    my $hypervisors_r = $opennebula->{_dbix}->opennebula3_hypervisors;

    while (my $row = $hypervisors_r->next) {
        my $hypervisor = Entity::Host->get(id => $row->get_column('hypervisor_host_id'));
        my $hv_id = $row->get_column('hypervisor_host_id');
        $hvs->{$hv_id}->{'hv_capa'} = {
            ram => $hypervisor->getHostRAM(),
            cpu => $hypervisor->getHostCORE(),
        };
        $hvs->{$hv_id}->{'vm_ids'} = [];
    }

    my $current_hosts   = $cluster->getHosts(administrator => Administrator->new);
    my $vms;

    $log->info("***INFRA OF".$self->{_cluster_id}."***");

    while( my ($id, $vm) = each %$current_hosts) {
        $vms->{$id}->{ram} = $vm->getHostRAM();
        $vms->{$id}->{cpu} = $vm->getHostCORE();
        $log->info("**** VM ID =***".$vm->getId()."******");
        my $hvid      = $vm->getHyperVisorHostId();

        if(defined $hvs->{$hvid}){
            push @{$hvs->{$hvid}->{'vm_ids'}}, $id;
        }
    }

    my $current_infra = {
        vms => $vms,
        hvs => $hvs,
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

    General::checkParams(args => \%args, required => ['vm_id',
                                                      'hv_id',
                                                      'resource_type',
                                                      'wanted_resource',
                                                      ]);


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
    $log->info("**** [scale-in $resource_type]  Remaining $remaining_resource in HV $hv_id, need $delta more to have $wanted_resource ****");
    if ($remaining_resource < $delta) {
        return 0;
    }
    else{
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
        $log->info("Not enough CPU to migrate VM $vm_id ($ram MB) in HV $hv_id (".$remaining_resources->{ram}." MB)");
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

    $log->debug(Dumper $infra);
    my @hv_selected_ids = $self->_getEmptyHVIds(hvs => $infra->{hvs});
    my $optim;
    my $current_plan = [];
    my $step = 1;
    do{
        $log->info("**STEP $step**\n");
        $optim = $self->_optimStep(
            infra           => $infra,
            hv_selected_ids => \@hv_selected_ids,
            methode         => 2,
            current_plan    => $current_plan,
        );
        $step++;

        @hv_selected_ids = $self->_getEmptyHVIds(hvs => $infra->{hvs});
    }while ($optim == 1);

    $self->_applyMigrationPlan(
        plan => $current_plan
    );
    $log->debug(Dumper $infra->{hvs});
    return $self->{_operationPlan};
}

sub _applyMigrationPlan{
    my ($self,%args) = @_;
    General::checkParams(args => \%args, required => ['plan']);

    my $plan = $args{plan};

    my @simplified_plan_order;
    my $simplified_plan_dest;

    for my $operation (@$plan){
        if(!defined $simplified_plan_dest->{$operation->{vm_id}}){
            $log->debug("xxx $operation->{vm_id} xxx");
            push @simplified_plan_order, $operation->{vm_id};
        }
        $simplified_plan_dest->{$operation->{vm_id}} = $operation->{hv_id};
    }

    $log->debug("*** COMPLETE PLAN : ");
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
    with enough ressource with minimum size (in order to optimize infrastructure usage)


=cut

sub getHypervisorIdForVM{
    my ($self,%args) = @_;
    General::checkParams(args => \%args, required => ['wanted_values']);
    my $wanted_values = $args{wanted_values};
    my $infra = $self->{_infra};
    my @all_hv = keys %{$infra->{hvs}};

    my $hv = $self->_findMinHVidRespectCapa(
        hv_selection_ids => \@all_hv,
        wanted_metrics   => $wanted_values,
        infra            => $infra,
    );
    $log->info(Dumper $hv);
    return $hv->{hv_id};
}

=head2 scaleMemoryHost

    Class : Public

    Desc : Try to scale the memory of a VM.
    The increasing contains 3 steps :
    1. Increases the size if the current HV of the VM contains enough ressource
    2. Migrate the VM in a HV with enought space if the VM does not
       contain enough ressource
    3. Migrate another VM of the same HV which free enough space for the scale-in


=cut

sub scaleMemoryHost{
    my ($self,%args) = @_;
    General::checkParams(args => \%args, required => ['host_id','memory']);

     my $sign = substr($args{memory},0,1); # get the first value
     my $mem_input;

     if($sign eq '+' || $sign eq '-'){
         $mem_input = substr $args{memory},1; # remove sign
     } else {
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
    }else{
        $mem_input *= 1024 * 1024; #GIVEN IN MB
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
        $log->warn("*** CANNOT SCALE RAM TO A NEGATIVE VALUE (typed : $args{memory})*** ");
    }
    elsif ($memory > 4096*1024*1024 ) { # WARNING TODO : UNHARCODE 4096 which corresponds to the maximum defined in the VM Template
            $self->{_admin}->addMessage(
                                from    => 'Capacity Management',
                                level   => 'info',
                                content => "Cannot scale to more than 4096 MB (typed : $args{memory})",
                             );
        $log->warn("*** CANNOT SCALE RAM TO MORE THAN 4096 MB (typed : $args{memory})*** ");
    }
    else {
        my @hv_selection_ids = keys %{$self->{_infra}->{hvs}};
        $log->info("Call scaleMemoryMetric for host $args{host_id} and new value = $args{memory}");
        $self->_scaleMetric(
            infra            => $self->{_infra},
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
    1. Increases the size if the current HV of the VM contains enough ressource
    2. Migrate the VM in a HV with enought space if the VM does not
       contain enough ressource
    3. Migrate another VM of the same HV which free enough space for the scale-in


=cut


sub scaleCpuHost{
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => ['host_id','vcpu_number']);

    my @hv_selection_ids = keys %{$self->{_infra}->{hvs}};
    if($args{vcpu_number} =~ /\D/){
        $self->{_admin}->addMessage(
                            from    => 'Capacity Management',
                            level   => 'info',
                            content => "Wrong format for scale in cpu value (typed : $args{vcpu_number})",
                         );
        $log->warn("*** WRONG FORMAT FOR CPU VALUE (typed : $args{vcpu_number}) *** ");
    }
    elsif($args{vcpu_number} <= 0 ){
        $self->{_admin}->addMessage(
                             from    => 'Capacity Management',
                             level   => 'info',
                             content => "Scale in cpu value must be strictly positive (typed : $args{vcpu_number})",
                         );
        $log->warn("*** CANNOT SCALE CPU TO A NEGATIVE VALUE (typed : $args{vcpu_number}) *** ");
    }
    elsif ($args{vcpu_number} > 4 ) { # WARNING TODO : UNHARCODE 4 which corresponds to the maximum defined in the VM Template
            $self->{_admin}->addMessage(
                                from    => 'Capacity Management',
                                level   => 'info',
                                content => "Cannot scale to more than 4 CPU (typed : $args{vcpu_number})",
                             );
        $log->warn("*** CANNOT SCALE CPU TO MORE THAN 4 (typed : $args{vcpu_number}) *** ");
    }
    else {
        $log->info("Call scaleCpuMetric for host $args{host_id} and new value = $args{vcpu_number}");
        $self->_scaleMetric(
            infra            => $self->{_infra},
            vm_id            => $args{host_id},
            new_value        => $args{vcpu_number},
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
    my $infra            = $args{infra};

    my $vm_id            = $args{vm_id};
    my $new_value        = $args{new_value};

    my $hv_selection_ids = $args{hv_selection_ids};

    $log->info(Dumper $infra);

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
                infra             => $infra,
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
                    memory  => $new_value / (1024*1024),
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
        $size->{ram} += $infra->{vms}->{$vm_id}->{ram};
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

    my $remaining_ram = $all_the_ram - $size->{ram};


    my $remaining_cpu = $all_the_cpu - $size->{cpu};

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
                    memory  => $new_value / (1024*1024),
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
            splice @{$hv->{vm_ids}}, $index_search,1;
        }
    }

    push @{$hvs->{$hv_dest_id}->{vm_ids}}, $vm_id;

    $log->info("Infra modified => migration $vm_id to $hv_dest_id");
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
    my $infra            = $args{infra};
    my $hv_selection_ids = $args{hv_selection_ids};
    my $scale_metric     = $args{scale_metric};

    my $wanted_metrics  = clone($infra->{vms}->{$vm_id});
    $wanted_metrics->{$scale_metric} = $new_value;

    my $hv_dest_id = $self->_findMinHVidRespectCapa(
        infra            => $infra,
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
    my $hvs_selection_ids = $args{hv_selection_ids};
    my $wanted_metrics    = $args{wanted_metrics};
    my $infra             = $args{infra};


    my $rep;
    for my $hv_id (@$hvs_selection_ids){

        my $size_remaining = $self->_getHvSizeRemaining(
            infra => $infra,
            hv_id => $hv_id,
        );

        my $total_score = $size_remaining->{cpu_p} + $size_remaining->{ram_p};

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


    $log->info("Remaining size = $remaining_size->{$scale_metric}, Need size = $delta, potential VM to scale (according to $scale_metric) = @other_vms");


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
            infra            => $infra,
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


        $log->debug("HV available to free $hv_id : @hv_selection_ids");
        # MIGRATE ALL VM OF THE SELECTED HV
        my @vmlist = @{$infra->{hvs}->{$hv_id}->{vm_ids}};
        $log->info("__ vmlist = @vmlist");

        for my $vm_to_migrate_id (@vmlist){
            $log->info("__ Processing VM $vm_to_migrate_id");
            my $hv_dest_id = $self->_findMinHVidRespectCapa(
                infra            => $infra,
                hv_selection_ids => \@hv_selection_ids,
                wanted_metrics   => $infra->{vms}->{$vm_to_migrate_id},
            );

            if(defined $hv_dest_id){
                $log->info("___Enqueue in Plan migration of VM $vm_to_migrate_id");
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

=head2 _getEmptyHVIds

    Class : Private

    Desc : Return list of id of empty HVs

=cut

sub _getEmptyHVIds {
    my ($self,%args) = @_;
    my $hvs = $args{hvs};
    my @empty_hv_ids;

    for my $hv_index (keys %$hvs){
        if(scalar @{$hvs->{$hv_index}->{vm_ids}} > 0){
            push @empty_hv_ids, $hv_index;
        }
    }
    return @empty_hv_ids;
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

    Desc : Compute the relative value of resource

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
1;
