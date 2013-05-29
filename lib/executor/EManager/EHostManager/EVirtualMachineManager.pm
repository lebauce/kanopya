# Copyright © 2012 Hedera Technology SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

package EManager::EHostManager::EVirtualMachineManager;
use base "EManager::EHostManager";

use strict;
use warnings;
use Data::Dumper;

use Log::Log4perl "get_logger";

my $log = get_logger("executor");
my $errmsg;

sub getFreeHost {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [ "cluster" ]);

    my $cluster     = $args{cluster};
    my $host_params = $cluster->getManagerParameters(manager_type => "HostManager");
    my @interfaces  = $cluster->interfaces;

    $log->info("Looking for a virtual host");
    my $host;
    eval {
        $host = $self->createVirtualHost(
                    core   => $host_params->{core},
                    ram    => $host_params->{ram},
                    ifaces => scalar @interfaces,
                );
    };
    if ($@) {
        $errmsg = "Virtual Machine Manager component <" . $self->getAttr(name => 'component_id') .
                  "> No capabilities to host this vm core <$args{core}> and ram <$args{ram}>:\n" . $@;
        # We can't create virtual host for some reasons (e.g can't meet constraints)
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    return $host;
}

=cut

=begin classdoc

Check the state of the vm

@return boolean

=end classdoc

=cut

sub checkUp {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ "host" ]);

    my $host = $args{host};
    my $vm_state = $self->getVMState(host => $host);

    $log->info('VM <' . $host->id . '> VM status <' . ($vm_state->{state}) . '>');

    if ($vm_state->{state} eq 'runn') {
        $log->info('VM running try to contact it');
        return 1;
    }
    elsif ($vm_state->{state} eq 'boot') {
        $log->info('VM still booting');
        return 0;
    }
    elsif ($vm_state->{state} eq 'fail' ) {
        my $lastmessage = $self->vmLoggedErrorMessage(vm => $host);
        throw Kanopya::Exception(error => 'VM fail on boot: ' . $lastmessage);
    }
    elsif ($vm_state->{state} eq 'pend' ) {
        $log->info('VM still pending'); #TODO check HV state
        return 0;
    }

    return 0;
}

sub vmLoggedErrorMessage {
    return "Unknown error";
}


=pod

=begin classdoc

Synchronize vm ram and core with infrastructure

@param host virtual machine

=end classdoc

=cut

sub repairVMRessourceIntegrity {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => [ 'host' ]);

    for my $vm ($args{host}->virtual_machines) {
        my $evm = new EEntity(data => $vm)->getResources(resource => [ 'cpu' , 'ram' ]);

        if ($evm->{ram} != $vm->host_ram) {
            $vm->setAttr(name => 'host_ram', value => $evm->{ram});
        }

        if ($evm->{cpu} != $vm->host_core) {
            $vm->setAttr(name => 'host_core', value => $evm->{cpu});
        }
        $vm->save();
    }
}


=pod

=begin classdoc

Analyse diff_infra_db datastructure to check if it contains entries.

@return test result which is true if the tested infrastructure is synchronized

=end classdoc

=cut

sub isInfrastructureSynchronized {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => [ 'hash' ]);

    $log->info(Dumper $args{hash});

    return ! (keys %{$args{hash}->{wrong_hv}}              > 0 ||
              keys %{$args{hash}->{infra_not_hostmanager}} > 0 ||
              keys %{$args{hash}->{base_not_hv_infra}}     > 0 ||
              keys %{$args{hash}->{unk_vm_uuids}}          > 0);

}


=pod

=begin classdoc

Check if the infrastructure managed by the controller is synchronized with the db values.

The method returns a hash table with 4 entries. Each entry is a hash table whose keys are vm ids or
uuids

unk_vm_uuids          : vms which are in the infrastructure but are not registered in the Kanopya DB
base_not_hv_infra     : vms which are registed in Kanopya DB but are not in the infrastructure
infra_not_hostmanager : vms which are in the infrastructure and in the Kanopya DB but are registered
                        with a wrong hostmanager
wrong_hv              : vms which are in the infrastructure and in the Kanopya DB but are registered
                        with a wrong hypervisor


@return hash table reference

=end classdoc

=cut

sub checkAllInfrastructureIntegrity {
    my $self = shift;
    my $hypervisors = $self->hypervisors;
    return $self->checkHypervisorsVMPlacementIntegrity(hypervisors => $hypervisors);
}


=pod

=begin classdoc

Check if a given list of hypervisors are synchronized with the db values.

The method returns a hash table with 4 entries. Each entry is a hash table whose keys are vm ids or
uuids

unk_vm_uuids          : vms which are in the infrastructure but are not registered in the Kanopya DB
base_not_hv_infra     : vms which are registed in Kanopya DB but are not in the infrastructure
infra_not_hostmanager : vms which are in the infrastructure and in the Kanopya DB but are registered
                        with a wrong hostmanager
wrong_hv              : vms which are in the infrastructure and in the Kanopya DB but are registered
                        with a wrong hypervisor

@param hypervisors array of hypervisors to check
@return hash table reference

=end classdoc

=cut

sub checkHypervisorsVMPlacementIntegrity {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => [ 'hypervisors' ]);

    my $diff_infra_db;

    for my $hypervisor (@{$args{hypervisors}}) {
        $diff_infra_db = $self->checkHypervisorVMPlacementIntegrity(
                                    host          => $hypervisor,
                                    diff_infra_db => $diff_infra_db
                                );
    }
    return $diff_infra_db;
}

=pod

=begin classdoc

Create OpenstackVms with given openstack uuid. Set ram, cpu and hypervisor

@param hashtable {vm_uuids => undef}

=end classdoc

=cut

sub repairVmInInfraUnkInDB {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => [ 'vm_uuids' ]);
    while (my ($vm_uuid, $hv_id) = each (%{$args{vm_uuids}})) {
        my $host = $self->createVirtualHost(ram => 0, core => 0, ifaces => 1);
        $host = $self->promoteVm(host           => $host,
                                 vm_uuid        => $vm_uuid,
                                 hypervisor_id  => $hv_id);

        my $evm = new EEntity(data => $host)->getResources(resource => [ 'cpu' , 'ram' ]);
        $host->setAttr(name => 'host_ram',  value => $evm->{ram});
        $host->setAttr(name => 'host_core', value => $evm->{cpu});
        $host->save();
    }
}


=pod

=begin classdoc

Check if a given hypervisor is synchronized with the db values.

The method returns a hash table with 4 entries. Each entry is a hash table whose keys are vm ids or
uuids

unk_vm_uuids          : vms which are in the infrastructure but are not registered in the Kanopya DB
base_not_hv_infra     : vms which are registed in Kanopya DB but are not in the infrastructure
infra_not_hostmanager : vms which are in the infrastructure and in the Kanopya DB but are registered
                        with a wrong hostmanager
wrong_hv              : vms which are in the infrastructure and in the Kanopya DB but are registered
                        with a wrong hypervisor

@param host hypervisor
@return hash table reference

=end classdoc

=cut

sub checkHypervisorVMPlacementIntegrity {
    my ($self, %args) = @_;
    General::checkParams(args     => \%args,
                         required => [ 'host' ],
                         optional => {
                             diff_infra_db => {
                                infra_not_hostmanager => {},
                                base_not_hv_infra     => {},
                                wrong_hv              => {},
                                unk_vm_uuids          => {},
                             }
                         });

    $DB::single = 1;

    my $hypervisor = $args{host};

    # Get hypervisor vms according to HostManager
    my $h_vms = $self->getHypervisorVMs(host => $hypervisor);
    my @infra_hv_vms = @{$h_vms->{vms}};
    my $hv_infra= {};
    for my $vm (@infra_hv_vms) {
        $hv_infra->{$vm->id} = $hypervisor->id;
    };

    # Get all the vms of the infra from the db
    my $cloud_vms = {};
    my @cloud_vms_array = $self->hosts;
    for my $vm (@cloud_vms_array) {
        $cloud_vms->{$vm->id} = -1;
    };

    # Get all the vms of the hypervisor from the db
    my @db_hv_vms = $hypervisor->virtual_machines;

    # Get all unkown vms
    for my $uuid (@{$h_vms->{unk_vm_uuids}}) {
        $args{diff_infra_db}->{unk_vm_uuids}->{$uuid} = $hypervisor->id;
    }

    for my $hv_infra_vm (@infra_hv_vms) {
        if (! defined $cloud_vms->{$hv_infra_vm->id}) {
            # Vm in db but not known by the hostmanager
            $args{diff_infra_db}->{infra_not_hostmanager}->{$hv_infra_vm->id} = $hypervisor->id;
        }
        elsif ($hv_infra_vm->hypervisor_id != $hypervisor->id) {
            # Vm in db, known by hostmanager but wrong hypervisor
            $args{diff_infra_db}->{wrong_hv}->{$hv_infra_vm->id} = $hypervisor->id;
            delete $args{diff_infra_db}->{base_not_hv_infra}->{$hv_infra_vm->id};
        }
    }

    # Check vm of hv in db which are not in the hv_infra
    for my $vm (@db_hv_vms) {
        if ((! defined $hv_infra->{$vm->id}) && (! defined $args{diff_infra_db}->{wrong_hv}->{$vm->id})) {
            eval {
                $args{diff_infra_db} = $self->checkVMPlacementIntegrity(host          => Entity->get(id => $vm->id),
                                                                        diff_infra_db => $args{diff_infra_db});
            };
            if ($@) {
                $args{diff_infra_db}->{base_not_hv_infra}->{$vm->id} = undef;
            }

        }
    }
    return $args{diff_infra_db};
}


=pod

=begin classdoc

Check if a given vm is on the right hypervisor

@param host openstack virtual machine to check
@optional diff_infra_db datastructure which will be updated or created if undef
@return updated hash table diff_infra_db

throw Kanopya::Exception if the VM is not in the infrastructure

=end classdoc

=cut

sub checkVMPlacementIntegrity {
    my ($self, %args) = @_;
    General::checkParams(args     => \%args,
                         required => [ 'host' ],
                         optional => {
                             diff_infra_db => {
                                infra_not_hostmanager => {},
                                base_not_hv_infra     => {},
                                wrong_hv              => {},
                                unk_vm_uuids          => {},
                             }
                         });

    my $detail;
    eval {
        $detail = $self->getVMDetails(host => $args{host});
    };
    if ($@) {
        # Case unknown vm
        my $error = $@;
        $args{diff_infra_db}->{base_not_hv_infra}->{$args{host}->id} = undef;
        throw Kanopya::Exception(error => $error);
    }

    my $hypervisor_hostname = $detail->{hypervisor};
    my $hypervisor_id = Node->find(hash => {node_hostname => $hypervisor_hostname})->host->id;
    my $db_hypervisor = $args{host}->hypervisor;

    if (defined $db_hypervisor && ($hypervisor_id == $db_hypervisor->id)) {
        # Case right hypervisor
        return $args{diff_infra_db};
    }

    # Case wrong hypervisor
    $args{diff_infra_db}->{wrong_hv}->{$args{host}->id} = $hypervisor_id;
    return $args{diff_infra_db};
}

=pod

=begin classdoc

Get all the vms of an hypervisor

@param host hypervisor

=end classdoc

=cut

sub getHypervisorVMs {
    throw Kanopya::Exception::NotImplemented();
}

sub getVMDetails {

    # return {
    #     state    =>
    #     hostname =>
    # }

    throw Kanopya::Exception::NotImplemented();
}
1;
