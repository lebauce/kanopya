#    Copyright © 2011-2013 Hedera Technology SAS
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

package Alert;
use parent 'BaseDB';

use constant ATTR_DEF => {
    entity_id => {
        pattern      => '^\d*$',
        is_mandatory => 0,
        is_extended  => 0
    },
    alert_message => {
        pattern      => '^.+$',
        is_mandatory => 0,
        is_extended  => 0
    },
    alert_message => {
        pattern      => '^.+$',
        is_mandatory => 0,
        is_extended  => 0
    },
};

sub getAttrDef { return ATTR_DEF; }

sub new {
    my ($class, %args) = @_;

    General::checkParams(args     => \%args, 
                         required => [ 'entity_id', 'alert_message', 'alert_signature' ]);

    return $class->SUPER::new(alert_date => \"CURRENT_DATE()",
                              alert_time => \"CURRENT_TIME()",
                              %args);
}

sub mark_resolved {
    my ($self) = @_;

    $self->setAttr(name => 'alert_active', value => 0, save => 1);
}

1;
