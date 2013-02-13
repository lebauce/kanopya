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

package  Entity::Component::Openstack::Keystone;
use base "Entity::Component";

use strict;
use warnings;

use Kanopya::Exceptions;
use Log::Log4perl "get_logger";
my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
};

sub getAttrDef { return ATTR_DEF; }

sub getPuppetDefinition {
    my ($self, %args) = @_;

    my $definition;
    my $sqlconnection;
    my $sql = $self->mysql5;

    if (ref($sql) eq 'Entity::Component::Mysql5') {
        $sqlconnection  = 'mysql://keystone:keystone@';
        $sqlconnection .= $sql->service_provider->getMasterNodeIp;
        $sqlconnection .= '/keystone';
    }
    else {
        $errmsg = "Only mysql is currently supported as DB backend";
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    $definition = "if \$kanopya_openstack_repository == undef {
                       class { 'kanopya::openstack::repository': }
                       \$kanopya_openstack_repository = 1
                   }
                   class { 'keystone':
                         verbose        => true,
                         debug          => true,
                         sql_connection => '$sqlconnection',
                         catalog_type   => 'sql',
                         admin_token    => 'admin_token',
                         before => Class['keystone::roles::admin'],
                   }
                   exec { \"/usr/bin/keystone-manage db_sync\":
                         path => \"/usr/bin:/usr/sbin:/bin:/sbin\",
                   }\n";

    $definition .= "class { 'keystone::roles::admin':
                        email => '" . $self->service_provider->user->user_email . "',
                        password => 'pass',
                        require => Exec['/usr/bin/keystone-manage db_sync'],
                    }\n";
    $definition .= "class { 'kanopya::keystone': dbserver => \"" .
                   $sql->service_provider->getMasterNode->fqdn .
                   "\", password => \"keystone\" }\n";

    return $definition;
}

sub getHostsEntries {
    my $self = shift;

    return $self->mysql5->service_provider->getHostEntries();
}

1;
