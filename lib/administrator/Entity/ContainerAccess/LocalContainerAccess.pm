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

package Entity::ContainerAccess::LocalContainerAccess;
use base "Entity::ContainerAccess";

use strict;
use warnings;

use Entity::Container;

use constant ATTR_DEF => {};

sub getAttrDef { return ATTR_DEF; }

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

    return $class->SUPER::new(%args);
}

1;
