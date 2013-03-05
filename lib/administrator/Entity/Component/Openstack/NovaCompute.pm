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

package  Entity::Component::Openstack::NovaCompute;
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

    my $glance = join(",", map { $_->getMasterNode->fqdn . ":9292" } $self->nova_controller->glances);
    my $keystone = $self->nova_controller->keystone->getMasterNode->fqdn;
    my $amqp = $self->nova_controller->amqp->getMasterNode->fqdn;
    my $sql = $self->mysql5->getMasterNode->fqdn;

    return "if \$kanopya_openstack_repository == undef {\n" .
           "\tclass { 'kanopya::openstack::repository': }\n" .
           "\t\$kanopya_openstack_repository = 1\n" .
           "}\n" .
           "class { 'kanopya::novacompute':\n" .
           "\tamqpserver => '" . $amqp . "',\n" .
           "\tdbserver => '" . $sql . "',\n" .
           "\tglance => '" . $glance . "',\n" .
           "\tkeystone => '" . $keystone . "',\n" .
           "\tpassword => 'nova'" .
           "}\n";
}

sub getHostsEntries {
    my $self = shift;

    my @entries;
    for my $glance ($self->nova_controller->glances) {
        @entries = (@entries, $glance->service_provider->getHostEntries());
    }

    @entries = ($self->nova_controller->keystone->service_provider->getHostEntries(),
                $self->nova_controller->amqp->service_provider->getHostEntries(),
                $self->mysql5->service_provider->getHostEntries());

    return \@entries;
}

1;
