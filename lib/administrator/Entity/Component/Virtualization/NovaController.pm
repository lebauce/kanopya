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

use base "Entity::Component";
use base "Manager::HostManager::VirtualMachineManager";

use strict;
use warnings;

use Entity::Host::Hypervisor::OpenstackHypervisor;
use Entity::Host::VirtualMachine::OpenstackVm;

use Log::Log4perl "get_logger";
my $log = get_logger("");

use constant ATTR_DEF => {
    repositories => {
        label       => 'Virtual machine images repositories',
        type        => 'relation',
        relation    => 'single_multi',
        is_editable => 1,
        specialized => 'openstack_repository'
    },
    host_type => {
        is_virtual => 1
    }
};

sub getAttrDef { return ATTR_DEF; }

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
        },
    };
}

sub checkHostManagerParams {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'ram', 'core' ]);
}

=pod

=begin classdoc

Return the boot policies for the host ruled by this host manager

=end classdoc

=cut

sub getBootPolicies {
    return (Manager::HostManager->BOOT_POLICIES->{virtual_disk}, );
}

sub supportHotConfiguration {
    return 0;
}

sub hostType {
    return "OpenStack VM";
}

=pod

=begin classdoc

Return the type of host managed

@return "OpenStack VM"

=end classdoc

=cut

=pod

=begin classdoc

Build the content of the puppet agent manifest for a node

@return definition

=end classdoc

=cut

sub getPuppetDefinition {
    my ($self, %args) = @_;

    my $sql        = $self->mysql5;
    my $keystone   = $self->keystone;
    my $quantum    = ($self->quantums)[0];
    my $glance     = join(",", map { $_->service_provider->getMasterNode->fqdn . ":9292" } $self->nova_controller->glances);

    if (not ($sql and $keystone and $quantum)) {
        return;
    }

    my $definition = "if \$kanopya_openstack_repository == undef {\n" .
                     "\tclass { 'kanopya::openstack::repository': }\n" .
                     "\t\$kanopya_openstack_repository = 1\n" .
                     "}\n" .
                     "class { 'kanopya::novacontroller':\n" .
                     "\tdbserver => '" . $sql->service_provider->getMasterNode->fqdn . "',\n" .
                     "\tamqpserver => '" . $self->amqp->service_provider->getMasterNode->fqdn . "',\n" .
                     "\tpassword => 'nova',\n" .
                     "\tkeystone => '" . $keystone->service_provider->getMasterNode->fqdn . "',\n" .
                     "\temail => '" . $self->service_provider->user->user_email . "',\n" .
                     "\tglance => '" . $glance . "',\n" .
                     "\tquantum => '" . $quantum->service_provider->getMasterNode->fqdn . "',\n" .
                     "}\n";

    return $definition;
}

sub getHostsEntries {
    my $self = shift;

    my @entries = ($self->keystone->service_provider->getHostEntries(),
                   $self->amqp->service_provider->getHostEntries(),
                   $self->mysql5->service_provider->getHostEntries());

    for my $component (($self->novas_compute, $self->glances, $self->quantums)) {
        @entries = (@entries, $component->service_provider->getHostEntries());
    }

    return \@entries;
}

=pod

=begin classdoc

Return a list of hypervisors under the rule of this instance of manager

@return opnestack_hypervisors

=end classdoc

=cut

sub hypervisors {
    my $self = shift;
    return $self->openstack_hypervisors;
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
                          filters => [ 'hypervisors' ],
                          hash    => { active => 1 }
                      );

    return wantarray ? @hypervisors : \@hypervisors;
}

=pod

=begin classdoc

Promote a host to the Entity::Host::Hypervisor::OpenstackHypervisor- class

àreturn OpenstackHypervisor instance of OpenstackHypervisor

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

Demote an OpenStack hypervisor to the Entity::Host::Hypervisor class

@return Hypervisor an instance of Hypervisor

=end classdoc

=cut

sub removeHypervisor {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);

    Entity::Host->demote(demoted => $args{host}->_getEntity);
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
