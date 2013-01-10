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

=pod

=begin classdoc

TODO

=end classdoc

=cut

package UserProfile;
use base 'BaseDB';

use strict;
use warnings;

use constant ATTR_DEF => {};

sub getAttrDef { return ATTR_DEF; }


=pod

=begin classdoc

Override the creation to automatically add the user in the group
corresponding to the associated profile..

=end classdoc

=cut

sub new {
    my ($class, %args) = @_;

    my $self = $class->SUPER::new(%args);

    # Automatically add the user in the groups associated to this profile
    for my $group ($self->profile->gps) {
        $group->appendEntity(entity => $self->user);
    }
    return $self;
}

1;
