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

package DescriptiveStatisticsFunction::StandardDeviation;

use strict;
use warnings;
use General;

use base "DescriptiveStatisticsFunction";

# logger
#use Log::Log4perl "get_logger";
#my $log = get_logger("descriptiveStatisticsFunction");

sub calculate {
    my $class = shift;
    
    my %args = @_;
    General::checkParams args => \%args, required => [
        'values',
    ];
   
    my $values = $args{'values'};

    my $mean = 0;
    for my $element (@$values){
        $mean += $element;
    }
    $mean /= scalar(@$values);

    my $square_difference_sum = 0; 
    for my $element (@$values){
        $square_difference_sum += ($mean - $element)*($mean - $element);
    }
    $square_difference_sum /= scalar(@$values);
    
    $square_difference_sum = sqrt($square_difference_sum);
    
    return $square_difference_sum;
}
1;