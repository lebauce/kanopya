# Copyright © 2011-2012 Hedera Technology SAS
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

package Harddisk;
use base 'BaseDB';

use strict;
use warnings;
use Log::Log4perl 'get_logger';

my $log = get_logger("");

use constant ATTR_DEF => {
    harddisk_device => {
        label        => 'root device',
        type         => 'string',
        pattern      => '^.*$',
        default      => 'autodetect',
        is_mandatory => 1,
        is_extended  => 0
    },
};

sub getAttrDef { return ATTR_DEF; }


=pod

=begin classdoc

Return class Host as delegateee class for Harddisk permissions.

@return the delegatee entity.

=end classdoc

=cut

sub getDelegatee {
    my ($self) = @_;
    my $class = ref $self;

    if (not $class) {
        return "Entity::Host";
    }
    else {
        return $self->host;
    }
}

1;
