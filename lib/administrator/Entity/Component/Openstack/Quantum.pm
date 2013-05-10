#    Copyright © 2011 Hedera Technology SAS
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

package  Entity::Component::Openstack::Quantum;
use base "Entity::Component";

use strict;
use warnings;

use Log::Log4perl "get_logger";
my $log = get_logger("");

use constant ATTR_DEF => {
};

sub getAttrDef { return ATTR_DEF; }

sub getPuppetDefinition {
    my ($self, %args) = @_;

    my $keystone = $self->nova_controller->keystone->getMasterNode->fqdn;
    my $amqp = $self->nova_controller->amqp->getMasterNode->fqdn;
    my $sql = $self->mysql5->getMasterNode->fqdn;

    return "class { 'kanopya::quantum_':\n" .
           "\tamqpserver => '" . $amqp . "',\n" .
           "\tkeystone   => '" . $keystone . "',\n" .
           "\tpassword   => 'quantum'," .
           "\tbridge_flat => 'br-flat'," .
           "\tbridge_vlan => 'br-vlan'," .
           "\temail      => '" . $self->service_provider->user->user_email . "',\n" .
           "\tdbserver   => '" . $sql . "'\n" .
           "}";
}

sub getHostsEntries {
    my $self = shift;

    my @entries = ($self->nova_controller->keystone->service_provider->getHostEntries(),
                   $self->nova_controller->amqp->service_provider->getHostEntries(),
                   $self->mysql5->service_provider->getHostEntries());

    return \@entries;
}

1;
