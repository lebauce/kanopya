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

package  Entity::Component::Openstack::NovaController;

use base "Entity::Component";
use base "Manager::HostManager::VirtualMachineManager";

use strict;
use warnings;

use Entity::Host::Hypervisor::OpenstackHypervisor;
use Entity::Host::VirtualMachine::OpenstackVm;

use Log::Log4perl "get_logger";
my $log = get_logger("");

use constant ATTR_DEF => {
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
        }
    };
}

sub checkHostManagerParams {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'ram', 'core' ]);
}

sub getBootPolicies {
    return (Manager::HostManager->BOOT_POLICIES->{virtual_disk}, );
}

sub supportHotConfiguration {
    return 0;
}

sub getPuppetDefinition {
    my ($self, %args) = @_;

    my $sql        = $self->mysql5;
    my $keystone   = $self->keystone;
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

sub hypervisors {
    my $self = shift;
    return $self->openstack_hypervisors;
}

sub activeHypervisors {
    my $self = shift;

    my @hypervisors = $self->searchRelated(
                          filters => [ 'hypervisors' ],
                          hash    => { active => 1 }
                      );

    return wantarray ? @hypervisors : \@hypervisors;
}

sub addHypervisor {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'host', 'uuid' ]);

    return Entity::Host::Hypervisor::OpenstackHypervisor->promote(
               promoted                  => $args{host},
               nova_controller_id        => $self->id,
               openstack_hypervisor_uuid => $args{uuid},
           );
}

sub removeHypervisor {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);

    Entity::Host->demote(demoted => $args{host}->_getEntity);
}

1;
