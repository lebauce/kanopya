#    Copyright © 2012 Hedera Technology SAS
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
package Combination;

use strict;
use warnings;
use base 'BaseDB';
use Data::Dumper;
# logger
use Log::Log4perl "get_logger";
my $log = get_logger("");

use constant ATTR_DEF => {
    combination_id      =>  {pattern       => '^.*$',
                                 is_mandatory   => 0,
                                 is_extended    => 0,
                                 is_editable    => 0},
    class_type_id => {
        type         => 'relation',
        relation     => 'single',
        pattern      => '^\d*$',
        is_mandatory => 0,
        is_extended  => 0
    },
};

sub getAttrDef { return ATTR_DEF; }

sub delete {
    my $self = shift;
    my @conditions = (
        $self->aggregate_condition_left_combinations,
        $self->aggregate_condition_right_combinations,
        $self->nodemetric_condition_left_combinations,
        $self->nodemetric_condition_right_combinations,
    );

    while (@conditions) {
        (pop @conditions)->delete();
    }
    return $self->SUPER::delete();
};
sub deleteIfConstant {};
1;
