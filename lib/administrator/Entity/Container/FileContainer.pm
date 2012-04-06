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

package Entity::Container::FileContainer;
use base "Entity::Container";

use strict;
use warnings;

use Entity::Component::Lvm2;

use constant ATTR_DEF => {
    container_access_id => {
        pattern => '^[0-9\.]*$',
        is_mandatory => 1,
        is_extended => 0
    },
    file_name => {
        pattern => '^.*$',
        is_mandatory => 1,
        is_extended => 0
    },
    file_size => {
        pattern => '^[0-9\.]*$',
        is_mandatory => 1,
        is_extended => 0
    },
    file_filesystem => {
        pattern => '^.*$',
        is_mandatory => 1,
        is_extended => 0
    },
};

sub getAttrDef { return ATTR_DEF; }

=head2 getContainer

    desc: Return a hash that match container virtual attributes with
          Fileimagemanager specific container attributes values.

=cut

sub getContainer {
    my $self = shift;
    my %args = @_;

    my $container = {
        container_name       => $self->{_dbix}->get_column('file_name'),
        container_size       => $self->{_dbix}->get_column('file_size'),
        container_filesystem => $self->{_dbix}->get_column('file_filesystem'),
        # Freespace on a container has no sens for instance.
        container_freespace  => 0,
        container_device     => $self->{_dbix}->get_column('file_name') . '.img',
    };
}

1;
