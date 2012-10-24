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

package Entity::Component::Lvm2::Lvm2Vg;
use base 'BaseDB';

use constant ATTR_DEF => {
    lvm2_id => {
        type         => 'relation',
        relation     => 'single',
        pattern      => '^\d+$',
        is_mandatory => 1,
    },
    lvm2_vg_name => {
        label        => 'Name',
        type         => 'string',
        is_mandatory => 1,
        is_editable  => 0,
    },
    lvm2_vg_freespace => {
        label        => 'Free space',
        type         => 'string',
        unit         => 'byte',
        is_mandatory => 1,
        is_editable  => 0,
    },
    lvm2_vg_size => {
        label        => 'Total size',
        type         => 'string',
        unit         => 'byte',
        is_mandatory => 1,
        is_editable  => 0,
    },
};

sub getAttrDef { return ATTR_DEF; }

1;
