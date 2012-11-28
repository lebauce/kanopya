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

Concrete class for local container accesses. A local container access is used to
access to containers locally the same way as a remote container, avoiding to 
export the disk and monting it loccally from the remote access protocol. 

@since    2012-Feb-23
@instance hash
@self     $self

=end classdoc

=cut

package Entity::ContainerAccess::LocalContainerAccess;
use base "Entity::ContainerAccess";

use strict;
use warnings;

use Entity::Container;

use constant ATTR_DEF => {};

sub getAttrDef { return ATTR_DEF; }


=pod

=begin classdoc

@constructor

Overrides the generic container access constructor to ensure that only one 
local access exists for a container.

@return a local container access instance

=end classdoc

=cut

sub new {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "container_id" ]);

    # Check if a local container access exists for this container.
    my $container = Entity::Container->get(id => $args{container_id});
    for my $access ($container->container_accesses) {
        if ($access->isa('Entity::ContainerAccess::LocalContainerAccess')) {
            throw Kanopya::Exception::Internal(
                      error => "A local access already exists for this container <$container>."
                  );
        }
    }

    # This type of export is not handled by a manager
    $args{export_manager_id} = 0;

    return $class->SUPER::new(%args);
}

1;
