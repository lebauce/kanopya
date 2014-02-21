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

Concrete class for NetApp lun containers. A NetApp lun container represent
a lun created on a NetApp equipment, and it is provided by a NetAppLunManager
component installed on a NetApp service provicer. It extends base container
by specifying the NetApp volume on wich is created the lun.

@since    2012-Mar-12
@instance hash
@self     $self

=end classdoc

=cut

package Entity::Container::NetappLun;
use base "Entity::Container";

use strict;
use warnings;

use constant ATTR_DEF => {
    volume_id => {
        pattern      => '^[0-9\.]*$',
        is_mandatory => 1,
        is_extended  => 0,
    },
};

sub getAttrDef { return ATTR_DEF; }


=pod

=begin classdoc

Accessor to get the volume on wich is created the lun.

@return the volume instance

=end classdoc

=cut

sub getVolume {
    my $self = shift;

    return Entity->get(id => $self->getAttr(name => "volume_id"));
}


=pod

=begin classdoc

Accessor to get the path of the lun within the NetApp equipment.

@return the lun path

=end classdoc

=cut

sub getPath {
    my $self = shift;

    return '/vol/' . $self->getVolume->getAttr(name => "container_name") .
           '/' . $self->getAttr(name => "container_name");
}

1;
