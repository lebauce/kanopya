# Snmpd5.pm - Snmpd server component (Adminstrator side)
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
# Created 4 sept 2010

package Entity::Component::Snmpd5;
use base "Entity::Component";

use strict;
use warnings;

use Kanopya::Config;
use Kanopya::Exceptions;
use Entity;
use Log::Log4perl "get_logger";

my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    monitor_server_ip => {
        label        => 'SNMP Server IP',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1
    },
    snmpd_options => { 
        label        => 'SNMP agent options',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1
    },
};

sub getAttrDef { return ATTR_DEF; }

sub getNetConf {
    return { 161 => ['udp'] };
}

sub getBaseConfiguration {
    return {
        monitor_server_ip => '127.0.0.1',
        snmpd_options => "-Lsd -Lf /dev/null -u snmp -I -smux -p /var/run/snmpd.pid"
    };
}

sub insertDefaultExtendedConfiguration {
    my $self = shift;

    # If the collector manager is the KanopyaCollector, set the server ip
    # to Kanopya monitor master node.
    my $collector;
    eval {
         $collector = $self->service_provider->getManager(manager_type => 'CollectorManager');
    };
    if (defined $collector and $collector->component_type->component_name eq 'Kanopyacollector') {
        $self->monitor_server_ip($collector->getMasterNode->adminIp);
    }
}

sub getPuppetDefinition {
    my ($self, %args) = @_;

    return {
        manifest     => "class { 'kanopya::snmpd': }\n",
        dependencies => []
    };
}

1;
