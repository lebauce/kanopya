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

use base "Entity::Component::Virtualization";
use base "Manager::HostManager::VirtualMachineManager";

use strict;
use warnings;

use Entity::Host::Hypervisor::OpenstackHypervisor;
use Entity::Host::VirtualMachine::OpenstackVm;

use Hash::Merge qw(merge);
use Log::Log4perl "get_logger";
my $log = get_logger("");

use constant ATTR_DEF => {
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

sub supportHotConfiguration {
    return 0;
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
    my @quantums = $self->quantums;
    my @glances = $self->glances;
    push @optionals, $quantums[0] if @quantums;
    push @optionals, $glances[0] if @glances;

    return merge($self->SUPER::getPuppetDefinition(%args), {
        novacontroller => {
            classes => {
                "kanopya::openstack::nova::controller" => {
                    admin_password => 'nova',
                    email => $self->service_provider->owner->user_email,
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

sub getHostsEntries {
    my $self = shift;

    my @entries;

    if ($self->keystone) {
        push @entries, $self->keystone->service_provider->getHostEntries();
    }
    if ($self->amqp) {
        push @entries,$self->amqp->service_provider->getHostEntries();
    }
    if ($self->mysql5) {
        push @entries, $self->mysql5->service_provider->getHostEntries();
    }
        
    for my $component (($self->vmms, $self->glances, $self->quantums)) {
        @entries = (@entries, $component->service_provider->getHostEntries());
    }

    return \@entries;
}

sub checkConfiguration {
    my $self = shift;

    for my $attr ("mysql5", "amqp", "keystone") {
        $self->checkAttribute(attribute => $attr);
    }

    my @glances = $self->glances;
    for my $component ($self->mysql5, $self->amqp, $self->keystone, @glances) {
        $self->checkDependency(component => $component);
    }
}


=pod
=begin classdoc

Return a list of hypervisors under the rule of this instance of manager

@return opnestack_hypervisors

=end classdoc
=cut

sub hypervisors {
    my $self = shift;

    my @hypervisors = $self->searchRelated(filters  => [ 'openstack_hypervisors' ],
                                           prefetch => [ 'node' ]);
    return \@hypervisors;
}


=pod
=begin classdoc

Return a list of active hypervisors ruled by this manager

@return active_hypervisors

=end classdoc
=cut

sub activeHypervisors {
    my $self = shift;

    my @hypervisors = $self->searchRelated(
                          filters => [ 'openstack_hypervisors' ],
                          hash    => { active => 1 }
                      );

    return wantarray ? @hypervisors : \@hypervisors;
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
               promoted                  => $args{host},
               nova_controller_id        => $self->id,
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
        my $linux = $vmm->service_provider->getComponent(category => "System");
        my $oldconf = $linux->getConf();
        my @mounts = (@{$oldconf->{linuxes_mount}}, @mountentries);
        $linux->setConf(conf => { linuxes_mount => \@mounts });
        $vmm->service_provider->update();
    }
}

1;
