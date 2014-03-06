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

Data Model for performing a forecast using the "stlf" (Loess Seasonal Decomposition of Time Series) algorithm
from the R forecast package. STLF IS A HIGHLY SEASONAL MODEL, SEASONALITY MUST BE >1 AND THERE MUST BE AT
LEAST TWO PERIODS IN THE DATA.

=end classdoc

=cut

package DataModel::RDataModel::StlForecast;

use base 'DataModel::RDataModel';

use strict;
use warnings;

use Kanopya::Exceptions;

# logger
use Log::Log4perl "get_logger";
my $log = get_logger("");

=pod

=begin classdoc

Make a prediction calling the stlf method from the R forecast package.

@param data A reference to an array containing the values of the time serie.
@param freq The frequency (or seasonality) of the time serie.
@param predict_end The ending point wished for the prediction (in points !).

@return A reference to an array containing the forecast values.


=end classdoc

=cut

sub predict {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['data', 'freq', 'predict_end'],
                         optional => {'predict_start' => scalar @{$args{data}}});

    my @timeserie = @{$args{data}};

    if (@timeserie - 1 > $args{predict_start}) {
        throw Kanopya::Exception::Internal::IncorrectParam(
                  error => 'Warning prediction must start after timeserie '
              );
    }

    if ($args{predict_start} > $args{predict_end}) {
        throw Kanopya::Exception::Internal::IncorrectParam(
                  error => 'Warning start and end timestamps are not coherent'
              );
    }



# 1- Check parameters
    $self->_checkParams(timeserie_ref => \@timeserie,
                        freq          => $args{freq},
                        predict_end   => $args{predict_end},
    );

# 2- Compute horizon
    my $horizon     = $args{predict_end} - @{$args{data}} + 1;

# 3- Forecast with R
    my $forecasts = $self->_forecastFromR(timeserie_ref => \@timeserie,
                                               freq          => $args{freq},
                                               horizon       => $horizon,);

    # consider only the last ($args{predict_end} - $args{predict_start}) th values

    my @selection = @$forecasts[($args{predict_start} - $args{predict_end} - 1)..-1];

    return \@selection;
}

sub label {
    my $self = shift;
    return 'STLF ' . $self->time_label();
}

sub isSeasonal {
    return 1;
}

=pod

=begin classdoc

Checks that the given parameters for computing the stlf method are valid.

@param timestamps_ref A reference to the timestamps of the time serie (array).
@param timeserie_ref A reference to the values of the time serie (array).
@param freq The frequence (ie seasonality) of the time serie.
@param end_time The horizon of the forecast.

=end classdoc

=cut

sub _checkParams {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['timeserie_ref', 'freq', 'predict_end']);

    # Check that the given data has a seasonality >1
    if ($args{freq} <= 1) {
        throw Kanopya::Exception::Internal::IncorrectParam(
                  error => 'STLF : bad parameter : The serie is not seasonal (freq must be at least 2)'
              );
    }

    # Check that at least two periods are present in the timeserie
    if (@{$args{timeserie_ref}}/$args{freq} < 2) {
        throw Kanopya::Exception::Internal::IncorrectParam(
                  error => 'STLF : bad parameters (there must be at least two periods in the given data)'
              );
    }

    # Check that the given end time is strictly after the last available data from the given set
    if ($args{predict_end} <= $#{$args{timeserie_ref}}) {
        throw Kanopya::Exception::Internal::IncorrectParam(
                  error => 'STLF : bad parameters (trying to forecast the past...)'
              );
    }
}


=pod

=begin classdoc

Initializes the R binding and the R objects, forecast with the stlf method from the forecast package.

@param timeserie_ref A reference to the values of the time serie (array).
@param freq The frequence (ie seasonality) of the time serie.
@param horizon The horizon (in term of points) for the forecast.

@return the R forecast reference.

=end classdoc

=cut

sub _forecastFromR {
    my ($self, %args) = @_;
    General::checkParams(args     => \%args,
                         required => ['timeserie_ref', 'freq', 'horizon']);

    # Create a communication bridge with R and start R
    my $R = Statistics::R->new();

    # Initialize the dataset
    $R->set('dataset', $args{timeserie_ref});

    my $freq = $args{freq};
    my $hor  = $args{horizon};

    # Run R commands
    $R->run(q`library(forecast);`                                            # Load the forecast package
            . qq`time_serie <- ts(dataset, start=1, frequency=$freq);`       # Create the time serie
            . qq`forecast <- stlf(time_serie, h=$hor);`);                    # fit and forecast with stlf

    # Return the forecast computed by R
    my $forecast = $R->get('as.numeric(forecast$mean)');
    return $forecast;
}


1;
