#    Copyright © 2013 Hedera Technology SAS
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

=pod
=begin classdoc

OpenStack component, used as host manager by Kanopya

=end classdoc
=cut

package  Entity::Component::Virtualization::NovaController;
use parent Entity::Component::Virtualization;
use parent Manager::HostManager::VirtualMachineManager;
use parent Manager::NetworkManager;

use strict;
use warnings;

use Kanopya::Exceptions;
use Entity::Host::Hypervisor::OpenstackHypervisor;
use Entity::Host::VirtualMachine::OpenstackVm;

use Hash::Merge qw(merge);
use TryCatch;

use Log::Log4perl "get_logger";
my $log = get_logger("");

use constant ATTR_DEF => {
    executor_component_id => {
        label        => 'Workflow manager',
        type         => 'relation',
        relation     => 'single',
        pattern      => '^[0-9\.]*$',
        is_mandatory => 1,
        is_editable  => 0,
    },
    repositories => {
        label       => 'Virtual machine images repositories',
        type        => 'relation',
        relation    => 'single_multi',
        is_editable => 1,
        specialized => 'OpenstackRepository'
    },
    amqp_id => {
        label       => 'Message queuing server',
        type        => 'relation',
        relation    => 'single',
        is_editable => 1
    },
    mysql5_id => {
        label       => 'Database server',
        type        => 'relation',
        relation    => 'single',
        is_editable => 1
    },
    keystone_id => {
        label       => 'Authentication server',
        type        => 'relation',
        relation    => 'single',
        is_editable => 1
    },
    kanopya_openstack_sync_id => {
        label       => 'OpenStack synchronization server',
        type        => 'relation',
        relation    => 'single',
        is_editable => 1
    },
    host_type => {
        is_virtual => 1
    }
};

sub getAttrDef { return ATTR_DEF; }

sub getNetConf {
    my $self = shift;

    my $conf = {
        novncproxy => {
            port => 6080,
            protocols => ['tcp']
        },
        ec2 => {
            port => 8773,
            protocols => ['tcp']
        },
        compute_api => {
            port => 8774,
            protocols => ['tcp']
        },
        metadata_api => {
            port => 8775,
            protocols => ['tcp']
        },
    };

    return $conf;
}


=pod
=begin classdoc

@return the manager params definition.

=end classdoc
=cut

sub getManagerParamsDef {
    my ($self, %args) = @_;

    return {
        %{ $self->SUPER::getManagerParamsDef },
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
        },
    };
}


sub checkHostManagerParams {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [ 'ram', 'core', 'max_core', 'max_ram' ]);
}


sub getHostManagerParams {
    my $self = shift;
    my %args = @_;

    my $definition = $self->getManagerParamsDef();
    return {
        core     => $definition->{core},
        ram      => $definition->{ram},
        max_core => $definition->{max_core},
        max_ram  => $definition->{max_ram},
    }
}


=pod
=begin classdoc

Return the boot policies for the host ruled by this host manager

=end classdoc
=cut

sub getBootPolicies {
    return (Manager::HostManager->BOOT_POLICIES->{virtual_disk},
            Manager::HostManager->BOOT_POLICIES->{pxe_iscsi},
            Manager::HostManager->BOOT_POLICIES->{pxe_nfs});
}


=pod
=begin classdoc

Build the content of the puppet agent manifest for a node

@return definition

=end classdoc
=cut

sub getPuppetDefinition {
    my ($self, %args) = @_;

    if (not ($self->mysql5 and $self->keystone)) {
        return;
    }

    my $definition = $self->SUPER::getPuppetDefinition(%args);
    my $name       = "nova-" . $self->id;

    my @optionals;
    my @neutrons = $self->neutrons;
    my @glances = $self->glances;
    push @optionals, $neutrons[0] if @neutrons;
    push @optionals, $glances[0] if @glances;

    return merge($self->SUPER::getPuppetDefinition(%args), {
        novacontroller => {
            classes => {
                "kanopya::openstack::nova::controller" => {
                    admin_password => 'nova',
                    email => $self->getMasterNode->owner->user_email,
                    database_user => $name,
                    database_name => $name,
                    rabbit_user => $name,
                    rabbit_virtualhost => 'openstack-' . $self->id,
                }
            },
            dependencies => [ $self->mysql5, $self->keystone, $self->amqp ],
            optionals => \@optionals
        }
    } );
}


=pod
=begin classdoc

NovaController depend on its keystone, amqp, mysql, computes, glances and neutrons if exists.

=end classdoc
=cut

sub getDependentComponents {
    my ($self, %args) = @_;

    my @entries = ($self->vmms, $self->glances, $self->neutrons);
    if ($self->keystone) {
        push @entries, $self->keystone;
    }
    if ($self->amqp) {
        push @entries, $self->amqp;
    }
    if ($self->mysql5) {
        push @entries, $self->mysql5;
    }
    return \@entries;
}


sub checkConfiguration {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, optional => { 'ignore' => [] });

    for my $attr ("mysql5", "amqp", "keystone") {
        $self->checkAttribute(attribute => $attr);
    }

    # Do not check configuration on vmms
    my @vmms = $self->vmms;
    my @ignore = (@vmms, @{ $args{ignore} });
    $self->SUPER::checkConfiguration(ignore => \@ignore);
}


=pod
=begin classdoc

Promote a host to the Entity::Host::Hypervisor::OpenstackHypervisor- class

@return OpenstackHypervisor instance of OpenstackHypervisor

=end classdoc
=cut

sub addHypervisor {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);

    return Entity::Host::Hypervisor::OpenstackHypervisor->promote(
               promoted => $self->SUPER::addHypervisor(host => $args{host}),
           );
}


=pod
=begin classdoc

Promote host into OpenstackVm and set its hypervisor id

@param host    host to promote
@param vm_uuid openstack uuid
@param hypervisor_id

@return the promoted host

=end classdoc
=cut

sub promoteVm {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => [ 'host', 'vm_uuid', 'hypervisor_id' ]);

     $args{host} = Entity::Host::VirtualMachine::OpenstackVm->promote(
                      promoted           => $args{host},
                      nova_controller_id => $self->id,
                      openstack_vm_uuid  => $args{vm_uuid},
                  );

    $args{host}->hypervisor_id($args{hypervisor_id});
    return $args{host};
}


=pod
=begin classdoc

Demote an OpenStack hypervisor to the Entity::Host::Hypervisor class

@return Hypervisor an instance of Hypervisor

=end classdoc
=cut

sub removeHypervisor {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);

    Entity::Host->demote(demoted => $args{host});
}


=pod
=begin classdoc

Set the configuration of the component.

If repositories are specified, update the mount entries of all compute nodes

=end classdoc
=cut

sub setConf {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'conf' ]);

    $self->SUPER::setConf(%args);

    # update linux mount table
    my @mountentries;
    for my $repository ($self->repositories) {
        push @mountentries, {
             linux_mount_dumpfreq   => 0,
             linux_mount_filesystem => 'nfs',
             linux_mount_point      => "/var/lib/nova/instances",
             linux_mount_device     => $repository->container_access->container_access_export,
             linux_mount_options    => 'rw,sync,vers=3',
             linux_mount_passnum    => 0,
        };

        # Don't know how to support multiple shared repositories
        last;
    }

    for my $vmm ($self->vmms) {
        try {
            my $linux = $vmm->getMasterNode->getComponent(category => "System");
            my $oldconf = $linux->getConf();
            my @mounts = (@{$oldconf->{linuxes_mount}}, @mountentries);
            $linux->setConf(conf => { linuxes_mount => \@mounts });
            $vmm->service_provider->update();
        }
        catch (Kanopya::Exception::Internal::NotFound $err) {
            # Component <NovaCompute> has no master node yet
            $log->warn("Unable to configure linux mounts, $err");
        }
    }
}


=pod
=begin classdoc

Override the update method to handle changes on the attribute kanopya_openstack_sync_id,
and register/unregister the nova controller to/from the OpenstackSync daemon.

If repositories are specified, update the mount entries of all compute nodes

=end classdoc
=cut

sub update {
    my ($self, %args) = @_;

    # Keept the openstack_sync ref as the update call could unset it
    my $openstack_sync = $self->kanopya_openstack_sync;

    my $updated = $self->SUPER::update(%args);

    # If kanopya_openstack_sync_id has change at update and component has nodes,
    # register/unregister the NovaController to/from the OpenstackSync daemon.
    if (exists $args{kanopya_openstack_sync_id} && scalar($self->nodes)) {
        if (defined $args{kanopya_openstack_sync_id}) {
            $self->registerToOpenstackSync(
                openstack_sync => $openstack_sync || $self->kanopya_openstack_sync
            );
        }
        else {
            $self->unregisterFromOpenstackSync(
                openstack_sync => $openstack_sync || $self->kanopya_openstack_sync
            );
        }
    }

    return $updated;
}

sub getRemoteSessionURL {
    return "";
}

sub registerToOpenstackSync {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, optional => { 'openstack_sync' => $self->kanopya_openstack_sync });

    try {
        $args{openstack_sync}->registerNovaController(nova_controller_id => $self->id);
    }
    catch ($err) {
        $log->warn("Unable to register NovaController to the OpenstackSync daemon:\n$err");
    }
}

sub unregisterFromOpenstackSync {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, optional => { 'openstack_sync' => $self->kanopya_openstack_sync });

    try {
        $args{openstack_sync}->unregisterNovaController(nova_controller_id => $self->id);
    }
    catch ($err) {
        $log->warn("Unable to unregister NovaController from the OpenstackSync daemon:\n$err");
    }
}

sub createVirtualHost {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, optional => { 'openstack_vm_uuid' => undef });

    return Entity::Host::VirtualMachine::OpenstackVm->promote(
               promoted           => $self->SUPER::createVirtualHost(%args),
               nova_controller_id => $self->id,
               openstack_vm_uuid  => $args{openstack_vm_uuid},
           );
}

sub applyVLAN {
    my ($self, %args) = @_;

    General::checkParams(
        args     => \%args,
        required => [ 'iface', 'vlan' ]
    );
}

1;
