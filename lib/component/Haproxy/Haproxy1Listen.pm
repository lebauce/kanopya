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

package Haproxy1Listen;
use base BaseDB;

use strict;
use warnings;

use constant ATTR_DEF => {
    listen_name => {
        label       => 'Listen name',
        type        => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1
    },
    listen_ip => {
        label       => 'Listen ip',
        type        => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1
    },
    listen_port => {
        label       => 'Listen port',
        type        => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1,
        size         => 5
    },
    listen_mode => {
        label       => 'Listen mode',
        type        => 'enum',
        options      => ['tcp','http'],
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1
    },
    listen_balance => {
        label       => 'Listen balance',
        type        => 'enum',
        options      => ['roundrobin'],
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1
    },
    listen_component_id => {
        label       => 'Component',
        type        => 'relation',
        relation    => 'single',
        is_mandatory => 1,
        is_editable => 1
    },
    listen_component_port => {
        label       => 'Component port',
        type        => 'integer',
        pattern      => '^\d*$',
        is_mandatory => 1,
        is_editable  => 1,
        size         => 5
    },
};

sub getAttrDef { return ATTR_DEF; }

1;
