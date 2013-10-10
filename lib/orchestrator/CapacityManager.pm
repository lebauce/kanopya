#    Copyright © 2013 Hedera Technology SAS
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

TODO

=end classdoc
=cut

package CapacityManager;

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
    if (defined $args{infra}) {
        $self->{_infra} = $args{infra};
        return $self;
    }

    General::checkParams(args => \%args, required => [ 'cloud_manager' ]);

    $self->{_cloud_manager} = $args{cloud_manager};

    $self->{_infra} = $self->_constructInfra();
    $self->_applyOvercommitmentFactors();

    return $self;
}


=pod

=begin classdoc

Construct the infrastructure data structure used in the class by algorithms.
Use the cloud manager to get the infrastructure information

@return constructed infrastructure.

=end classdoc

=cut

sub _constructInfra {
    my $self = shift;

    # Get the list of all hypervisors
    my @hypervisors_r = $self->{_cloud_manager}->activeAndInHypervisors();
    my $master_hv;

    my ($hvs, $vms);
    for my $hypervisor (@hypervisors_r) {
        $hvs->{$hypervisor->id} = {
            resources => {
                ram => $hypervisor->host_ram,
                cpu => $hypervisor->host_core,
            },
        };

        my @hypervisor_vms = $hypervisor->getVms();
        for my $vm (@hypervisor_vms) {
            $vms->{$vm->id} = {
                resources => {
                    ram   => $vm->host_ram,
                    cpu   => $vm->host_core,
                },
                hv_id => $hypervisor->getId,
            };
            $hvs->{$hypervisor->getId}->{vm_ids}->{$vm->id} = 1;
        }
    }

    my $current_infra = {
        vms => $vms,
        hvs => $hvs
    };

    return $current_infra;
}


=pod

=begin classdoc

Desc : Apply overcommitment factors to all the hypervisors' resources

=end classdoc

=cut

sub _applyOvercommitmentFactors {
    my $self = shift;

    # Get available memory for all cloud manager hosts (hypervisors)
    my $overcommitment_factors =  $self->{_cloud_manager}->getOvercommitmentFactors();
    $log->debug('Overcommitment cpu    factor <'
                .($overcommitment_factors->{overcommitment_cpu_factor}).'>');
    $log->debug('Overcommitment memory factor <'
                .($overcommitment_factors->{overcommitment_memory_factor}).'>');

   for my $hv_id (keys %{$self->{_infra}->{hvs}}) {
       my $hv_resources = $self->{_infra}->{hvs}->{$hv_id}->{resources};

       $hv_resources->{cpu} *= $overcommitment_factors->{overcommitment_cpu_factor};
       $hv_resources->{ram} *= $overcommitment_factors->{overcommitment_memory_factor};
   }
}

=pod

=begin classdoc

Desc : Optimize infrastructure by migrating vms in a few hypervisors as possible.
@return Plan formed by a list of Migration Operation to enqueue

=end classdoc

=cut

sub optimIaas {
    my $self = shift;
    throw Kanopya::Exception::NotImplemented();
}


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
    throw Kanopya::Exception::NotImplemented();
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
    throw Kanopya::Exception::NotImplemented();
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
    throw Kanopya::Exception::NotImplemented();
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
    throw Kanopya::Exception::NotImplemented();
}


sub _migrateOtherVmsToScale {
    my ($self,%args) = @_;
    General::checkParams(args => \%args, required => [ 'vm_id', 'new_value', 'scale_metric' ]);
    throw Kanopya::Exception::NotImplemented();
}
=pod

=begin classdoc

Convert internal infrastructure into JSON structure. RAM is givent in MB

@return corresponding JSON structure

=end classdoc

=cut

sub _infraToJson {
    my ($self,%args) = @_;
    General::checkParams(args => \%args, optional => {'infra'  => undef});

    if (! defined $args{infra}) {
        $args{infra} = Clone::clone($self->{_infra});
    }

    while (my ($vm_id,$vm_info) = each (%{$args{infra}->{vms}})) {
        if (! defined $vm_info->{hv_id}) {
            $vm_info->{hv_id} = -1;
        }
    }

    # Convert RAM into MB
    map {$_->{resources}->{ram} >>= 20} values %{$args{infra}->{vms}};
    map {$_->{resources}->{ram} >>= 20} values %{$args{infra}->{hvs}};

    return JSON->new->utf8->encode($args{infra});
}


=pod

=begin classdoc

Write JSON structure into a temp file and return the file path

@return file path

=end classdoc

=cut

sub _jsonToTempFile {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => [ 'json' ]);

    (my $result_file, my $result_filename) = File::Temp::tempfile("result.jsonXXXXX", TMPDIR => 1);
    print $result_file $args{json};
    return $result_filename;
}


=pod

=begin classdoc

Write internal infrastructure into a temp file as a JSON structure

@return file path

=end classdoc

=cut

sub _infraToTempFile {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, optional => {'infra' => undef});

    my $infra_to_json = $self->_infraToJson(%args);
    return $self->_jsonToTempFile(json => $infra_to_json);
}


sub _resourcesToJson {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => [ 'resources' ],
                                         optional => {ram_in_MB => 0});

    if ($args{ram_in_MB} != 0) {
        for my $resource (@{$args{resources}}) {
            $resource->{ram} >>= 20
        }
    }

    my $resources_json = JSON->new->utf8->encode($args{resources});
    $resources_json =~ s/"/\\"/g; # Escape double quotes

    return $resources_json;
}


=pod

=begin classdoc

Convert VM resources hash into JSON structure.

@param resources hash ref {ram => 'ram_value', cpu => 'cpu_value'} the ram and cpu wanted for the vm

@return corresponding JSON structure

=end classdoc

=cut

sub _resourcesToJson {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'resources' ],
                                         optional => {ram_in_MB => 0});

    if ($args{ram_in_MB} != 0) {
        $args{resources}->{ram} >>= 20; # Convert to MB
    }
    my $resources_json = JSON->new->utf8->encode($args{resources});
    $resources_json =~ s/"/\\"/g; # Escape double quotes
    return $resources_json;
}


=pod

=begin classdoc

Add a migration Operation in internal operation plan

@param vm_id id of the vm
@param hv_id the id of destination hypervisor

=end classdoc

=cut

sub _migrateVmOrder {
    my ($self,%args) = @_;
    General::checkParams(args => \%args, required => [ 'vm_id', 'hv_id' ]);

    push @{$self->{_operationPlan}}, {
        type => 'MigrateHost',
        priority => 1,
        params => {
           context => {
               vm   => Entity->get(id => $args{vm_id}),
               host => Entity->get(id => $args{hv_id}),
           }
        }
    };

    $log->debug("Enqueuing MigrateHost of host $args{vm_id} to hypervisor $args{hv_id}");
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
    General::checkParams(args => \%args, required => [ 'vm_id' ]);
    return $self->{_infra}->{vms}->{$args{vm_id}}->{hv_id};
}

sub _addVmInHV {
    my ($self,%args) = @_;
    General::checkParams(args => \%args, required => [ 'vm_id', 'hv_id' ]);

    $self->{_infra}->{hvs}->{$args{hv_id}}->{vm_ids}->{$args{vm_id}} = 1;
    $self->{_infra}->{vms}->{$args{vm_id}}->{hv_id} = $args{hv_id}
}


=pod

=begin classdoc

Modify the internal infrastructure when the algorithms plan a migration operation

@param vm_id id of the vm
@param hv_id id of destination hypervisor

=end classdoc

=cut

sub _migrateVmModifyInfra{
    my ($self,%args) = @_;
    General::checkParams(args => \%args, required => [ 'vm_id', 'hv_id' ]);

    my $vm_id      = $args{vm_id};
    my $hv_dest_id = $args{hv_id};

    my $hv_from_id = $self->_getHvIdFromVmId(vm_id => $vm_id);

    $self->_removeVmFromHV(vm_id => $vm_id, hv_id => $hv_from_id);
    $self->_addVmInHV(vm_id => $vm_id, hv_id => $hv_dest_id);

    $log->debug("Infra modified => migration <$vm_id> (ram: "
                .($self->{_infra}->{vms}->{$vm_id}->{resources}->{ram})
                .") from <$hv_from_id> to <$hv_dest_id>");

    # Modify available memory
    if (defined $self->{_hvs_mem_available}) {
        $self->{_hvs_mem_available}->{$hv_dest_id} -= $self->{_infra}->{vms}->{$vm_id}->{resources}->{ram};
        $self->{_hvs_mem_available}->{$hv_from_id} += $self->{_infra}->{vms}->{$vm_id}->{resources}->{ram};
    }

    # Modify RAM effective when overcommitment
    if( defined $self->{_infra}->{hvs}->{$hv_from_id}->{resources}->{ram_effective}) {

        $self->{_infra}->{hvs}->{$hv_dest_id}->{resources}->{ram_effective} -= $self->{_infra}
                                                                                    ->{vms}
                                                                                    ->{$vm_id}
                                                                                    ->{resources}
                                                                                    ->{'ram_effective'};

        $self->{_infra}->{hvs}->{$hv_from_id}->{resources}->{ram_effective} += $self->{_infra}
                                                                                    ->{vms}
                                                                                    ->{$vm_id}
                                                                                    ->{resources}
                                                                                    ->{'ram_effective'};
    }
}


sub _removeVmFromHV {
    my ($self,%args) = @_;
    General::checkParams(args => \%args, required => [ 'vm_id' ], optional => {hv_id => undef, infra => undef});

    $args{hv_id} = $args{hv_id} || $self->_getHvIdFromVmId(vm_id => $args{vm_id});
    $args{infra} = $args{infra} || $self->{_infra};

    if ($args{infra}->{vms}->{$args{vm_id}}->{hv_id} != $args{hv_id}) {
        my $error = "Hypervisor <$args{hv_id}> does not match vm <$args{vm_id}> hv id (<".$args{infra}->{vms}->{$args{vm_id}}->{hv_id}.">)";
        throw Kanopya::Exception(error => $error);
    }

    if (defined $args{infra}->{hvs}->{$args{hv_id}}->{vm_ids}->{$args{vm_id}}) {
        delete $args{infra}->{hvs}->{$args{hv_id}}->{vm_ids}->{$args{vm_id}}
    }
    else {
        my $error = "Vm <$args{vm_id}> is not on hypervisor <$args{hv_id}> vm list";
        throw Kanopya::Exception(error => $error);
    }

    $args{infra}->{vms}->{$args{vm_id}}->{hv_id} = undef;
    return $args{hv_id};
}


=pod

=begin classdoc

Delete a virtual machine from the internal infrastructure

@param vm_id id of the vm to demete

=end classdoc

=cut

sub _removeVmfromInfra {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => ['vm_id']);

    if (defined $self->{_infra}->{vms}->{$args{vm_id}}) {
        my $hv_id = $self->{_infra}->{vms}->{$args{vm_id}}->{hv_id};
        delete $self->{_infra}->{hvs}->{$hv_id}->{vm_ids}->{$args{vm_id}};
        delete $self->{_infra}->{vms}->{$args{vm_id}};
    }
}


=pod

=begin classdoc

Return the hypervisor ID in which to re-place the vm. Choose the hypervisor with enough resource
with minimum size (in order to optimize infrastructure usage)

@param wanted_values the resource values of the VM

@return The hypervisor id

=end classdoc

=cut

sub getHypervisorIdResubmitVM {
    my ($self,%args) = @_;
    General::checkParams(args => \%args, required => ['vm_id', 'wanted_values']);

    # Remove me from present vm
    $self->_removeVmfromInfra(vm_id => $args{vm_id});
    return $self->getHypervisorIdForVM(vm_id => $args{vm_id}, resources => $args{wanted_values});
}


=pod

=begin classdoc

Check if a migration is authorized w.r.t. the VM resources and the destination HV resources.

@param vm_id id of the vm to migrate
@param hv_id id of the destination hypervisor

@return 1 if migration is possible, return 0 if some resources are missing

=end classdoc

=cut

sub isMigrationAuthorized {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => ['vm_id','hv_id']);

    my $vm_id = $args{vm_id};
    my $hv_id = $args{hv_id};

    if (! defined $self->{_infra}->{hvs}->{$hv_id}) {
        return {
            authorization => 0,
            error         => "Hypervisor [$hv_id] is either not up or not an active host of the cloud manager",
        };
    }

    my @resources = keys %{$self->{_infra}->{vms}->{$vm_id}->{resources}};

    my $remaining_resources = $self->_getHvSizeRemaining(hv_id => $hv_id);

    for my $resource (@resources) {
        $log->debug("Check $resource, good if :  "
                    .$self->{_infra}->{vms}->{$vm_id}->{resources}->{$resource}
                    .' < '.$remaining_resources->{$resource});

        if ($self->{_infra}->{vms}->{$vm_id}->{resources}->{$resource} > $remaining_resources->{$resource}) {
            my $error = "Migration refused : not enough $resource to migrate vm [$vm_id] ("
                         .$self->{_infra}->{vms}->{$vm_id}->{resources}->{$resource}
                         .") in hypervisor [$hv_id] (".$remaining_resources->{$resource};

            return {
                authorization => 0,
                error         => $error,
            };
        }
    }

    return {
        authorization => 1,
    };
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
    General::checkParams(args => \%args, required => ['hv_id']);

    my $hv_id        = $args{hv_id};

    my $size = $self->_getHvSizeOccupied(hv_id => $hv_id);

    my $all_the_ram   = $self->{_infra}->{hvs}->{$hv_id}->{resources}->{ram};
    my $all_the_cpu   = $self->{_infra}->{hvs}->{$hv_id}->{resources}->{cpu};

    my $remaining_cpu = $all_the_cpu - $size->{cpu};
    my $remaining_ram;

    $remaining_ram = (defined $self->{_hvs_mem_available}) ? $self->{_hvs_mem_available}->{$hv_id}
                                                           : $all_the_ram - $size->{ram};

    my $size_rem = {
        ram           => $remaining_ram,
        cpu           => $remaining_cpu,
        ram_p         => $remaining_ram / $all_the_ram,
        cpu_p         => $remaining_cpu / $all_the_cpu,
        ram_effective => $self->{_infra}->{hvs}->{$hv_id}->{resources}->{ram_effective},
    };

    if (defined  $self->{_infra}->{hvs}->{$hv_id}->{resources}->{ram_free_effective}) {
       $size_rem->{ram_free_effective} = $self->{_infra}->{hvs}->{$hv_id}->{resources}->{ram_free_effective};
    }

    return $size_rem;
}


=pod

=begin classdoc

Return occupied size (RAM and CPU) of a hypervisor.

@param hv_id the hypervisor id

@return Occupied size of the hypervisor

=end classdoc

=cut

sub _getHvSizeOccupied {
    my ($self,%args) = @_;
    General::checkParams(args => \%args, required => ['hv_id']);

    my $hv_id = $args{hv_id};
    my $size  = {cpu => 0, ram => 0};

    for my $vm_id (keys %{$self->{_infra}->{hvs}->{$hv_id}->{vm_ids}}) {
        $size->{cpu} += $self->{_infra}->{vms}->{$vm_id}->{resources}->{cpu};
        $size->{ram} += $self->{_infra}->{vms}->{$vm_id}->{resources}->{ram};
    }

    my $all_the_ram  = $self->{_infra}->{hvs}->{$hv_id}->{resources}->{ram};
    my $all_the_cpu  = $self->{_infra}->{hvs}->{$hv_id}->{resources}->{cpu};

    $size->{cpu_p} = $size->{cpu} / $all_the_cpu;
    $size->{ram_p} = $size->{ram} / $all_the_ram;

    return $size;
}


=pod

=begin classdoc

    Compute the average load of the HVs and the num of free HV

=end classdoc

=cut

sub _computeInfraChargeStat {
    my $self = shift;

    my $num_of_hv = (scalar (keys %{$self->{_infra}->{hvs}}));
    my $num_of_empty_hv = 0;
    my $stat;

    $stat->{cpu_p}  = 0;
    $stat->{ram_p}  = 0;

    while (my($hv_id,$v) = each(%{$self->{_infra}->{hvs}})) {
        my @vm_list = keys %{$self->{_infra}->{hvs}->{$hv_id}->{vm_ids}};
        if (@vm_list == 0) {
            $num_of_empty_hv++;
        }
        else {
            my $size = $self->_getHvSizeOccupied(hv_id => $hv_id);
            $stat->{cpu_p} += $size->{cpu_p};
            $stat->{ram_p} += $size->{ram_p};
            $log->debug("HV $hv_id : CPU [".($size->{cpu_p}*100)." %] RAM [".($size->{ram_p} * 100)." %]");
        }
    }

    my $result = {
        num_of_empty_hv => $num_of_empty_hv,
        cpu_p_absolute  => $stat->{cpu_p} / $num_of_hv,
        ram_p_absolute  => $stat->{ram_p} / $num_of_hv,
        cpu_p_relative  => $stat->{cpu_p} / ($num_of_hv - $num_of_empty_hv),
        ram_p_relative  => $stat->{ram_p} / ($num_of_hv - $num_of_empty_hv),
    };

    $log->info("TOTAL CPU USED [".($hash->{cpu_p_relative}*100)
               ." %], RAM USED = [".($hash->{ram_p_relative}*100)
               ." %], HV EMPTY $hash->{num_of_empty_hv}");

    return $result;
}


sub _convertRelativetoAbsoluteScaleCpuValues {
    my ($self,%args) = @_;
    General::checkParams(args => \%args, required => ['host_id','vcpu_number']);

    my $sign = substr($args{vcpu_number},0,1); # get the first value
    my $vcpu_input;

    if ($sign eq '+' || $sign eq '-') {
        $vcpu_input = substr $args{vcpu_number},1; # remove sign
    }
    else {
        $vcpu_input = $args{vcpu_number};
    }

    my $cpu;
    if ($sign eq '+') {
        $cpu = $self->{_infra}->{vms}->{$args{host_id}}->{resources}->{cpu} + $vcpu_input;
    }
    elsif ($sign eq '-') {
        $cpu = $self->{_infra}->{vms}->{$args{host_id}}->{resources}->{cpu} - $vcpu_input;
    }
    elsif ($sign =~ /\d/) {
        $cpu = $vcpu_input;
    }
    else {
        throw Kanopya::Exception::Integer::WrongValue(error => "Wrong format for scale in memory value (typed : $args{vcpu_number})");
    }

    if ($cpu =~ /\D/) {
        throw Kanopya::Exception::Integer::WrongValue(error => "Wrong format for scale in memory value (typed : $args{vcpu_number})");
    }
    elsif ($cpu <= 0) {
        throw Kanopya::Exception::Integer::WrongValue(error => "Cannot scale CPU to a negative value (typed : $args{vcpu_number})");
    }
    else {
        return $cpu;
    }
}


sub _convertRelativetoAbsoluteScaleMemoryValues {
    my ($self,%args) = @_;
    General::checkParams(args => \%args, required => ['host_id','memory']);

    #Firstly Check
    my $sign = substr($args{memory},0,1); # get the first value
    my $mem_input;

    if ($sign eq '+' || $sign eq '-') {
        $mem_input = substr $args{memory},1; # remove sign
    }
    else {
        $mem_input = $args{memory};
    }

    if ($mem_input =~ /\D/) {
        throw Kanopya::Exception::Internal::WrongValue(error => "Wrong format for scale in memory value (typed : $args{memory})");
    }

    # Compute absolute memory instead of relative
    my $memory;
    if ($sign eq '+') {
        $memory = $self->{_infra}->{vms}->{$args{host_id}}->{resources}->{ram} + $mem_input;
    }
    elsif ($sign eq '-') {
        $memory = $self->{_infra}->{vms}->{$args{host_id}}->{resources}->{ram} - $mem_input;
    }
    elsif ($sign =~ /\d/) {
        $memory = $mem_input;
    }
    else {
        throw Kanopya::Exception::Internal::WrongValue(error => "Wrong format for scale in memory value (typed : $args{memory})");
    }

    if ($memory <= 0) {
        throw Kanopya::Exception::Internal::WrongValue(error => "Scale in memory value must be strictly positive (typed : $args{memory}");
    }

    return $memory;
}


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

sub scaleCpuHost {
    my ($self,%args) = @_;
    General::checkParams(args => \%args, required => ['host_id','vcpu_number']);

    my $cpu = $self->_convertRelativetoAbsoluteScaleCpuValues(%args);

    $self->{_operationPlan} = [];

    my @hv_selection_ids = keys %{$self->{_infra}->{hvs}};
    $log->info("Call scaleCpuMetric for host $args{host_id} and new value = $cpu");

    $self->_scaleMetric(
        vm_id            => $args{host_id},
        new_value        => $cpu,
        hv_selection_ids => \@hv_selection_ids,
        scale_metric     => 'cpu',
    );

    return $self->{_operationPlan};
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

sub scaleMemoryHost {
    my ($self,%args) = @_;
    General::checkParams(args => \%args, required => ['host_id','memory']);

    my $memory = $self->_convertRelativetoAbsoluteScaleMemoryValues(%args);

    $self->{_operationPlan} = [];

    my @hv_selection_ids = keys %{$self->{_infra}->{hvs}};
    $log->info("Call scaleMemoryMetric for host $args{host_id} and new value = $args{memory}");

    $self->_scaleMetric(
        vm_id            => $args{host_id},
        new_value        => $memory,
        hv_selection_ids => \@hv_selection_ids,
        scale_metric     => 'ram',
    );

    return $self->{_operationPlan};
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
    General::checkParams(args => \%args, required => ['vm_id', 'new_value', 'scale_metric']);

    my $vm_id         = $args{vm_id};
    my $new_value     = $args{new_value};
    my $scale_metric  = $args{scale_metric};

    $self->{_infra}->{vms}->{$vm_id}->{resources}->{$scale_metric} = $new_value;

    if ($scale_metric eq 'ram') {
        $log->debug("=> Operation scaling $scale_metric of vm $vm_id to $new_value");

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
        $log->debug("=> Operation scaling $scale_metric of vm $vm_id to $new_value");
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

Check if a scale-in is authorized w.r.t. the VM resources and the destination HV resources.

@param vm_id id of the checked vm
@param resource_type scaled resource
@param wanted_resource value of the resource you want to scale

@return 1 if scale-in is possible, return 0 if some resources are missing.

=end classdoc

=cut


sub isScalingAuthorized {
    my ($self, %args)   = @_;

    General::checkParams(args     => \%args,
                         required => [ 'vm_id', 'resource_type', 'wanted_resource' ]);

    my $vm_id           = $args{vm_id};
    my $resource_type   = $args{resource_type};
    my $wanted_resource = $args{wanted_resource}; # Mem must be in bytes

    my $hv_id           = $self->{_infra}->{vms}->{$vm_id}->{hv_id};

    my $remaining = $self->_getHvSizeRemaining(hv_id => $hv_id);

    my $current_resource;
    my $remaining_resource;

    if ($resource_type eq 'ram') {
        $current_resource   = $self->{_infra}->{vms}->{$vm_id}->{resources}->{ram};
        $remaining_resource = $remaining->{ram};
    }
    elsif ($resource_type eq 'cpu') {
        $current_resource   = $self->{_infra}->{vms}->{$vm_id}->{resources}->{cpu};
        $remaining_resource = $remaining->{cpu};
    }

    my $delta    = $wanted_resource - $current_resource;
    $log->debug("**** [scale-in $resource_type]  Remaining <$remaining_resource> in HV <$hv_id>, need <$delta> more to have <$wanted_resource> ****");

    if ($remaining_resource < $delta) {
        $log->info('Scaling refused : not enough resource ' . $resource_type . ' for VM ' . $vm_id . ' on hv ' . $hv_id);
        return 0;
    }

    $log->info('scaling authorized by capacity management : ' . $resource_type . ' for VM ' . $vm_id . ' on hv ' . $hv_id);
    return 1;

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

sub _migrateVmToScale {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => ['vm_id',
                                                      'new_value',
                                                      'hv_selection_ids',
                                                      'scale_metric']);

    my $vm_id = $args{vm_id};

    my $wanted_metrics = Clone::clone($self->{_infra}->{vms}->{$vm_id}->{resources});
    $wanted_metrics->{$args{scale_metric}} = $args{new_value};

    my $hv_dest_id = $self->_findMinHVidRespectCapa(
        hv_selection_ids => $args{hv_selection_ids},
        resources        => $wanted_metrics,
    );

    if (! defined $hv_dest_id->{hv_id}) {
        return 0;
    }

    $self->_migrateVmModifyInfra(vm_id => $vm_id,
                                 hv_id => $hv_dest_id->{hv_id});

    $self->_migrateVmOrder(vm_id => $vm_id,
                           hv_id => $hv_dest_id->{hv_id});

    return 1;
}


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
    General::checkParams(args => \%args, required => ['scale_metric', 'vm_id',
                                                      'new_value', 'hv_selection_ids']);


    my $scale_metric     = $args{scale_metric};
    my $vm_id            = $args{vm_id};
    my $new_value        = $args{new_value};
    my $hv_selection_ids = $args{hv_selection_ids};

    my $old_value = $self->{_infra}->{vms}->{$vm_id}->{resources}->{$scale_metric};
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

                my $result = $self->_migrateOtherVmsToScale(
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

Find the HV id which can accept the resources. Choose the one
with minimum space (average btw RAM and CPU)

@param resources values wanted for the vm
@param hv_selection_ids hypervisor which can be used to perform the migration

@return a hash with keys : hv_id => the hypervisor id, min_size_remaining => the 'score' used to
compare 2 hypervisors

=end classdoc

=cut

sub _findMinHVidRespectCapa {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => ['hv_selection_ids', 'resources']);
    General::checkParams(args => $args{resources}, required => ['ram', 'cpu']);

    my $wanted_metrics = $args{resources};

    my $result = {};
    $result->{hv_id} = undef;
    $result->{min_size_remaining} = undef;

    for my $hv_id (@{$args{hv_selection_ids}}){

        my $size_remaining = $self->_getHvSizeRemaining(hv_id => $hv_id);

        my $total_score = $size_remaining->{cpu_p} + $size_remaining->{ram_p};

        $log->debug('HV <'.$hv_id.'> Wanted RAM <'.($wanted_metrics->{ram})
                    .'> got <'.($size_remaining->{ram}).' ('.(100*$size_remaining->{ram_p})
                    .'%) > & CPU <'.($wanted_metrics->{cpu}).'> got <'.($size_remaining->{cpu})
                    .' ('.(100*$size_remaining->{cpu_p}).'%) >');

        my $condition = 1;
        for my $metric (keys %$wanted_metrics) {
            if (defined $size_remaining->{$metric}) {
                $log->debug("Check $metric, ok if $wanted_metrics->{$metric} <= $size_remaining->{$metric}");
                $condition &&= $wanted_metrics->{$metric} <= $size_remaining->{$metric};
            }
        }

        if ($condition) {
            if (defined $result->{min_size_remaining}) {
                if ($total_score < $result->{min_size_remaining}) {
                    $result->{min_size_remaining} = $total_score;
                    $result->{hv_id}              = $hv_id;
                }
            }
            else{
                $result->{min_size_remaining} = $total_score,
                $result->{hv_id}              = $hv_id;
            }
        }
    }

    return $result;
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

    my $hv_cluster   = (defined $self->{_cloud_manager}) ?
                       $self->{_cloud_manager}->service_provider :
                       undef;

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

    $log->debug("=> migration $vm_id to new started HV");
    push @{$self->{_operationPlan}}, {
        type => 'MigrateHost',
        priority => 1,
        params => {
            context => {
                vm => Entity->get(id=>$vm_id),
            }
        }
    };

    # Scale host
    if ($scale_metric eq 'ram') {
        $log->debug("=> Operation scaling $scale_metric of vm $vm_id to $new_value");
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
        $log->debug("=> Operation scaling $scale_metric of vm $vm_id to $new_value");
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


sub _addVirtualHV {
    my ($self,%args) = @_;
    General::checkParams(args => \%args, required => ['resources'],
                                         optional => {'hv_id' => undef});

    if (! defined $args{hv_id}) {
        # Add a 'virtual' hypervisor into infrastructure
        my $hv_id_max = 0;
        for my $hv_id (keys %{$self->{_infra}->{hvs}}) {
            if ($hv_id > $hv_id_max) {
                $hv_id_max = $hv_id;
            }
        }

        $args{hv_id} = $hv_id_max+1;
    }

    $self->{_infra}->{hvs}->{$args{hv_id}}->{resources} = $args{resources};
    return  $args{hv_id};
}


sub _addVirtualVMs {
    my ($self,%args) = @_;
    General::checkParams(args => \%args, required => ['vms_resources'],
                                         optional => {'vm_ids' => undef});

    if (! defined $args{vm_ids}) {
        my $vm_id_max = 0;
        for my $vm_id (keys %{$self->{_infra}->{vms}}) {
            if ($vm_id > $vm_id_max) {
                $vm_id_max = $vm_id;
            }
        }
        my @vm_ids = ($vm_id_max+1, $vm_id_max + 1 + (scalar @{$args{vms_resources}}));
        $args{vm_ids} = \@vm_ids;
    }

    for my $id (@{$args{vm_ids}}) {
        $self->{_infra}->{vms}->{$id}->{resources} = shift @{$args{vms_resources}};
    }

    return  $args{vm_ids};
}

sub prettyOut {
    my $self = shift;

    for $hv_id (keys %{$self->{_infra}->{hvs}}) {
        my $o = $self->{_infra}->{hvs}->{$hv_id}->{resources};
        my $r = $self->_getHvSizeRemaining(hv_id => $hv_id);
        print "$hv_id [(".($r->{ram} >> 20) ."/".($o->{ram} >> 20)." ".$r->{cpu}."/".$o->{cpu}."] ";
        print scalar keys %{$self->{_infra}->{hvs}->{$hv_id}->{vm_ids}};
        print "\n";
    }
}
1;
