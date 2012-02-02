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
use Entity::Cluster;
use DBI;
sub new {
    my $class = shift;
    my %args = @_;
    
     General::checkParams args => \%args, required => [
        'cluster',
        'indicator',
        'descriptive_statistics_function_name',
        'window_time',
    ];
    
    my $self = {};
    $self->{_cluster}                              = $args{cluster};
    $self->{_indicator}                            = $args{indicator};
    $self->{_descriptive_statistics_function_name} = $args{descriptive_statistics_function_name};
    $self->{_window_time}                          = $args{window_time};
    
    
    my $required = 'DescriptiveStatisticsFunction/'.($self->{_descriptive_statistics_function_name}).'.pm';
    require $required;
    
    bless $self, $class;
}

sub getCluster{
    my $self = shift;
    return $self->{_cluster};
}

sub callDescriptiveStatisticsFunction{
    my $self = shift;
    my %args = @_;
    
    General::checkParams args => \%args, required => [
        'values',
    ];
    
    my $values  = $args{values};
    ('DescriptiveStatisticsFunction::'.($self->{_descriptive_statistics_function_name}))->calculate(values => $values);
}
1;
