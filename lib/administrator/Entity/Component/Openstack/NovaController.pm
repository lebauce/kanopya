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

package  Entity::Component::Openstack::NovaController;
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

    my $sql        = $self->mysql5;
    my $keystone   = $self->keystone;
    my $definition = "if \$kanopya_openstack_repository == undef {\n" .
                     "\tclass { 'kanopya::openstack::repository': }\n" .
                     "\t\$kanopya_openstack_repository = 1\n" .
                     "}\n" .
                     "class { 'kanopya::novacontroller':\n" .
                     "\tdbserver => '$sql->service_provider->getMasterNode->fqdn',\n" .
                     "\tpassword => 'nova',\n" .
                     "\tkeystone => '$keystone->service_provider->getMasterNode->fqdn',\n" .
                     "\temail => '$self->service_provider->user->email',\n" .
                     "}\n";

    return $definition;
}

1;
