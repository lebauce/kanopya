# HAProxy1.pm - HAProxy1 component
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

package Entity::Component::Haproxy1;
use base "Entity::Component";

use strict;
use warnings;

use Kanopya::Exceptions;

use Hash::Merge qw(merge);
use Log::Log4perl "get_logger";

my $log = get_logger("");

use constant ATTR_DEF => {
    haproxy1_listens => {
        label       => 'Listen entries',
        type        => 'relation',
        relation    => 'single_multi',
        is_editable => 1
    },
};

sub getAttrDef { return ATTR_DEF; }

sub getBaseConfiguration {
    return {}
}

sub getPuppetDefinition {
    my ($self, %args) = @_;

    my $manifest = $self->instanciatePuppetResource(
                       name => "kanopya::haproxy",
                   );

    my @listens = $self->haproxy1s_listen;
    for my $listen (@listens) {
        $manifest .= $self->instanciatePuppetResource(
                         resource => 'haproxy::listen',
                         name => $listen->listen_name,
                         params => {
                            ipaddress => $listen->listen_ip,
                            ports     => $listen->listen_port,
                            mode      => $listen->listen_mode,
                            options   => {
                                option => ['tcplog'],
                                balance => $listen->listen_balance
                            }
                        }
                     );
    }

    return merge($self->SUPER::getPuppetDefinition(%args), {
        haproxy => {
            manifest => $manifest
        }
    } );

}

1;
