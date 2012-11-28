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

package Entity::Component::Apache2::Apache2Virtualhost;
use base 'BaseDB';

use strict;
use warnings;

use constant ATTR_DEF => {
    apache2_virtualhost_servername => {
        label        => 'Server Name',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1,
    },
    apache2_virtualhost_sslenable => {
        label        => 'Enable SSL',
        type         => 'boolean',
        is_mandatory => 1,
        is_editable  => 1,
    },
    apache2_virtualhost_serveradmin => {
        label        => 'Email',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1,
    },
    apache2_virtualhost_documentroot => {
        label        => 'Document Root',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1,
    },
    apache2_virtualhost_log => {
        label        => 'Access Log file',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1,
    },
    apache2_virtualhost_errorlog => {
        label        => 'Errors Log file',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1,
    }
};

sub getAttrDef { return ATTR_DEF; }

1;
