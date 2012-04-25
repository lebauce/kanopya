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

package Ip;
use base 'BaseDB';

use strict;
use warnings;

use Data::Dumper;
use Log::Log4perl 'get_logger';
use EntityComment;

my $log = get_logger('administrator');

use constant ATTR_DEF => {
    ip_addr => {
        pattern      => '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$',
        is_mandatory => 1,
        is_extended  => 0
    },
    poolip_id => {
        pattern      => '^\d+$',
        is_mandatory => 1,
        is_extended  => 0
    },
    iface_id => {
        pattern      => '^\d+$',
        is_mandatory => 0,
        is_extended  => 0
    },
};


sub getAttrDef { return ATTR_DEF; }

1;