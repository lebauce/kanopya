#    Copyright © 2011-2012 Hedera Technology SAS
#
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

package Entity::Component::Virtualization::Opennebula3;
use base "Entity::Component::Virtualization";
use base "Manager::HostManager::VirtualMachineManager";

use strict;
use warnings;

use General;
use Kanopya::Exceptions;
use Manager::HostManager;
use Entity::Workflow;
use Entity::Kernel;
use Entity::Host;
use Entity::ContainerAccess;
use Entity::ContainerAccess::NfsContainerAccess;
use Entity::Host::Hypervisor::Opennebula3Hypervisor;
use Entity::Host::VirtualMachine;
use Entity::Host::VirtualMachine::Opennebula3Vm;
use Entity::Host::VirtualMachine::Opennebula3Vm::Opennebula3KvmVm;
use Entity::Repository::Opennebula3Repository;

use Hash::Merge qw(merge);
use Log::Log4perl "get_logger";

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
    opennebula3_hypervisors => {
        label       => 'Hypervisors',
        type        => 'relation',
        relation    => 'single_multi',
        is_editable => 0,
    },
    opennebula3_repositories => {
        is_virtual => 1
    },
    # TODO: move this virtual attr to HostManager attr def when supported
    host_type => {
        is_virtual => 1
    }
};

sub getAttrDef { return ATTR_DEF; }

sub opennebula3Repositories {
    my $self = shift;

    return $self->repositories;
}

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
        overcommitment_memory_factor => 1,
        overcommitment_cpu_factor => 1
    };
}

sub hypervisors {
    my $self = shift;

    my @hypervisors = $self->opennebula3_hypervisors;
    return \@hypervisors;
}

sub activeHypervisors {
    my $self = shift;

    my @hypervisors = $self->searchRelated(
                          filters => ['opennebula3_hypervisors'],
                          hash    => { active => 1 }
                      );

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

    return { ram_current => $ram_current, ram_before => $ram_before };
}

sub getHostManagerParams {
    my $self = shift;
    my %args = @_;

    return {
        core => {
            label        => 'Initial CPU number',
            type         => 'integer',
            unit         => 'core(s)',
            pattern      => '^\d*$',
            is_mandatory => 1
        },
        ram => {
            label        => 'Initial RAM amount',
            type         => 'integer',
            unit         => 'byte',
            pattern      => '^\d*$',
            is_mandatory => 1
        },
        max_core => {
            label        => 'Maximum CPU number',
            type         => 'integer',
            unit         => 'core(s)',
            pattern      => '^\d*$',
            is_mandatory => 1
        },
        max_ram => {
            label        => 'Maximum RAM amount',
            type         => 'integer',
            unit         => 'byte',
            pattern      => '^\d*$',
            is_mandatory => 1
        }
    };
}

=head2 getBootPolicies

    Desc: return a list containing boot policies available

=cut

sub getBootPolicies {
    return (Manager::HostManager->BOOT_POLICIES->{pxe_iscsi},
            Manager::HostManager->BOOT_POLICIES->{pxe_nfs},
            Manager::HostManager->BOOT_POLICIES->{virtual_disk});
}

sub getConf {
    my $self = shift;
    my $conf = $self->SUPER::getConf();

    $conf->{opennebula3_repositories} = ();
    my @repositories = Entity::Repository::Opennebula3Repository->search(
        hash     => { virtualization_id => $self->id },
        prefetch => [ 'container_access' ],
    );
    foreach my $repo (@repositories) {
        my $container_access = $repo->container_access;
        push @{$conf->{opennebula3_repositories}}, {
            repository_name         => $repo->repository_name,
            container_access_export => $container_access->container_access_export,
            container_access_id     => $container_access->id,
            datastore_id            => $repo->datastore_id
        }
    }

    return $conf;
}

sub setConf {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['conf']);

    my $conf  = $args{conf};
    my $repos = delete $conf->{opennebula3_repositories};

    $self->SUPER::setConf(conf => $conf);

    my @repos = $self->repositories;
    foreach my $repo (@repos) {
        $repo->remove;
    }
    foreach my $repo (@{ $repos }) {
        if (exists $repo->{opennebula3_repository_id}) {
            delete $repo->{opennebula3_repository_id};
        }
        Entity::Repository::Opennebula3Repository->new(
            repository_name     => $repo->{repository_name},
            datastore_id        => $repo->{datastore_id},
            virtualization_id   => $self->id,
            container_access_id => $repo->{container_access_id}
        );
    }
}

sub getNetConf {
    my $self = shift;

    return {
        oned => {
            port => $self->port,
            protocols => ['tcp']
        }
    };
}

sub needBridge {
    return 1;
}

sub getHostsEntries {
    my $self = shift;
    my @hosts_entries = ();

    for my $vmm ($self->vmms) {
        foreach my $host ($vmm->service_provider->getHosts()) {
            push @hosts_entries, {
                fqdn    => $host->node->fqdn,
                aliases => [ $host->node->node_hostname ],
                ip      => $host->adminIp
            };
        }
    }

    return \@hosts_entries;
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

sub getPuppetDefinition {
    my ($self, %args) = @_;

    return merge($self->SUPER::getPuppetDefinition(%args), {
        opennebula => {
            manifest => $self->instanciatePuppetResource(
                            name => "kanopya::opennebula",
                        )
        }
    } );
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

    return Entity::Host::Hypervisor::Opennebula3Hypervisor->promote(
               promoted       => $args{host},
               opennebula3_id => $self->id,
               onehost_id     => $args{onehost_id}
           );
}

sub removeHypervisor {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);

    Entity::Host->demote(demoted => $args{host}->_entity);
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
        my $host_params = $cluster->getManagerParameters(manager_type => 'HostManager');

        $opennebulavm->setAttr(name => 'opennebula3_kvm_vm_cores',
                               value => $host_params->{max_core} || $args{host}->host_core);

    }
    $opennebulavm->setAttr(name => 'hypervisor_id', value => $args{hypervisor}->id);
    $opennebulavm->save();

    return $opennebulavm;
}

sub getImageRepository {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => ['container_access_id']);

    return Entity::Repository::Opennebula3Repository->find(hash => {
        container_access_id => $args{container_access_id}
    });
}

sub supportHotConfiguration {
    return 1;
}

sub getRemoteSessionURL {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);

    return "vnc://" . $args{host}->hypervisor->adminIp . ":" . $args{host}->vnc_port;
}

1;
