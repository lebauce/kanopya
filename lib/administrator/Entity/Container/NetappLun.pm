#    Copyright © 2012 Hedera Technology SAS
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

package Entity::Container::NetappLun;
use base "Entity::Container";

use strict;
use warnings;

use constant ATTR_DEF => {
    volume_id => {
        pattern => '^[0-9\.]*$',
        is_mandatory => 1,
        is_extended => 0,
    },
    name => {
        pattern      => '^.*$',
        is_mandatory => 1,
        is_extended  => 0,
        is_editable  => 0
    },
    filesystem => {
        pattern      => '^\w*$',
        is_mandatory => 1,
        is_extended  => 0,
    },
    size => {
        pattern => '^[0-9]*$',
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

    my $manager = Entity::Connector::NetappLunManager->get(
        id => $self->{_dbix}->parent->get_column('disk_manager_id')
    );

    return $manager->getContainer(lun => $self);
}

=head2 getDiskManager
    
    desc:

=cut

sub getDiskManager {
    my $self = shift;

    return Entity->get(id => $self->getAttr(name => 'disk_manager_id'));
}

1;
