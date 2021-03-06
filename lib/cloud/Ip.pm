# Copyright © 2011-2012 Hedera Technology SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

package Ip;
use base 'BaseDB';

use strict;
use warnings;
use NetAddr::IP;

use constant ATTR_DEF => {
    ip_addr => {
        pattern      => '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$',
        is_mandatory => 1,
        is_extended  => 0,
        description  => 'The IP address',
    },
    poolip_id => {
        pattern      => '^\d+$',
        is_mandatory => 0,
        is_extended  => 0,
        description  => 'The IP pool that contains this IP address',
    },
    iface_id => {
        pattern      => '^\d+$',
        is_mandatory => 0,
        is_extended  => 0,
        description  => 'The interface attached to this IP address',
    },
};

sub getAttrDef { return ATTR_DEF; }

sub _labelAttr {
    return 'ip_addr';
}

sub getStringFormat {
    my ($self) = @_;
    my $ipaddress = $self->ip_addr;
    my $netmask   = $self->poolip->network->network_netmask;
    my $ip = NetAddr::IP->new($ipaddress,$netmask);
    return "$ip";
}

1;
