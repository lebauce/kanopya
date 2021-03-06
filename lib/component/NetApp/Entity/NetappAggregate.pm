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

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

=pod
=begin classdoc

TODO

=end classdoc
=cut

package Entity::NetappAggregate;
use base "Entity";

use Kanopya::Exceptions;

use constant ATTR_DEF => {
    name => {
        pattern      => '^.*$',
        is_mandatory => 1,
        is_extended  => 0
    },
    netapp_id => {
        pattern      => '^\d*$',
        is_mandatory => 1,
        is_extended  => 0
    }
};

sub getAttrDef { return ATTR_DEF; }


=pod
=begin classdoc

Override method to delete NetappVolumes properly

=end classdoc
=cut

sub remove {
    my $self = shift;

    my @navolumes = $self->netapp_volumes();
    while (@navolumes) {
        (pop @navolumes)->remove();
    }

    return $self->SUPER::remove();
};

1;
