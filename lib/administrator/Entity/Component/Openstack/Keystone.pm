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
use Hash::Merge qw(merge);

my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    mysql5_id => {
        label        => 'Database server',
        type         => 'relation',
        relation     => 'single',
        pattern      => '^\d*$',
        is_mandatory => 0,
        is_editable  => 1,
    },
};

sub getAttrDef { return ATTR_DEF; }

sub getNetConf {
    return {
        keystone_service => {
            port => 5000,
            protocols => ['tcp']
        },
        keystone_admin => {
            port => 35357,
            protocols => ['tcp']
        }
    };
}

sub getPuppetDefinition {
    my ($self, %args) = @_;
    my $definition = $self->SUPER::getPuppetDefinition(%args);

    my $sql = $self->mysql5;
    my $name = "keystone-" . $self->id;

    if (ref($sql) ne 'Entity::Component::Mysql5') {
        throw Kanopya::Exception::Internal(
            error => "Only mysql is currently supported as DB backend"
        );
    }

    return merge($definition, {
        keystone => {
            classes => {
                'kanopya::openstack::keystone' => {
                    admin_password => 'keystone',
                    email => $self->service_provider->owner->user_email,
                    database_user => $name,
                    database_name => $name,
                }
            },
            dependencies => [ $sql ]
        }
    } );
}

sub getHostsEntries {
    my $self = shift;

    my @entries = $self->mysql5->service_provider->getHostEntries();

    return \@entries;
}

sub checkConfiguration {
    my $self = shift;

    $self->checkAttribute(attribute => "mysql5");
    $self->checkDependency(component => $self->mysql5);
}

1;
