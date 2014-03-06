#    Copyright © 2013 Hedera Technology SAS
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

=pod

=begin classdoc

Abstract class which represents a DataModel using a regression caracterized by an analytical function to 
perform a prediction.

=end classdoc

=cut

package Entity::DataModel::AnalyticRegression;

use base 'Entity::DataModel';

use strict;
use warnings;

=pod

=begin classdoc

Method called from child class instance to compute the forcasting.
By default the method return a hash with two keys 'timestamps' (reference to an array of timestamps)
and 'values' (reference an array of forecasted values).

@param function_args all the arguments of the forcasting function

@return the forecasted values as an array ref.

=end classdoc

=cut

sub constructPrediction {
    my ($self, %args) = @_;

    my $function_args = $args{function_args};

    my @timestamps = ($args{predict_start}..$args{predict_end});
    my @predictions;

    # Compute prediction with good format
    for my $ts (@timestamps) {

        $function_args->{ts} = $ts;
        my $value = $self->prediction_function(function_args => $function_args);
        push @predictions, $value;
    }
    return \@predictions;
}

1;