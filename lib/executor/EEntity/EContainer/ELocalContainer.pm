# Copyright © 2012 Hedera Technology SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

package EEntity::EContainer::ELocalContainer;
use base "EEntity::EContainer";

use strict;
use warnings;

use Entity::ContainerAccess::LocalContainerAccess;
use File::Basename;

use Log::Log4perl "get_logger";

use Data::Dumper;
my $log = get_logger("");

sub createDefaultExport {
    my $self = shift;
    my %args = @_;

    # Local container access are not handled by a manager
    return EEntity->new(entity => Entity::ContainerAccess::LocalContainerAccess->new(
               container_id      => $self->id,
               export_manager_id => 0,
           ));
}

sub removeDefaultExport {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'container_access' ]);

    # Local container access are not handled by a manager
    $args{container_access}->remove();
}

sub getMountPoint {
    my $self = shift;

    return "/mnt/local_" . $self->getAttr(name => 'container_name');
}

1;
