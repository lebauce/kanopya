#    Copyright © 2014 Hedera Technology SAS
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

Execution lib for component OpenStack.

@see <package>Entity::Component::OpenStack</package>

=end classdoc
=cut

package EEntity::EComponent::EOpenStack;
use parent EEntity::EComponent;
use parent EManager::EHostManager::EVirtualMachineManager;

use strict;
use warnings;


=pod
=begin classdoc

Override the parent execution method to forward the call to the component entity.

@see <package>EManager::EHostManager</package>

=end classdoc
=cut

sub getFreeHost {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'flavor' ]);

    while ( my ($flavor_id, $flavor) = each (%{$self->param_preset->load->{flavors}})) {
        if ($flavor->{name} eq $args{flavor}) {
            $args{ram} = $flavor->{ram} * 1024 * 1024; # MB to B
            $args{core} = $flavor->{vcpus};
            last;
        }
    }
    return $self->_entity->getFreeHost(%args);
}

1;

