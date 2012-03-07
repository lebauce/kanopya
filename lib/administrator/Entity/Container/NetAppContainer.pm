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

package Entity::Container::NetAppContainer;
use base "Entity::Container";

use strict;
use warnings;

use Netapp::Filer;

use constant ATTR_DEF => {
    volume_id =>  {
        pattern => '^[0-9\.]*$',
        is_mandatory => 1,
        is_extended => 0,
    },
};

sub getAttrDef { return ATTR_DEF; }

=head2 getContainer

    desc :

=cut

sub getContainer {
    my $self = shift;
    my %args = @_;

    my $netapp = Entity::Connector::NetApp->get(
        id => $self->{_dbix}->parent->get_column('disk_manager_id')
    );

    return $netapp->getContainer(volume_id => $self->{_dbix}->get_column('volume_id'));
}

=head2 getDiskManager
    
    desc:

=cut

sub getDiskManager {
    my $self = shift;

    return Entity::Connector::NetApp->get(id => $self->getAttr(name => 'disk_manager_id'));
}

1;
