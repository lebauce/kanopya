# Copyright © 2012-2014 Hedera Technology SAS
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

package NotificationSubscription;
use base BaseDB;

use strict;
use warnings;
 
use Entity::Operation;

use Data::Dumper;
use Log::Log4perl 'get_logger';

my $log = get_logger("");

use constant ATTR_DEF => {
    subscriber_id => {
        pattern      => '^\d*$',
        is_mandatory => 1,
        is_delegatee => 1,
    },
    entity_id => {
        pattern      => '^\d*$',
        is_mandatory => 1,
    },
    operationtype_id => {
        pattern      => '^\d*$',
        is_mandatory => 0,
    },
    operation_state => {
        pattern      => '^' . join('|', Entity::Operation::OPERATION_STATES) . '$',
        is_mandatory => 1,
    },
    validation => {
        pattern      => '^[01]$',
        is_mandatory => 0,
    },
};

sub getAttrDef { return ATTR_DEF; }

sub methods { return {}; }

1;
