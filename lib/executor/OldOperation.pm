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

package OldOperation;
use base 'BaseDB';

use strict;
use warnings;

use Log::Log4perl 'get_logger';
use Data::Dumper;

my $log = get_logger("");

use constant ATTR_DEF => {
    operationtype_id => {
        pattern      => '^\d+$',
        is_mandatory => 0,
    },
    operation_id => {
        pattern      => '^\d+$',
        is_mandatory => 0,
    },
    workflow_id => {
        pattern      => '^\d+$',
        is_mandatory => 0,
    },
    user_id => {
        pattern      => '^\d+$',
        is_mandatory => 0,
    },
    priority => {
        pattern      => '^\d+$',
        is_mandatory => 0,
    },
    creation_date => {
        pattern      => '^.*$',
        is_mandatory => 0,
    },
    creation_time => {
        pattern      => '^.*$',
        is_mandatory => 0,
    },
    execution_date => {
        pattern      => '^.*$',
        is_mandatory => 0,
    },
    execution_time => {
        pattern      => '^.*$',
        is_mandatory => 0,
    },
    execution_status => {
        pattern      => '^ready|processing|prereported|postreported|waiting_validation|validated' .
                        '|failed|cancelled|succeeded|pending|statereported|interrupted|timeouted$',
        is_mandatory => 0,
    },
    type => {
        is_virtual   => 1,
    },
};

sub getAttrDef { return ATTR_DEF; }

sub type {
    my $self = shift;

    return $self->operationtype->operationtype_name;
}


1;
