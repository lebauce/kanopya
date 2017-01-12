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
use CapacityManager::HCMCapacityManager;
use Kanopya::Exceptions;

use TryCatch;
use String::Random 'random_regex';
use Log::Log4perl "get_logger";

my $log = get_logger("");
my $errmsg;

=pod
=begin classdoc

@return the manager params definition.

=end classdoc
=cut

sub getManagerParamsDef {
    my ($self, %args) = @_;

    return {
        %{ $self->SUPER::getManagerParamsDef },
        affinity => {
            label => 'Placement Policy',
            is_mandatory => 0,
            type => 'enum',
            options => {
                most_loaded => 'Most loaded hypervisor',
                least_loaded => 'Least loaded hypervisor',
                anti_affinity => 'AntiAffinity',
                affinity => 'Affinity',
            },
            description => "Virtual Machine placement strategy: \n"
                           . "AntiAffinity will try to spread "
                           . "virtual machines on different hypervisors \n"
                           . "Affinity will try to stack virtual machines "
                           . "on the same hypervisor \n"
                           . "Least/Most loaded hypervisor will choose "
                           . "an hypervisor independently of existing other vms"
                           . "(from candidate hypervisors with enough capacities)",
        },
    }
}

sub methods {
    return {
        scaleHost => {
            description => 'scale host\'s cpu / memory',
        },
        migrate => {
            description => 'migrate a host',
        },
        optimiaas  => {
            description => 'optimize IaaS (packing)',
        },
    };
}

sub getHostManagerParams {
    my ($self, %args) = @_;
    return {affinity_policy => $self->getManagerParamsDef->{affinity}};
}

sub createVirtualHost {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'ram', 'core' ],
                         optional => { 'ifaces'        => 0,
                                       'hypervisor_id' => undef,
                                       'serial_number' => "Virtual Host managed by component " . $self->id });

    # Use the first kernel found...
    my $kernel = Entity::Kernel->find(hash => {});

    my $vm = Entity::Host::VirtualMachine->new(
                 host_manager_id    => $self->id,
                 hypervisor_id      => $args{hypervisor_id},
                 host_serial_number => $args{serial_number},
                 kernel_id          => $kernel->id,
                 host_ram           => $args{ram},
                 host_core          => $args{core},
                 active             => 1,
             );

    foreach (0 .. $args{ifaces}-1) {
        $vm->addIface(
            iface_name     => 'eth' . $_,
            iface_mac_addr => $self->generateMacAddress(),
            iface_pxe      => $_ == 0 ? 1 : 0,
        );
    }

    return $vm;
}


=pod
=begin classdoc

Redirect calls to createHost to createVirtualHost, should be never call,
usefull for test purpose.

@return the created virtual machine

=end classdoc
=cut

sub createHost {
    my ($self, %args) = @_;

    return $self->createVirtualHost(ram  => delete $args{host_ram},
                                    core => delete $args{host_core},
                                    %args);
}


=pod
=begin classdoc

return a mac address auto generated and not used by any host

@return mac address auto generated and not used by any host

=end classdoc
=cut

sub generateMacAddress {
    my ($self, %args) = @_;

    General::checkParams(args => \%args,
        optional => { regexp => '00:[a-f0-9]{2}:[a-f0-9]{2}:[a-f0-9]{2}:[a-f0-9]{2}:[a-f0-9]{2}', }
    );

    my $macaddress;
    my @ifaces = ();

    do {
         $macaddress = random_regex($args{regexp});
         @ifaces = Entity::Iface->search(hash => { iface_mac_addr => $macaddress },
                                  rows => 1);
    } while(scalar(@ifaces));

    return $macaddress;
}

=pod
=begin classdoc

launch a scale workflow that can be of type 'cpu' or 'memory'

@param host_id Host instance id to scale
@param scalein_value Wanted value
@param scalein_type Selectsthe metric to scale in either 'ram' or 'cpu'

=end classdoc
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

    return $self->executor_component->run(
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

    return $self->executor_component->run(
               name       => 'MigrateWorkflow',
               params     => $wf_params
           );
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

sub selectHypervisor {
    my ($self, %args) = @_;
    General::checkParams(args => \%args,
                         optional => {
                             cluster => undef,
                             affinity => 'default',
                             selected_hv_ids => undef,
                         },
                         required => [ 'ram', 'core' ]);

    my %cm_params = ();
    if ($args{affinity_policy} eq 'anti_affinity') {
        $log->debug('Configure anti affinity placement policy');
        my %affinity_weights = map {$_->host_id, 1} $args{cluster}->nodes;
        $cm_params{affinity_weights} = \%affinity_weights,
        $cm_params{cpu_multiplier} = 0;
        $cm_params{ram_multiplier} = 0;
    }
    elsif ($args{affinity_policy} eq 'affinity') {
        $log->debug('Configure affinity placement policy');
        my %affinity_weights = map {$_->host_id, -1} $args{cluster}->nodes;
        $cm_params{affinity_weights} = \%affinity_weights,
        $cm_params{cpu_multiplier} = 0;
        $cm_params{ram_multiplier} = 0;
    }
    elsif ($args{affinity_policy} eq 'least_loaded') {
        $log->debug('Configure least loaded placement policy');
        $cm_params{cpu_multiplier} = -1;
        $cm_params{ram_multiplier} = -1;
    }
    else {
        $log->debug('Configure most loaded placement policy');
        # by default we use the most loaded hypervisor which does not need
        # specific parameters
    }

    $cm_params{selected_hv_ids} = $args{selected_hv_ids} if defined $args{selected_hv_ids};

    my $cm = CapacityManager::HCMCapacityManager->new(cloud_manager => $self);

    return $cm->selectHypervisor(
               resources => {ram => $args{ram},
               cpu => $args{core}},
               %cm_params,
           );
}


sub optimiaas {
    my ($self, %args) = @_;
    General::checkParams(
        args     => \%args,
        optional => {
            policy => 'stack',
        }
    );

    $self->executor_component->run(
        name   => 'OptimiaasWorkflow',
        params => {
            context => {
                cloudmanager_comp => $self,
            },
            policy => $args{policy},
        }
    );
}

1;
