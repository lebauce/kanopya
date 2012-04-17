# Entity::Vlan.pm  

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

=head1 NAME

Entity::Vlan

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

package Entity::Network::Vlan;
use base "Entity::Network";

use constant ATTR_DEF => {
    vlan_number => {
        pattern      => '^\d*$',
        is_mandatory => 1,
        is_extended  => 0,
        is_editable  => 0,
    },
};

sub getAttrDef { return ATTR_DEF; }

=head2 toString

    desc: return a string representation of the entity

=cut

sub toString {
    my $self = shift;
    return "Vlan <" . $self->getAttr(name => 'network_name') .
           ">, number <" . $self->getAttr(name => 'vlan_number') . ">.";
}

sub getNetworksPoolipsDbix {
    my $self = shift;
    return $self->{_dbix}->parent->network_poolips;
}

1;
