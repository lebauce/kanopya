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
package Aggregate;

use strict;
use warnings;
use General;
use Statistics::Descriptive;
use base 'BaseDB';


use constant ATTR_DEF => {
    cluster_id               =>  {pattern       => '^.*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 0},
    indicator_id             =>  {pattern       => '^.*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 0},
    statistics_function_name =>  {pattern       => '^(mean|variance|standard_deviation|max|min)$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 0},
    window_time              =>  {pattern       => '^.*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 0},
};

sub getAttrDef { return ATTR_DEF; }

sub calculate{
    my $self = shift;
    my %args = @_;

    General::checkParams args => \%args, required => [
        'values',
    ];
    
    my $values  = $args{values};
    my $stat = Statistics::Descriptive::Full->new();
    $stat->add_data($values);
    my $funcname = $self->getAttr(name => 'statistics_function_name');
    my $mean = $stat->$funcname();
    return $mean;

}
1;
