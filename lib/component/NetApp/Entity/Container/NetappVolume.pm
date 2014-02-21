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

Concrete class for NetApp volume containers. A NetApp volume container represent
a volume created on a NetApp equipment, and it is provided by a NetAppVolumeManager
component installed on a NetApp service provicer. It extends base container
by specifying the NetApp aggregate on wich is created the volume.

@since    2012-Mar-12
@instance hash
@self     $self

=end classdoc

=cut

package Entity::Container::NetappVolume;
use base "Entity::Container";

use strict;
use warnings;

use constant ATTR_DEF => {
    aggregate_id => {
        pattern      => '^[0-9\.]*$',
        is_mandatory => 1,
        is_extended  => 0,
    },
};

sub getAttrDef { return ATTR_DEF; }


=pod

=begin classdoc

Accessor to get the path of the volume within the NetApp equipment.

@return the volume path

=end classdoc

=cut

sub volumePath {
    my $self = shift;

    return '/vol/' . $self->getAttr(name => "container_name");
}

1;
