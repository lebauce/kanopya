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

=pod

=begin classdoc

TODO

=end classdoc

=cut

package Manager::HostManager::VirtualMachineManager;
use base "Manager::HostManager";

use Entity::Host::Hypervisor;
use Entity::Host::VirtualMachine;
use Entity::Iface;
use Entity::Workflow;
use Log::Log4perl "get_logger";

my $log = get_logger("administrator");
my $errmsg;

sub methods {
    return {
        scaleHost => {
            description => 'scale host\'s cpu / memory',
            perm_holder => 'entity',
        },
        migrate => {
            description => 'migrate a host',
            perm_holder => 'entity',
        },
        optimiaas  => {
            description => 'optimize IaaS (packing)',
            perm_holder => 'entity',
        },
        # TODO(methods): Remove this method from the api once the merge of component/connector
        hypervisors => {
            description => 'get the hypervisors manzaged by the cloud component',
            perm_holder => 'entity',
            is_virtual  => 1
        },
    };
}


sub createVirtualHost {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [ 'ram', 'core' ], optional => { 'ifaces' => 0 });

    # Use the first kernel found...
    my $kernel = Entity::Kernel->find(hash => {});

    my $vm = Entity::Host::VirtualMachine->new(
                 host_manager_id    => $self->id,
                 host_serial_number => "Virtual Host managed by component " . $self->id,
                 kernel_id          => $kernel->id,
                 host_ram           => $args{ram},
                 host_core          => $args{core},
                 active             => 1,
             );

    foreach (0 .. $args{ifaces}-1) {
        $vm->addIface(
            iface_name     => 'eth' . $_,
            iface_mac_addr => Entity::Iface->generateMacAddress(),
            iface_pxe      => $_ == 0 ? 1 : 0,
        );
    }

    $log->debug("Return host with <" . $vm->id . ">");
    return $vm;
}

=head2 scaleHost

    Desc: launch a scale workflow that can be of type 'cpu' or 'memory'
    Args: $host_id, $scalein_value, $scalein_type

=cut

sub scaleHost {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [ 'host_id', 'scalein_value', 'scalein_type' ]);

    my $host = Entity::Host::VirtualMachine->get(id => $args{host_id});

    my $wf_params = {
        scalein_value => $args{scalein_value},
        scalein_type  => $args{scalein_type},
        context       => {
            host              => $host,
            cloudmanager_comp => $self
        }
    };

    $self->service_provider->getManager(manager_type => 'ExecutionManager')->run(
        name   => 'ScaleIn' . ($args{scalein_type} eq 'memory' ? "Memory" : "CPU"),
        params => $wf_params
    );
}

=pod

=begin classdoc

Launch migration

=end classdoc

=cut

sub migrate {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host_id', 'hypervisor_id' ]);

    my $hypervisor = Entity::Host::Hypervisor->get(id => $args{hypervisor_id});
    my $wf_params = {
        context => {
            vm   => Entity::Host::VirtualMachine->get(id => $args{host_id}),
            host => $hypervisor,
            cloudmanager_comp => $self
        }
    };

    return $self->service_provider->getManager(manager_type => 'ExecutionManager')->run(
               name       => 'MigrateWorkflow',
               related_id => $hypervisor->getClusterId(),
               params     => $wf_params
           );
}


=pod

=begin classdoc

Update hypervisor of vm in DB

=end classdoc

=cut

sub migrateHost {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'host', 'hypervisor_dst' ]);

    $log->info('Migrating host <' . $args{host}->getId . '> to hypervisor ' . $args{hypervisor_dst}->getId);

    $args{host}->hypervisor_id($args{hypervisor_dst}->id);

}


=pod

=begin classdoc

Abstract method to get the list of hypervisors managed by this host manager.

@return the hypervisor list

=end classdoc

=cut

sub hypervisors {
    throw Kanopya::Exception::NotImplemented();
}

sub hostType {
    return "Virtual Machine";
}


=pod

=begin classdoc

Update hypervisors of vms

@param hashtable {vm_id => hypervisor_id}

=end classdoc

=cut

sub repairWrongHypervisor {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => [ 'vm_ids' ]);
    while (my ($vm_id, $hv_id) = each (%{$args{vm_ids}})) {
        Entity->get(id => $vm_id)->hypervisor_id($hv_id);
    }
}


=pod

=begin classdoc

Deactivate a node which is not in the infrastructure. Set state as broken and hypervisor as undef

@param hashtable {vm_id => undef}

=end classdoc

=cut

sub repairVmInDBNotInInfra {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => [ 'vm_ids' ]);
    for my $vm_id (keys %{$args{vm_ids}}) {
        my $vm = Entity->get(id => $vm_id);
        if (defined $vm->node) {
            $vm->node->disable();
            $vm->setNodeState(state => 'broken');
        }
        $vm->setAttr(name => 'hypervisor_id', value => undef);
        $vm->save();
    }
}

=pod

=begin classdoc

Update hypervisor of vms in Kanopya DB

@param vm_ids hashtable {vm_id => hv_id}

=end classdoc

=cut

sub repairVmInInfraWrongHostManager {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => [ 'vm_ids' ]);
    while (my ($vm_id, $hv_id) = each (%{$args{vm_ids}})) {
        my $host = Entity->get(id => $vm_id);
        $host->setAttr(name => 'hypervisor_id',   value => $hv_id);
        $host->setAttr(name => 'host_manager_id', value => $self->id);
        $host->save();
    }
}

sub promoteVm {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => [ 'host', 'hypervisor_id' ]);
    throw Kanopya::Exception::NotImplemented();
}
1;
