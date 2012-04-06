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

package Entity::Container::NetappVolume;
use base "Entity::Container";

use strict;
use warnings;

use constant ATTR_DEF => {
    name => {
        pattern      => '^\w*$',
        is_mandatory => 1,
        is_extended  => 0,
        is_editable  => 0
    },
    size =>  {
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

    my $manager = Entity::Connector::NetappVolumeManager->get(
        id => $self->{_dbix}->parent->get_column('disk_manager_id')
    );

    return $manager->getContainer(volume_id => $self->{_dbix}->get_column('volume_id'));
}

1;
