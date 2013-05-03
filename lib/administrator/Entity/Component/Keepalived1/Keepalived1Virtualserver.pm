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

package Entity::Component::Keepalived1::Keepalived1Virtualserver;
use base 'BaseDB';

use constant ATTR_DEF => {
    virtualserver_name => {
        label        => 'Name',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1,
    },
    virtualserver_ip => {
        label        => 'Ip address',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1,
    },
    virtualserver_port => {
        label        => 'Port',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1,
    },
    virtualserver_protocol => {
        label        => 'Protocol',
        type         => 'enum',
        options      => ['TCP','UDP'],
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1,
    },
    virtualserver_lbalgo => {
        label        => 'Scheduling method',
        type         => 'enum',
        options      => ['rr','wrr','lc','wlc','lblc','lblcr','dh','sh','sed','nq'], 
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1,
    },
    virtualserver_lbkind => {
        label        => 'Network model',
        type         => 'enum',
        options      => ['NAT'],
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1,
    },
    component_id => {
        label       => 'Component',
        type        => 'relation',
        relation    => 'single_multi',
        is_editable => 1
    },

};

sub getAttrDef { return ATTR_DEF; }

1;
