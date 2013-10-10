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

Capacity Management manages the infrastructure of virtual machine clusters.
It manages the scale-in and the scale-out of virtual machines
It manages the optimization of the infrastructure, which tries to minimize the
number of hypervisors used by the infra.

@since    2013-Jul-30
@instance hash
@self     $self

=end classdoc

=cut

package ChocoCapacityManagement;

use base CapacityManager;

use strict;
use warnings;
use Data::Dumper;
use TryCatch;
my $err;
use Clone;

# logger
use Log::Log4perl "get_logger";
my $log = get_logger("");

my $JAR = '/opt/kanopya/tools/constraint_engine/capacity_manager/capacity_manager.jar';
my $TIME_LIMIT_IN_MS = 20000;

sub getHypervisorIdForVM {
    my ($self,%args) = @_;
    General::checkParams(args => \%args, required => [ 'resources' ]);
    my $result = $self->getHypervisorIdsForVMs(vms_resources_hash => {0 => $args{resources}});
    return $result->{0};
}


sub flushHypervisorPlan {
    my ($self,%args) = @_;
    General::checkParams(args => \%args, required => ['hv_id']);

    my $migration_hash = $self->_executeFlushHypervisor(%args);

    my $num_failed = 0;
    while (my ($vm_id, $hv_id) = each (%$migration_hash)) {
        if ($hv_id == $args{hv_id}) {
            $num_failed++;
            delete $migration_hash->{$vm_id};
        }
        else {
            $self->_migrateVmModifyInfra(
                vm_id => $vm_id,
                hv_id => $hv_id,
            );
        }
    }

    return {
        migrations => $migration_hash,
        num_failed => $num_failed,
    }
}

sub flushHypervisor {
    my ($self,%args) = @_;
    General::checkParams(args => \%args, required => ['hv_id']);

    if (not defined $self->{_infra}->{hvs}->{$args{hv_id}}) {
        my $error = "Hypervisor <$args{hv_id}> is not managed by the capacity manager (may be not active or not up)";
        throw Kanopya::Exception(error => $error);
    }

    my $plan = $self->flushHypervisorPlan(%args);

    $self->{_operationPlan} = [];

    while (my ($vm_id, $hv_id) = each (%{$plan->{migrations}})) {
        $self->_migrateVmOrder(
            vm_id => $vm_id,
            hv_id => $hv_id,
        );
    }

    return { num_failed     => $plan->{num_failed},
             operation_plan => $self->{_operationPlan}};
}

sub resubmitHypervisor {
    my ($self,%args) = @_;
    General::checkParams(args => \%args, required => ['hv_id'],
                                         optional => {authorized_same_hv => 0});

    my $result = $self->_executeFlushHypervisor(hv_id => $args{hv_id});

    if ($args{authorized_same_hv} == 0) {
        while (my ($k,$v) = each (%$result)) {
            if ($v == $args{hv_id}) {
                delete $result->{$k};
            }
        }
    }

    return $result;
}


sub getHypervisorIdsForVMs {
    my ($self,%args) = @_;
    General::checkParams(args => \%args, required => ['vms_resources_hash']);

    my $virtual_hv_resources = {
        ram => 0,
        cpu => 0,
    };

    my @vm_ids = ();
    my @vms_resources = ();

    while (my ($vm_id, $vm_resources) = each(%{$args{vms_resources_hash}})) {
        push @vm_ids, $vm_id;
        push @vms_resources, $vm_resources;

        $virtual_hv_resources->{ram} += $vm_resources->{ram};
        $virtual_hv_resources->{cpu} += $vm_resources->{cpu};
    }

    my $virtual_hv_id  = $self->_addVirtualHV(resources => $virtual_hv_resources);
    $self->_addVirtualVMs(vms_resources => \@vms_resources,
                          vm_ids        => \@vm_ids);

    for my $vm_id (@vm_ids) {
        $self->_addVmInHV(hv_id => $virtual_hv_id, vm_id => $vm_id)
    }

    my $hypervisor_assignment = $self->_executeFlushHypervisor(hv_id => $virtual_hv_id);

    while( my ($k,$v) = each (%$hypervisor_assignment)) {
        if ($v == $virtual_hv_id) {
            $hypervisor_assignment->{$k} = undef;
        }
    }

    # Clean infra
    for my $vm_id (@vm_ids) {
        $self->_removeVmfromInfra(vm_id => $vm_id);
    }

    delete $self->{_infra}->{hvs}->{$virtual_hv_id};

    return $hypervisor_assignment;
}


=pod

=begin classdoc

Launch Jar execution inside a local EContext

@param main_class the Choco main class
@param jar_args Array reference containing the arguments of the Choco main class

@return command execution return hash { stderr => 'Error message',
                                        stdout => 'Output message',
                                        exitcode => '' }

=end classdoc

=cut

sub _executeJAR {
    my ($self,%args) = @_;
    General::checkParams(args => \%args, required => [ 'main_class' ],
                                         optional => { jar_args => []});

    my $command  = "java -cp $JAR main.$args{main_class}";
    map {$command .= " ".$_} @{$args{jar_args}};
#    print $command."\n";
    my $econtext = EContext::Local->new();
    my $result = $econtext->execute(command => $command);
#    print Dumper $result;
    return $result;
}


=pod

=begin classdoc

Prepare parameters and launch Choco FlushHypervisor class main

@param hv_id the hypervisor id to flush

@return hash reference {vm_id => hv_id}, the hypervisor id in which the vm id has been planed to be
        migrated

=end classdoc

=cut

sub _executeFlushHypervisor {
    my ($self,%args) = @_;
    General::checkParams(args => \%args, required => ['hv_id']);

    my $infra_simplified = $self->_modifyInfraRemoveVmsAjustHvsSize(hv_id => $args{hv_id});

    my $tempfile = $self->_infraToTempFile(infra => $infra_simplified);

    my @jar_args = ($tempfile, $args{hv_id}, $TIME_LIMIT_IN_MS);

    my $flush_class = 'FlushHypervisor';

    my $result = $self->_executeJAR(main_class => $flush_class, jar_args => \@jar_args);

    unlink $tempfile; # Delete temp file

    if ($result->{exitcode} eq 0) {
        return JSON->new->utf8->decode($result->{stdout});
    }
    elsif ($result->{exitcode} eq 2) {
        throw Kanopya::Exception::Internal(error => 'Cannot flush hypervisor');
    }
    else {
        throw Kanopya::Exception::(error => 'Error executing Choco constraint engine GetHypervisorIdsForVms: '.
                                           $result->{stderr});
    }
}

sub _modifyInfraRemoveVmsAjustHvsSize {
    my ($self,%args) = @_;
    General::checkParams(args => \%args, required => ['hv_id']);

    my $infra = {};

    for my $hv_id (keys %{$self->{_infra}->{hvs}}) {
        if ($hv_id != $args{hv_id}) {
            my $remaining_resources = $self->_getHvSizeRemaining(hv_id=> $hv_id);
            $infra->{hvs}->{$hv_id}->{resources}->{ram} = $remaining_resources->{ram};
            $infra->{hvs}->{$hv_id}->{resources}->{cpu} = $remaining_resources->{cpu};
        }
        else {
            $infra->{hvs}->{$hv_id} = Clone::clone($self->{_infra}->{hvs}->{$hv_id});
        }
    }

    for my $vm_id (keys %{$infra->{hvs}->{$args{hv_id}}->{vm_ids}}) {
        $infra->{vms}->{$vm_id} = Clone::clone($self->{_infra}->{vms}->{$vm_id});
    }

    return $infra;
}


=pod

=begin classdoc

Prepare parameters and launch Choco AddVmMinMigration class main

@param hv_id the hypervisor id to flush

@return hash reference {vm_id => hv_id}, the hypervisor id in which the vm id has been planed to be
        migrated

=end classdoc

=cut

sub _executeAddVmInHvMinMigrations {
    my ($self,%args) = @_;
    General::checkParams(args => \%args, required => ['hv_id'], optional => {infra => undef});

    my $tempfile = $self->_infraToTempFile(infra => $args{infra});
    my @jar_args = ($tempfile, $args{hv_id}, $TIME_LIMIT_IN_MS);

    my $result = $self->_executeJAR(main_class => 'AddVmInHvMinMigrations', jar_args => \@jar_args);

    unlink $tempfile;

    if ($result->{exitcode} eq 0) {
        return JSON->new->utf8->decode($result->{stdout});
    }
    elsif ($result->{exitcode} eq 2) {
        throw Kanopya::Exception::Internal(error => 'Cannot force vm on the hypervisor');
    }
    else {
        throw Kanopya::Exception(error => 'Error executing Choco constraint engine AddVmInHvMinMigrations: '.
                                           $result->{stderr});
    }
}


sub _migrateOtherVmsToScale {
    my ($self,%args) = @_;
    General::checkParams(args => \%args, required => [ 'vm_id', 'new_value', 'scale_metric' ]);

    my $old_value = $self->{_infra}->{vms}->{$args{vm_id}}->{resources}->{$args{scale_metric}};

    # Remove VM to scale from the infrastructure in order to replace it, allowing
    # only migration of its original hypervisor and minimizing number of migrations

    $self->{_infra}->{vms}->{$args{vm_id}}->{resources}->{$args{scale_metric}} = $args{new_value};

    my $old_hv_id = $self->{_infra}->{vms}->{$args{vm_id}}->{hv_id};
    my $infra_simplified = $self->_modifyInfraRemoveVmsAjustHvsSize(hv_id => $old_hv_id);
    $self->_removeVmFromHV(vm_id => $args{vm_id}, infra => $infra_simplified);

    my $result;
    try {
        $result = $self->_executeAddVmInHvMinMigrations(hv_id => $old_hv_id, infra => $infra_simplified);
    }
    catch (Kanopya::Exception::Internal $err) {
        return 0;
    }

    $self->_addVmInHV(
        vm_id => $args{vm_id},
        hv_id => $old_hv_id,
    );

    while (my ($vm_id, $hv_id) = each(%$result)) {
        $self->_migrateVmModifyInfra(
            vm_id => $vm_id,
            hv_id => $hv_id,
        );

        $self->_migrateVmOrder(
            vm_id => $vm_id,
            hv_id => $hv_id,
        );
    }

    return 1;
}

1;
