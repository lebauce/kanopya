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

use Hash::Merge qw(merge);
use Log::Log4perl "get_logger";

my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
};

sub getAttrDef { return ATTR_DEF; }

sub getNetConf {
    return {
        snmpd => {
            port => 161,
            protocols => [ 'udp' ]
        }
    };
}

sub getPuppetDefinition {
    my ($self, %args) = @_;

    my $collector = $self->service_provider->getManager(manager_type => 'CollectorManager');

    return merge($self->SUPER::getPuppetDefinition(%args), {
        snmpd => {
            manifest => $self->instanciatePuppetResource(
                            name => "kanopya::snmpd",
                            params => {
                                collector => $collector->getMasterNode->adminIp
                            }
                        )
        }
    } );
}

1;
