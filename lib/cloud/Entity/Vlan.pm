#    Copyright © 2011-2012 Hedera Technology SAS
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


=pod
=begin classdoc

TODO

=end classdoc
=cut

package Entity::Vlan;
use base "Entity";

use constant ATTR_DEF => {
    vlan_name => {
        label        => 'Name',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_extended  => 0,
        is_editable  => 1,
        description  => 'You can give a name to this VLAN (used to find the VLAN in the topology, '.
                        'e.g. admin, sdn, public, ...)',
    },
    vlan_number => {
        label        => 'Number',
        pattern      => '^\d*$',
        is_mandatory => 1,
        is_extended  => 0,
        is_editable  => 1,
        description  => 'The VLAN ID',
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
    my $self = shift;
    return "Vlan <" . $self->vlan_name . ">, number <" . $self->vlan_number . ">.";
}

1;
