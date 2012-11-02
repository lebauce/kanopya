# Opennebula3.pm - Opennebula3 component
#    Copyright © 2011-2012 Hedera Technology SAS
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

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

=head1 NAME

<Entity::Component::Opennebula3> <Opennebula3 component concret class>

=head1 VERSION

This documentation refers to <Entity::Component::Opennebula3> version 1.0.0.

=head1 SYNOPSIS

use <Entity::Component::Opennebula3>;

my $component_instance_id = 2; # component instance id

Entity::Component::Opennebula3->get(id=>$component_instance_id);

# Cluster id

my $cluster_id = 3;

# Component id are fixed, please refer to component id table

my $component_id =2

Entity::Component::Opennebula3->new(component_id=>$component_id, cluster_id=>$cluster_id);

=head1 DESCRIPTION

Entity::Component::Opennebula3 is class allowing to instantiate a Opennebula3 component
This Entity is empty but present methods to set configuration.

=head1 METHODS

=cut

package Entity::Component::Opennebula3;
use base "Entity::Component";
use base "Manager::HostManager::VirtualMachineManager";

use strict;
use warnings;

use Kanopya::Exceptions;
use Manager::HostManager;
use Entity::Workflow;
use Entity::Operation;
use Entity::ContainerAccess;
use Entity::ContainerAccess::NfsContainerAccess;
use Entity::Host::Hypervisor::Opennebula3Hypervisor;
use Entity::Host::Hypervisor::Opennebula3Hypervisor::Opennebula3XenHypervisor;
use Entity::Host::Hypervisor::Opennebula3Hypervisor::Opennebula3KvmHypervisor;
use Entity::Host::VirtualMachine;
use Entity::Host::VirtualMachine::Opennebula3Vm;
use Entity::Host::VirtualMachine::Opennebula3Vm::Opennebula3KvmVm;

use Log::Log4perl "get_logger";
use Data::Dumper;
use Administrator;
use General;
use Entity::Kernel;
use Entity::Host qw(get new);

my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    install_dir => {
        label        => 'Installation directory',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 0
    },
    host_monitoring_interval => {
        label        => 'Host monitoring interval',
        type         => 'string',
        pattern      => '^\d*$',
        is_mandatory => 1,
        is_editable  => 1
    },
    vm_polling_interval => {
        label        => 'VM polling interval',
        type         => 'string',
        pattern      => '^\d*$',
        is_mandatory => 1,
        is_editable  => 1
    },
    vm_dir => {
        label        => 'VM directory',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 0
    },
    scripts_remote_dir => {
        label        => 'Scripts remote directory',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 0
    },
    image_repository_path => {
        label        => 'Images repository path',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 0
    },
    port => {
        label        => 'Port',
        type         => 'string',
        pattern      => '^\d*$',
        is_mandatory => 1,
        is_editable  => 1
    },
    hypervisor => {
        label        => 'Hypervisor',
        type         => 'enum',
        options      => ['kvm','xen'],
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1
    },
    debug_level => {
        label        => 'Debug level',
        type         => 'enum',
        options      => ['0','1','2','3'],
        pattern      => '^\d*$',
        is_mandatory => 1,
        is_editable  => 1
    },
    overcommitment_cpu_factor => {
        label        => 'Overcommitment cpu factor',
        type         => 'string',
        pattern      => '^\d*$',
        is_mandatory => 1,
        is_editable  => 1
    },
    overcommitment_memory_factor => {
        label        => '0vercommitment memory factor',
        type         => 'string',
        pattern      => '^\d*$',
        is_mandatory => 1,
        is_editable  => 1
    },
    opennebula3_repositories => {
        label       => 'Virtual machine images repositories',
        type        => 'relation',
        relation    => 'single_multi',
        is_editable => 1,
    },
    opennebula3_hypervisors => {
        label       => 'Hypervisors',
        type        => 'relation',
        relation    => 'single_multi',
        is_editable => 0,
    }
};

sub getAttrDef { return ATTR_DEF; }

sub getBaseConfiguration {
    return {
        install_dir => '/srv/cloud/one',
        host_monitoring_interval => '600',
        vm_polling_interval => '600',
        vm_dir => '/srv/cloud/one/var',
        scripts_remote_dir => '/var/tmp/one',
        image_repository_path => '/srv/cloud/images',
        port => '2633',
        hypervisor => 'kvm',
        debug_level => '3',
        overcommitment_cpu_factor => '1',
        overcommitment_memory_factor => '1'
    };
}

sub methods {
    return {
        getHypervisors  => {
            description => 'get hypervisors',
            perm_holder => 'entity'
        },
        optimiaas  => {
            description => 'optimize IaaS (packing)',
            perm_holder => 'entity'
        },
    };
}


sub getOvercommitmentFactors {
    my ($self) = @_;
    return {
        overcommitment_cpu_factor    => $self->overcommitment_cpu_factor,
        overcommitment_memory_factor => $self->overcommitment_memory_factor,
    }
}


=head2 getHypervisors

=cut

sub getHypervisors {
    my $self = shift;

    my @hypervisors = Entity::Host::Hypervisor::Opennebula3Hypervisor->search(hash => { opennebula3_id => $self->getId });
    return wantarray ? @hypervisors : \@hypervisors;
}

=head2 getHypervisorType

=cut

sub getHypervisorType {
    my ($self) = @_;
    return $self->hypervisor;
}

=head2 checkHostManagerParams

=cut

sub checkHostManagerParams {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'ram', 'core' ]);
}

sub checkScaleMemory {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);

    my $node = $args{host}->node;

    my $indicator_oid = 'XenTotalMemory'; # Memory Total
    my $indicator_id  = Indicator->find(hash => { 'indicator_oid'  => $indicator_oid })->getId();

    my $raw_data = $node->getMonitoringData(raw => 1, time_span => 600, indicator_ids => [$indicator_id]);

    $log->info(Dumper $raw_data);
    my $ram_current = pop @{$raw_data->{$indicator_oid}};
    my $ram_before  = pop @{$raw_data->{$indicator_oid}};

    return {ram_current => $ram_current, ram_before => $ram_before};
}

=head2 getPolicyParams

=cut

sub getPolicyParams {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'policy_type' ]);

    if ($args{policy_type} eq 'hosting') {
        return [ { name => 'max_core', label => 'Maximum CPU number', pattern => '^[0-9]+$' },
                 { name => 'core',     label => 'Initial CPU number', pattern => '^[0-9]+$' },
                 { name => 'max_ram',  label => 'Maximum RAM amount', pattern => '^[0-9]+$' },
                 { name => 'ram',      label => 'Initial RAM amount', pattern => '^[0-9]+$' },
                 { name => 'ram_unit', label => 'RAM unit',   values => [ 'M', 'G' ] } ];
    }
    return [];
}

=head2 getBootPolicies

    Desc: return a list containing boot policies available

=cut

sub getBootPolicies {
    return (Manager::HostManager->BOOT_POLICIES->{pxe_iscsi},
            Manager::HostManager->BOOT_POLICIES->{pxe_nfs},
            Manager::HostManager->BOOT_POLICIES->{virtual_disk});
}

sub getHostType {
    return "Virtual Machine";
}

sub getConf {
    my $self = shift;
    my %conf = ();
    my $confindb = $self->{_dbix};
    if($confindb) {
        %conf = $confindb->get_columns();
    }

    my @repositories = ();
    my @available_accesses = ();
    my @hypervisors = ();
    my @vms = ();

    my $repo_rs = $confindb->opennebula3_repositories;
    while (my $repo_row = $repo_rs->next) {
        my $container_access = Entity::ContainerAccess->get(
                                   id => $repo_row->get_column('container_access_id')
                               );
        push @repositories, {
            repository_name         => $repo_row->get_column('repository_name'),
            container_access_export => $container_access->getAttr(name => 'container_access_export'),
            container_access_id     => $repo_row->get_column('container_access_id'),
            datastore_id            => $repo_row->get_column('datastore_id'),
        }
    }

    my @container_accesses = Entity::ContainerAccess::NfsContainerAccess->search(hash => {});
    for my $access (@container_accesses) {
        push @available_accesses, {
            container_access_id   => $access->getAttr(name => 'container_access_id'),
            container_access_name => $access->getAttr(name => 'container_access_export'),
        }
    }

    my @hyper_rs = Entity::Host::Hypervisor::Opennebula3Hypervisor->search(hash => { opennebula3_id => $self->getId });
    for my $hyper (@hyper_rs) {
        my @vms_rs = $hyper->getVms();

        push @hypervisors, {
                onehost_id             => $hyper->onehost_id,
                opennebula3_hypervisor_id => $hyper->getId,
                vms                       => \@vms_rs,
                nbrevms                   => scalar(@vms_rs)
        };

        for my $vm (@vms_rs) {
            my $vm_id = $vm->getId;
            push @vms, {
                vm_id                     => $vm->onevm_id,
                opennebula3_hypervisor_id => $hyper->getId,
                vm_host_id                => $vm_id,
                url                       => "/infrastructures/hosts/$vm_id"
            };
        }
    }

    $conf{container_accesses}       = \@available_accesses;
    $conf{opennebula3_repositories} = \@repositories;
    $conf{opennebula3_hypervisors}  = \@hypervisors;
    $conf{opennebula3_vms}          = \@vms;
    $conf{opennebula3_hypervisor}   = $conf{"hypervisor"};

    return \%conf;
}

sub setConf {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['conf']);

    my $conf = $args{conf};
    my $repos = $conf->{opennebula3_repositories};
    delete $conf->{opennebula3_repositories};

    # main config
    if (not $conf->{opennebula3_id}) {
        $self->{_dbix}->create($conf);
    } else {
        $self->{_dbix}->update($conf);
    }
    
    # repositories config
    $self->{_dbix}->opennebula3_repositories->delete_all;
    foreach my $repo (@$repos) {
        if(exists $repo->{opennebula3_repository_id}) {
            delete $repo->{opennebula3_repository_id};
        }
        $self->{_dbix}->opennebula3_repositories->create($repo);
    }
}

sub getNetConf {
    my $self = shift;
    my $port = $self->port;
    return { $port => ['tcp'] };
}

sub needBridge {
    return 1;
}

sub getTemplateDataOned {
    my $self = shift;
    my %data = $self->{_dbix}->get_columns();
    delete $data{opennebula3_id};
    delete $data{component_instance_id};
    return \%data;
}

sub getTemplateDataOnedInitScript {
    my $self = shift;

    my $data = { install_dir => $self->install_dir };
    return $data;
}

### hypervisors manipulation ###

=head2 getVmResources

    Promote the selected host to an hypervisor type.
    Real declaration in opennebula must have been done
    since `onehost_id` is required.

=cut

sub addHypervisor {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'host', 'onehost_id' ]);

    my $hypervisor_type = 'Entity::Host::Hypervisor::Opennebula3Hypervisor::';
    if ($self->hypervisor eq 'xen') {
        $hypervisor_type .= 'Opennebula3XenHypervisor';
    } else {
        $hypervisor_type .= 'Opennebula3KvmHypervisor';
    }

    return $hypervisor_type->promote(
               promoted       => $args{host},
               opennebula3_id => $self->id,
               onehost_id     => $args{onehost_id}
           );
}

sub removeHypervisor {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);

    Entity::Host->demote(demoted => $args{host}->_getEntity);
}

### VMs manipulations ###

sub addVM {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'hypervisor', 'host', 'id' ]);

    my $vmtype  = 'Entity::Host::VirtualMachine::Opennebula3Vm';
    if ($self->hypervisor eq 'kvm') {
        $vmtype .= '::Opennebula3KvmVm';
    }

    my $opennebulavm = $vmtype->promote(
                           promoted       => $args{host},
                           opennebula3_id => $self->id,
                           onevm_id       => $args{id},
                       );

    if ($self->hypervisor eq 'kvm') {
        my $cluster = Entity->get(id => $args{host}->getClusterId());
        my $host_params = $cluster->getManagerParameters(manager_type => 'host_manager');

        $opennebulavm->setAttr(name => 'opennebula3_kvm_vm_cores',
                               value => $host_params->{max_core} || $args{host}->host_core);

    }
    $opennebulavm->setAttr(name => 'hypervisor_id', value => $args{hypervisor}->id);
    $opennebulavm->save();

    return $opennebulavm;
}

sub optimiaas {
    my ($self, %args) = @_;
    my $wf_params = {
        context => {
            cloudmanager_comp => $self,
        }
    };

    return Entity::Workflow->run(name => 'OptimiaasWorkflow', params => $wf_params);

}

sub migrate {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host_id', 'hypervisor_id' ]);

    my $hypervisor = Entity->get(id => $args{hypervisor_id});
    my $wf_params = {
        context => {
            vm   => Entity->get(id => $args{host_id}),
            host => $hypervisor,
            cloudmanager_comp => $self
        }
    };

    return Entity::Workflow->run(
        name       => 'MigrateWorkflow',
        related_id => $hypervisor->getClusterId(),
        params     => $wf_params
    );
}

# Execute host migration to a new hypervisor
sub migrateHost {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'host', 'hypervisor_dst', 'hypervisor_cluster' ]);

    $log->info('Migrating host <' . $args{host}->getId . '> to hypervisor ' . $args{hypervisor_dst}->getId);

    $args{host}->setAttr(name => 'hypervisor_id', value => $args{hypervisor_dst}->getId);
    $args{host}->save();
}

sub getImageRepository {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => ['container_access_id']);

    my $row = $self->{_dbix}->opennebula3_repositories->search( {
                  container_access_id => $args{container_access_id} }
              )->single;

    if (not defined $row) {
        throw Kanopya::Exception::Internal(error => "No repository configured for OpenNebula " . $self->id);
    }

    return $row->get_columns();
}

sub supportHotConfiguration {
    return 1;
}

sub getRemoteSessionURL {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['host']);

    return "vnc://" . $args{host}->hypervisor->getAdminIp() . ":" . $args{host}->vnc_port;
}

=head1 DIAGNOSTICS

Exceptions are thrown when mandatory arguments are missing.
Exception : Kanopya::Exception::Internal::IncorrectParam

=head1 CONFIGURATION AND ENVIRONMENT

This module need to be used into Kanopya environment. (see Kanopya presentation)
This module is a part of Administrator package so refers to Administrator configuration

=head1 DEPENDENCIES

This module depends of

=over

=item KanopyaException module used to throw exceptions managed by handling programs

=item Entity::Component module which is its mother class implementing global component method

=back

=head1 INCOMPATIBILITIES

None

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to <Maintainer name(s)> (<contact address>)

Patches are welcome.

=head1 AUTHOR

<HederaTech Dev Team> (<dev@hederatech.com>)

=head1 LICENCE AND COPYRIGHT

Kanopya Copyright (C) 2009, 2010, 2011, 2012, 2013 Hedera Technology.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; see the file COPYING.  If not, write to the
Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
Boston, MA 02110-1301 USA.

=cut

1;
