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

package Entity::ContainerAccess::IscsiContainerAccess;
use base "Entity::ContainerAccess";

use strict;
use warnings;

use constant ATTR_DEF => {
    target_name => {
        pattern => '^.*$',
        is_mandatory => 1,
        is_extended => 0
    },
    iomode => {
        pattern => '^.*$',
        is_mandatory => 1,
        is_extended => 0
    },
    typeio => {
        pattern => '^.*$',
        is_mandatory => 1,
        is_extended => 0
    },
};

sub getAttrDef { return ATTR_DEF; }

=head2 getContainerAccess

    desc: Return a hash that match container virtual attributes with
          Iscsitarget1 specific container attributes values.

=cut

sub getContainerAccess {
    my $self = shift;
    my %args = @_;

    # Cannot use getAttr here, to avoid infinite recursion as
    # getContainer method is called from getAttr parent class.
    my $export_manager = Entity->get(
                             id => $self->getAttr(name => "export_manager_id"),
                         );

    return $export_manager->getContainerAccess(container_access => $self);
}

=head2 getExportManager

    desc: Return the component/conector that manages this container access.

=cut

sub getExportManager {
    my $self = shift;

    return Entity->get(id => $self->getAttr(name => 'export_manager_id'));
}

1;
