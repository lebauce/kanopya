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

sub getNetConf {
    my ($self) = @_;
    my $conf = {
         5000 => ['tcp'], # service port
        35357 => ['tcp'], # admin port
    };
    return $conf;
}

sub getPuppetDefinition {
    my ($self, %args) = @_;

    my $definition;
    my $sqlconnection;
    my $sql = $self->mysql5;

    if (ref($sql) ne 'Entity::Component::Mysql5') {
        $errmsg = "Only mysql is currently supported as DB backend";
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    $definition = "class { 'kanopya::openstack::keystone':\n" .
                  "    dbserver      => '" . $sql->getMasterNode->fqdn . "',\n" .
                  "    dbip          => '" . $sql->getMasterNode->adminIp . "',\n" .
                  "    dbpassword    => 'keystone',\n" .
                  "    adminpassword => 'keystone',\n" .
                  "    email         => '" . $self->service_provider->user->user_email . "',\n" .
                  "}\n";

    return $definition;
}

sub getHostsEntries {
    my $self = shift;

    my @entries = $self->mysql5->service_provider->getHostEntries();

    return \@entries;
}

1;
