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

use base CapacityManager;

use strict;
use warnings;
use Data::Dumper;
use Clone;
use List::Util;
use Entity;
use EEntity;
use Message;
use Entity::ServiceProvider::Cluster;
# logger
use Log::Log4perl "get_logger";
my $log = get_logger("");


=pod

=begin classdoc

Desc : Main entrance to optimize infra. Will call private methode _optimstep
until optimstep cannot improve the infra (which means cannot empty an HV
from all its VMs).

@return Plan formed by a list of Migration Operation to enqueue

=end classdoc

=cut

sub optimIaas {
    my $self = shift;

    $self->{_operationPlan} = [];
    my $hv_selected_ids = $self->_separateEmptyHvIds()->{non_empty_hv_ids};
    my $optim;
    my $current_plan = [];
    my $step = 1;
    do{
        $optim = $self->_optimStep(
            hv_selected_ids => $hv_selected_ids,
            methode         => 2,
            current_plan    => $current_plan,
        );
        $step++;

        $hv_selected_ids = $self->_separateEmptyHvIds()->{non_empty_hv_ids};
    } while ($optim == 1);

    $self->_applyMigrationPlan(
        plan                 => $current_plan,
        empty_master_allowed => 0,
    );

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
    General::checkParams(args => \%args, required => ['plan', 'empty_master_allowed']);

    my @simplified_plan_order; # The order of VM migration
    my $simplified_plan_dest;  # The destination of the VM

    #Check each operation and keep the last one for each VM
    for my $operation (@{$args{plan}}) {
        if (! defined $simplified_plan_dest->{$operation->{vm_id}}) {
            push @simplified_plan_order, $operation->{vm_id};
        }
        $simplified_plan_dest->{$operation->{vm_id}} = $operation->{hv_id};
    }

    $log->debug("Complete Plan : ");
    $log->debug(Dumper $args{plan});
    $log->info("Simplified plan migration order @simplified_plan_order");
    $log->info(Dumper $simplified_plan_dest);

    for my $vm_id (@simplified_plan_order) {
        $self->_migrateVmOrder(
            vm_id => $vm_id,
            hv_id => $simplified_plan_dest->{$vm_id},
        );
    }
}


=pod

=begin classdoc

Find hypervisors for a list of vm with their ressources

@param resources hash resource values of the the VMs

@return hash associating a hypervisor id to each vm id. The hypervisor id is undef when no hypervisor
        has been found for the vm

=end classdoc

=cut


sub getHypervisorIdsForVMs {
    my ($self,%args) = @_;
    General::checkParams(args => \%args, required => ['vms_resources_hash']);

    my %rep;
    while (my ($vm_id, $resources) = each (%{$args{vms_resources_hash}})) {
        my $hv_id = $self->getHypervisorIdForVM(resources => $resources);
        if (defined $hv_id) {
            $self->{_infra}->{hvs}->{$hv_id}->{vm_ids}->{$vm_id} = 1;
            $self->{_infra}->{vms}->{$vm_id} = $resources;
            $rep{$vm_id} = $hv_id;
        }
        else {
            $log->warn("No free hypervisor has been found to host vm <$vm_id>");
        }
    }
    return \%rep;
}


=pod

=begin classdoc

Return the hypervisor ID in which to place the vm. Choose the hypervisor with enough resource
with minimum size (in order to optimize infrastructure usage)

@param wanted_values the resource values of the VM

@return The hypervisor id

=end classdoc

=cut

sub getHypervisorIdForVM {
    my ($self,%args) = @_;
    General::checkParams(args => \%args, required => ['resources']);

    # Option : blacklisted_hv_ids
    # Option : selected_hv_ids
    # Wanted values : { cpu => num_of_proc, ram => value_in_bytes}

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
        resources        => $args{resources},
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

Migrate another VM in order to relieve hypervisor and allow scale for the current vm

@param vm_id id of the vm
@param scale_metric the metric ('cpu' or 'ram')
@param new_value the value of the metric

@return 1 if operation succeed, 0 if it failed

=end classdoc

=cut

sub _migrateOtherVmsToScale{
    my ($self,%args) = @_;
    General::checkParams(args => \%args, required => ['hv_selection_ids',
                                                      'vm_id',
                                                      'new_value',
                                                      'scale_metric']);

    my $vm_id            = $args{vm_id};
    my $new_value        = $args{new_value};
    my $scale_metric     = $args{scale_metric};
    my $hv_selection_ids = $args{hv_selection_ids};

    my $hv_id            = $self->_getHvIdFromVmId(vm_id => $vm_id);

    my $delta            = $new_value - $self->{_infra}->{vms}->{$vm_id}->{resources}->{$scale_metric};
    my $remaining_size   = $self->_getHvSizeRemaining(
                               hv_id => $hv_id,
                           );

    #Other vm which could be migrated instead of current vm (according to analyzed metric)
    my @other_vms = grep {
                        $self->{_infra}->{vms}->{$_}->{resources}->{$scale_metric} + $remaining_size->{$scale_metric} >= $delta   #otherwise too small
                        && $self->{_infra}->{vms}->{$_}->{resources}->{$scale_metric} < $new_value #otherwise the other one could have been migrated
                        &&  $_ != $vm_id
                    } keys %{$self->{_infra}->{hvs}->{$hv_id}->{vm_ids}};


    $log->debug("HV <$hv_id> Remaining size = $remaining_size->{$scale_metric}, Need size = $delta, potential VM to scale (according to $scale_metric) => VM_ids :  @other_vms");


    #Find one with other metric OK
    my @sorted_vms = sort {
        $self->{_infra}->{vms}->{$b}->{resources}->{$scale_metric} <=> $self->{_infra}->{vms}->{$a}->{resources}->{$scale_metric}
    } @other_vms;

    my $hv_dest_id;
    my $vm_to_migrate_id;

    while ((!defined $hv_dest_id) && (scalar @sorted_vms > 0)) {
        $vm_to_migrate_id = pop @sorted_vms;
        $log->debug("Check $vm_to_migrate_id migration possibility...");

        # remove vm HV from selection

        my $vm_hv_id  = $self->_getHvIdFromVmId(
                            vm_id => $vm_to_migrate_id,
                        );

        my @selection = grep {$_ != $vm_hv_id} @$hv_selection_ids;

        $log->debug(Dumper \@selection);

        $hv_dest_id = $self->_findMinHVidRespectCapa(
            hv_selection_ids => \@selection,,
            resources       =>  $self->{_infra}->{vms}->{$vm_to_migrate_id}->{resources},
        );
    }

    if (defined $hv_dest_id->{hv_id}) {
        $self->_migrateVmModifyInfra(
            vm_id => $vm_to_migrate_id,
            hv_id => $hv_dest_id->{hv_id},
        );

        $self->_migrateVmOrder(
            vm_id => $vm_to_migrate_id,
            hv_id => $hv_dest_id->{hv_id},
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

sub _optimStep {
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

        my @vmlist = keys %{$self->{_infra}->{hvs}->{$hv_id}->{vm_ids}};
        $log->debug("List of VMs to migrate = @vmlist");

        for my $vm_to_migrate_id (@vmlist){
            my $hv_dest_id = $self->_findMinHVidRespectCapa(
                hv_selection_ids => \@hv_selection_ids,
                resources        => $self->{_infra}->{vms}->{$vm_to_migrate_id}->{resources},
            );

            my $msg;
            if (defined $hv_dest_id->{hv_id}) {
                $msg = "Enqueue VM <$vm_to_migrate_id> migration";
                $self->_migrateVmModifyInfra(
                    vm_id => $vm_to_migrate_id,
                    hv_id => $hv_dest_id->{hv_id},
                );
                push @$current_plan, {vm_id => $vm_to_migrate_id, hv_id => $hv_dest_id->{hv_id}};
            }
            else{
                $msg = "___Cannot migrate VM $vm_to_migrate_id";
                $num_failed++;
            }
            $log->debug($msg);
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
        if(scalar keys %{$hvs->{$hv_index}->{vm_ids}} > 0){
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

    my @vm_sizes = map {
        $self->_computeRelativeResourceSize(vm_id => $_);
    } (keys %{$self->{_infra}->{hvs}->{$hv_index}->{vm_ids}});

    my $n_vm = List::Util::max @vm_sizes;
    my $rep = {
        id    => [$hv_index],
        count => $n_vm,
    };

    for my $hv_index_s (1..@$hv_selected_ids-1){

        my $hv_index        = $hv_selected_ids->[$hv_index_s];

        my @vm_sizes = map {
            $self->_computeRelativeResourceSize(vm_id => $_);
        } (keys %{$self->{_infra}->{hvs}->{$hv_index}->{vm_ids}});

        my $n_vm            = List::Util::max @vm_sizes;

        if ($n_vm< $rep->{count}){
            $rep->{count} = $n_vm;
            $rep->{id}    = [$hv_index];
        }
        elsif ($n_vm == $rep->{count}){
            push @{$rep->{id}}, $hv_index;
        }
    }
    $log->debug("Select minimax hv: value = $rep->{count} ; id: @{$rep->{id}})");
    return $rep;
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

    my $cpu_relative = $self->{_infra}->{vms}->{$vm_id}->{resources}->{cpu} / $self->{_infra}->{hvs}->{$hv_id}->{resources}->{cpu};
    my $ram_relative = $self->{_infra}->{vms}->{$vm_id}->{resources}->{ram} / $self->{_infra}->{hvs}->{$hv_id}->{resources}->{ram};
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

    my $rep = {
        id    => [$hv_index],
        count => scalar keys %{$self->{_infra}->{hvs}->{$hv_index}->{vm_ids}},
    };

    for my $hv_index_s (1..@$hv_selected_ids-1){
        my $hv_index = $hv_selected_ids->[$hv_index_s];

        my $n_vm = scalar (keys %{$self->{_infra}->{hvs}->{$hv_index}->{vm_ids}});
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

    if (not defined $self->{_infra}->{hvs}->{$args{hv_id}}) {
        my $error = "Hypervisor <$args{hv_id}> is not managed by the capacity manager (may be not active or not up)";
        throw Kanopya::Exception(error => $error);
    }

    $self->{_operationPlan} = [];

    my $flush_results = $self->flushHypervisorPlan(%args);

    my @operation_plan = ();

    while (my($k,$v) = each(%{$flush_results->{migration}})) {
        push @operation_plan, {vm_id => $k, hv_id => $v};
    }

    $self->_applyMigrationPlan(
        plan                 => \@operation_plan,
        empty_master_allowed => 1,
    );

    return { num_failed     => $flush_results->{num_failed},
             operation_plan => $self->{_operationPlan}
           };

}

sub _sortVmsDesc {
    my ($self,%args) = @_;
    General::checkParams(args => \%args, required => ['vm_ids']);

    my $max_cpu = 0;
    my $max_ram = 0;

    for my $vm_id (@{$args{vm_ids}}) {
        if ($self->{_infra}->{vms}->{$vm_id}->{resources}->{cpu} > $max_cpu) {
            $max_cpu = $self->{_infra}->{vms}->{$vm_id}->{resources}->{cpu};
        }

        if ($self->{_infra}->{vms}->{$vm_id}->{resources}->{ram} > $max_ram) {
            $max_ram = $self->{_infra}->{vms}->{$vm_id}->{resources}->{ram};
        }
    }

    my @vms_sorted = sort { ( $self->{_infra}->{vms}->{$b}->{resources}->{ram} / $max_ram +
                              $self->{_infra}->{vms}->{$b}->{resources}->{cpu} / $max_cpu ) <=>
                            ( $self->{_infra}->{vms}->{$a}->{resources}->{ram} / $max_ram +
                              $self->{_infra}->{vms}->{$a}->{resources}->{cpu} / $max_cpu )
                     } @{$args{vm_ids}};

    return \@vms_sorted;
}

=pod

=begin classdoc

    Migrate all vms of an hypervisor

    @param hv_id the id of the hypervisor

    @return hash with operation plan and the number of vm remaining

=end classdoc

=cut


sub flushHypervisorPlan {
    my ($self,%args) = @_;
    General::checkParams(args => \%args, required => ['hv_id']);

    my $hv_id = $args{hv_id};
    # use_empty_hv = 1 in order to allow migration of all the vms in empty hv

    my $hv_selected_ids;

    if (defined $args{use_empty_hv} && $args{use_empty_hv} == 1) {
        $hv_selected_ids = $self->_separateEmptyHvIds()->{non_empty_hv_ids};
    }
    else {
        $hv_selected_ids = $self->_separateEmptyHvIds()->{hv_ids};
    }

    # Just remove current hv it self
    my @hv_selection_ids = grep { $_ != $hv_id } @$hv_selected_ids;
    $log->debug("List of HVs available to free <$hv_id> : @hv_selection_ids");

    # Migrate all the vm of the selected hv
    my @vmlist = keys %{$self->{_infra}->{hvs}->{$hv_id}->{vm_ids}};

    my $sorted_vm_list = $self->_sortVmsDesc(vm_ids => \@vmlist);

    $log->debug("List of VMs to migrate = @$sorted_vm_list");

    my %migrations;
    my $num_failed      = 0;

    for my $vm_to_migrate_id (@$sorted_vm_list) {

        my $hv_dest_id = $self->_findMinHVidRespectCapa(
            hv_selection_ids => \@hv_selection_ids,
            resources        => $self->{_infra}->{vms}->{$vm_to_migrate_id}->{resources},
        );

        if (defined $hv_dest_id->{hv_id}) {
            $log->debug("Enqueue VM <$vm_to_migrate_id> migration");
            $self->_migrateVmModifyInfra(
                vm_id => $vm_to_migrate_id,
                hv_id => $hv_dest_id->{hv_id},
            );
            $migrations{$vm_to_migrate_id} = $hv_dest_id->{hv_id};
        }
        else{
            $log->debug("Cannot migrate VM $vm_to_migrate_id");
            $num_failed++;
        }
    }

    return {
        migrations => \%migrations,
        num_failed => $num_failed,
    };
};


=pod

=begin classdoc

    Find a new hypervisor for each vms of a given hypervisor

    @param hv_id the id of the hypervisor

    @return hash with a new hypervisor for each vms

=end classdoc

=cut

sub resubmitHypervisor {
    my ($self,%args) = @_;
    General::checkParams(args => \%args, required => ['hv_id']);

    my %resources;
    my $deleted_hv;
    if (defined $self->{_infra}->{hvs}->{$args{hv_id}}) {
        for my $vm_id (keys %{$self->{_infra}->{hvs}->{$args{hv_id}}->{vm_ids}}) {
            my $vm_resources = $self->{_infra}->{vms}->{$vm_id}->{resources};
            $resources{$vm_id} = { ram => $vm_resources->{ram},
                                           cpu => $vm_resources->{cpu}};
        }
        # Do not resubmit on same hypervisor
        $deleted_hv = delete $self->{_infra}->{hvs}->{$args{hv_id}};
    }
    else {
        # Capacity manager do not manage broken or unactive hypervisor.
        # but resubmit is allowed in broken hypervisors

        my $hypervisor = Entity->get(id => $args{hv_id});

        for my $vm ($hypervisor->getVms()) {
            $resources{$vm->id} = {ram => $vm->host_ram, cpu => $vm->host_core,};
        }
    }

    my $return = $self->getHypervisorIdsForVMs(vms_resources_hash => \%resources);
    return $return;
}

1;
