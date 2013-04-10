# Mysql5.pm - Mysql 5 component module (Adminstrator side)
#    Copyright © 2011 Hedera Technology SAS
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
# Created 12 sept 2010

package Entity::Component::Mysql5;
use base "Entity::Component";

use strict;
use warnings;

use Kanopya::Exceptions;
use Log::Log4perl "get_logger";

my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    mysql5_port        => {
        label          => 'Port',
        type           => 'string',
        pattern        => '^\d*$',
        is_mandatory   => 1,
        is_editable    => 1
    },
    mysql5_datadir     => { 
        label          => 'Data directory',
        type           => 'string',
        pattern        => '^.*$',
        is_mandatory   => 1,
        is_editable    => 1
    },
    mysql5_bindaddress => { 
        label          => 'Bind address',
        type           => 'string',
        pattern        => '^.*$',
        is_mandatory   => 1,
        is_editable    => 0
    },
};

sub getAttrDef { return ATTR_DEF; }

sub getBaseConfiguration {
    return {
        mysql5_port => 3306,
        mysql5_datadir => "/var/lib/mysql",
        mysql5_bindaddress => '0.0.0.0'
    };
}

sub getExecToTest {
    my $self = shift;

    return {
        mysql => {
            cmd         => 'netstat -lnpt | grep ' . $self->mysql5_port,
            answer      => '.+$',
            return_code => '0'
        }
    };
}

sub getPuppetDefinition {
    my ($self, %args) = @_;

    return "class { 'kanopya::mysql':\n" .
           "\tconfig_hash => {\n" .
           "\t\t'port' => '" . $self->mysql5_port . "',\n" .
           "\t\t'bind_address' => '" . $self->mysql5_bindaddress . "',\n" .
           "\t\t'datadir' => '" . $self->mysql5_datadir . "',\n" .
           "\t}\n" .
           "}\n";
}

1;
