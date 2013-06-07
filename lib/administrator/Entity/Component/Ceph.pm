#    Copyright © 2013 Hedera Technology SAS
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

package  Entity::Component::Ceph;
use base "Entity::Component";

use strict;
use warnings;

use Hash::Merge qw(merge);
use Log::Log4perl "get_logger";

my $log = get_logger("");

use constant ATTR_DEF => {
    ceph_fsid => {
        label          => 'Ceph fsid',
        type           => 'string',
        pattern        => '^.*$',
        is_mandatory   => 0,
        is_editable    => 0  
    },
};

sub getAttrDef { return ATTR_DEF; }

sub _getNetwork {
    my ($self, $iface) = @_;

    my @netconfs = $iface->netconfs;
    my @poolips = (shift @netconfs)->poolips;
    return (shift @poolips)->network;
}

sub getPuppetDefinition {
    my ($self, %args) = @_;

    my $admin = $args{host}->getAdminIface;
    my $public = shift @{$args{host}->getIfaces(role => 'public')};

    my $admin_network = $self->_getNetwork($admin);
    my $public_network =  $public ? $self->_getNetwork($public) : $admin_network;
 
    return merge($self->SUPER::getPuppetDefinition(%args), {
        ceph => {
            manifest => $self->instanciatePuppetResource(
                            name => "kanopya::ceph",
                            params => {
                                fsid => $self->ceph_fsid,
                                cluster_network => $admin_network->cidr,
                                public_network => $public_network->cidr
                            }
                        )
        }
    } );
}

1;
