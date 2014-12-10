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
# Created 16 july 2010


=pod
=begin classdoc

TODO

=end classdoc
=cut


package Entity::Network;
use base "Entity";

use Entity::Poolip;
use NetAddr::IP;

use constant ATTR_DEF => {
    network_name => {
        label        => 'Name',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_extended  => 0,
        is_editable  => 1,
    },
    network_addr => {
        label        => 'Network Address',
        pattern      => '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$',
        is_mandatory => 1,
        is_editable  => 1,
        description  => 'It is the network address (eg. 10.0.0.0 or 172.23.32.128)',
    },
    network_netmask => {
        label        => 'Netmask',
        pattern      => '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$',
        is_mandatory => 1,
        is_editable  => 1,
        description  => 'The netmask is the second part of your network definition.'.
                        'It specifies the size of the network. (eg 255.255.255.0 or 255.255.255.252)',
    },
    network_gateway => {
        label        => 'Gateway',
        pattern      => '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$',
        is_mandatory => 1,
        is_editable  => 1,
        description  => 'Gateway is an optional parameter to specify '.
                        'what is the ip of the gateway on this network',
    },
    poolips => {
        label        => 'Pools Ip',
        type         => 'relation',
        relation     => 'single_multi',
        is_mandatory => 0,
        is_editable  => 1,
        description  => 'It is the list of ip pools available on this network.'.
                        'This pools will be used by HCM to assigned ip adress to service instances',
    },
};

sub getAttrDef { return ATTR_DEF; }


=pod
=begin classdoc

Return a string representation of the entity

@return string representation of the entity

=end classdoc
=cut


sub toString {
    return shift->network_name;
}

sub cidr {
    my $self = shift;

    return NetAddr::IP->new($self->network_addr,
                            $self->network_netmask)->cidr;
}

1;
