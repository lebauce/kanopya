#    Copyright © 2011 Hedera Technology SAS
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

Concrete class for local containers. A local container is used to consider
local files as containers, it is useful to proccess operations with other 
containers like copies.

@since    2012-Feb-23
@instance hash
@self     $self

=end classdoc

=cut

package Entity::Container::LocalContainer;
use base "Entity::Container";

use strict;
use warnings;

use constant ATTR_DEF => {};

sub getAttrDef { return ATTR_DEF; }


=pod

=begin classdoc

@constructor

Overrides the generic container constructor to fix values
that does not make sens for this type of container.

@return a local container instance

=end classdoc

=cut

sub new {
    my $class = shift;
    my %args = @_;

    $args{container_freespace} = 0;

    return $class->SUPER::new(%args);
}


=pod

=begin classdoc

Overrides the accessor of the disk manager to raise
the proper exception.

=end classdoc

=cut

sub disk_manager {
    my $class = shift;
    my %args = @_;

    throw Kanopya::Exception::Internal(
              error => "A local container is not managed by any disk manager"
          );
}

1;
