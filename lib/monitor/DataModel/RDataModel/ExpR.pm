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

Data Model which perform a forecast choosing a DataModel among the ones using the package forecast from R,
and imitating the behaviour of an expert.

=end classdoc

=cut

package Entity::DataModel::RDataModel::ExpR;

use base 'Entity::DataModel::RDataModel';

use strict;
use warnings;

use Entity::DataModel::RDataModel::AutoArima;
use Entity::DataModel::RDataModel::ExponentialSmoothing;
use Entity::DataModel::RDataModel::StlForecast;

use Kanopya::Exceptions;

# logger
use Log::Log4perl "get_logger";
my $log = get_logger("");

use constant {
    MIN_ETS => 4000,
};


=pod

=begin classdoc

Make a prediction choosing a DataModel among the ones using the package forecast from R,
and imitating the behaviour of an expert.

@param data A reference to an array containing the values of the time serie.
@param freq The frequency (or seasonality) of the time serie.
@param predict_end The ending point wished for the prediction (in points !).

@return A reference to an array containing the forecast values.


=end classdoc

=cut

sub predict {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['data', 'freq', 'predict_end']);

    my @timeserie = @{$args{data}};

    my $forecasts; 
    # If the seasonality is > 1 use stlf, 
    # else : if the dataset length is < MIN_ETS, use autoarima
    # else use ets. 
    if ($args{freq} > 1) {
        $forecasts = Entity::DataModel::RDataModel::StlForecast->predict(%args);
    }
    elsif (scalar(@timeserie) < MIN_ETS) {
        $forecasts = Entity::DataModel::RDataModel::AutoArima->predict(%args);
    }
    else {
        $forecasts = Entity::DataModel::RDataModel::ExponentialSmoothing->predict(%args);
    }

    return $forecasts;
}

sub label {
    my $self = shift;
    return 'ExpR ' . $self->time_label();
}

sub isSeasonal {
    return 1;
}

1;