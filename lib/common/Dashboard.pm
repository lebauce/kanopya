# Copyright © 2011-2013 Hedera Technology SAS
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

package Dashboard;
use base BaseDB;

use strict;
use warnings;

use Data::Dumper;
use Log::Log4perl 'get_logger';
my $log = get_logger("");

use constant ATTR_DEF => {
    dashboard_service_provider_id => {
        pattern      => '^\d+$',
        is_mandatory => 1,
        is_delegatee => 1,
    },
    dashboard_config => {
        pattern      => '^.*$',
        is_mandatory => 1,
    },
};

sub getAttrDef { return ATTR_DEF; }

sub methods { return {}; }

1;
