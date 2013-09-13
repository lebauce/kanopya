#    Copyright © 2012 Hedera Technology SAS
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

package LinuxMount;
use base BaseDB;

use strict;
use warnings;

use constant ATTR_DEF => {
    linux_mount_device => {
        label        => 'Device',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1,
    },
    linux_mount_point => {
        label        => 'Mount point',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1,
    },
    linux_mount_filesystem => {
        label        => 'Filesystem',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1,
    },
    linux_mount_options => {
        label        => 'Options',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 0,
        is_editable  => 1,
    },
    linux_mount_dumpfreq => {
        label        => 'Dump',
        type         => 'string',
        pattern      => '^\d$',
        is_mandatory => 0,
        is_editable  => 1,
    },
    linux_mount_passnum => {
        label        => 'Pass',
        type         => 'string',
        pattern      => '^\d$',
        is_mandatory => 0,
        is_editable  => 1,
    },
};

sub getAttrDef { return ATTR_DEF; }

1;
