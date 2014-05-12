# Entity::Tag.pm  

#    Copyright © 2013 Hedera Technology SAS
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

package Entity::Tag;
use base "Entity";

use Kanopya::Exceptions;

use Log::Log4perl "get_logger";
use Data::Dumper;
my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    tag => {
        label        => 'tag',
        pattern      => '.*',
        is_mandatory => 1,
        is_editable  => 1,
    },
    entities => {
        label        => 'Tagged entities',
        type         => 'relation',
        relation     => 'multi',
        link_to      => 'entity',
        is_mandatory => 0,
        is_editable  => 1,
    },
};

sub getAttrDef { return ATTR_DEF; }

sub label {
    return shift->tag;
}

1;
