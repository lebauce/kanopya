# Copyright © 2011 Hedera Technology SAS
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

package ConnectorType;
use base 'BaseDB';

use strict;
use warnings;

use constant ATTR_DEF => {
    connector_name        => {
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_extended     => 0,
        is_editable     => 0
    },
    connector_version     => {
        pattern         => '^\d*$',
        is_mandatory    => 0,
        is_extended     => 0,
        is_editable     => 0
    },
    connector_category    => {
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_extended     => 0,
        is_editable     => 0
    }
};

sub getAttrDef { return ATTR_DEF; }


=pod

=begin classdoc

Return the delegatee entity on which the permissions must be checked.
By default, permissions are checked on the entity itself.

@return the delegatee entity.

=end classdoc

=cut


sub getDelegatee {
    my $self = shift;
    my $class = ref $self;

    if (not $class) {
        return 'Entity::Component';
    }

    return $self::SUPER->getDelegatee;
}

1;
