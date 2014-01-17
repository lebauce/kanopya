#    Copyright © 2012 Hedera Technology SAS
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

=pod
=begin classdoc

TODO

=end classdoc
=cut

package Keepalived1Vrrpinstance;
use base BaseDB;

use strict;
use warnings;


use Ip;

use constant ATTR_DEF => {
    vrrpinstance_name => {
        label        => 'Name',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1,
    },
    vrrpinstance_password => {
        label        => 'Password',
        type         => 'password',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1,
    },
    interface_id => {
        label        => 'Interface',
        pattern      => '^\d+$',
        type         => 'relation',
        relation     => 'single',
        is_mandatory => 1,
        is_editable  => 1
    },
    virtualip_id => {
        label        => 'Ip',
        type         => 'relation',
        relation     => 'single',
        is_mandatory => 0,
        is_editable  => 0
    },
    virtualip_interface_id => {
        label        => 'Ip interface',
        type         => 'relation',
        relation     => 'single',
        is_mandatory => 1,
        is_editable  => 1
    },
};

sub getAttrDef { return ATTR_DEF; }

=pod

=begin classdoc

Method redefined to free the associated ip of this vrrp instance

=end classdoc

=cut

sub remove {
    my $self = shift;

    my @netconfs = $self->virtualip_interface->netconfs;
    my @poolips  = $netconfs[0]->poolips;
    $poolips[0]->freeIp(ip => Ip->get(id => $self->virtualip_id));

    $self->SUPER::delete();
};

1;
