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

package Entity::Component::Iscsi::IscsiPortal;
use base 'BaseDB';

use constant ATTR_DEF => {
    iscsi_portal_ip => {
        label        => 'Portal IP',
        type         => 'string',
        pattern      => '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$',
        is_mandatory => 1,
        is_editable  => 1,
    },
    iscsi_portal_port => {
        label        => 'Port',
        type         => 'integer',
        pattern      => '^\d+$',
        is_mandatory => 1,
        is_editable  => 1,
    },
};

sub getAttrDef { return ATTR_DEF; }

sub label {
    my $self = shift;
    my %args = @_;

    return $self->iscsi_portal_ip . ':' . $self->iscsi_portal_port;
}

1;
