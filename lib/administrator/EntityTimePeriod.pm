# Copyright © 2013 Hedera Technology SAS
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

package EntityTimePeriod;
use base "BaseDB";

use strict;
use warnings;

use Kanopya::Exceptions;
use General;

use Log::Log4perl "get_logger";

my $log = get_logger("");

use constant ATTR_DEF => {
    entity_id => {
        label        => 'Entity',
        type         => 'relation',
        relation     => 'single',
        is_mandatory => 0,
        is_editable  => 1,
    },
    time_period_id => {
        label        => 'Time period',
        type         => 'relation',
        relation     => 'single',
        is_mandatory => 0,
        is_editable  => 1,
    }
};

sub getAttrDef { return ATTR_DEF; }

1;
