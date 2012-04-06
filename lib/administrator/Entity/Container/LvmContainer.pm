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

package Entity::Container::LvmContainer;
use base "Entity::Container";

use strict;
use warnings;

use Entity::Component::Lvm2;

use constant ATTR_DEF => {
    lv_id => {
        pattern => '^[0-9\.]*$',
        is_mandatory => 1,
        is_extended => 0
    },
};

sub getAttrDef { return ATTR_DEF; }

=head2 getContainer

    desc: Return a hash that match container virtual attributes with
          Lvm2 specific container attributes values.

=cut

sub getContainer {
    my $self = shift;
    my %args = @_;

    # Cannot use getAttr here, to avoid infinite recursion as
    # getContainer method is called from getAttr parent class.
    my $lvm2 = Entity::Component::Lvm2->get(
                   id => $self->{_dbix}->parent->get_column('disk_manager_id')
               );

    return $lvm2->getContainer(lv_id => $self->{_dbix}->get_column('lv_id'));
}

1;
