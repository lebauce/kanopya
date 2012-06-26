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

package Entity::Billinglimit;
use base 'Entity';

use strict;
use warnings;

use Kanopya::Exceptions;

use Data::Dumper;
use Log::Log4perl 'get_logger';

my $log = get_logger('administrator');
my $errmsg;

use constant ATTR_DEF => {
    start => {
        pattern      => '^.*$',
        is_mandatory => 1,
        is_extended  => 0
    },
    end => {
        pattern      => '^.*$',
        is_mandatory => 1,
        is_extended  => 0
    },
    type => {
        pattern      => '^\d*$',
        is_mandatory => 1,
        is_extended  => 0
    },
    soft => {
        pattern      => '^\d*$',
        is_mandatory => 1,
        is_extended  => 0
    },
    service_provider_id => {
        pattern      => '^\d*$',
        is_mandatory => 1,
        is_extended  => 0
    },
    repeat => {
        pattern      => '^\d*$',
        is_mandatory => 0,
        is_extended  => 0
    },
    repeat_start_time => {
        pattern      => '^.*$',
        is_mandatory => 0,
        is_extended  => 0
    },
    repeat_end_time => {
        pattern      => '^.*$',
        is_mandatory => 0,
        is_extended  => 0
    },
    value => {
        pattern      => '^\d*$',
        is_mandatory => 1,
        is_extended  => 0
    }
};

sub getAttrDef { return ATTR_DEF; }

1;
