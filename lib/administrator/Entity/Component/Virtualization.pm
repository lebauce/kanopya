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

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

package Entity::Component::Virtualization;
use base "Entity::Component";

use strict;
use warnings;

use constant ATTR_DEF => {
    overcommitment_cpu_factor => {
        label        => 'Overcommitment cpu factor',
        type         => 'string',
        pattern      => '^\d*$',
        is_mandatory => 1,
        is_editable  => 1
    },
    overcommitment_memory_factor => {
        label        => '0vercommitment memory factor',
        type         => 'string',
        pattern      => '^\d*$',
        is_mandatory => 1,
        is_editable  => 1
    },
};

sub getAttrDef { return ATTR_DEF };

sub getPuppetDefinition {
    my ($self, %args) = @_;

    my $definitions = "\n";

    return $definitions;
}

1;
