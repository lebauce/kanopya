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

Data Model for performing a forecast using the "ets" (Exponential Smoothing State Space Model) algorithm from
the R forecast package.

=end classdoc

=cut

package Entity::DataModel::RDataModel::ExponentialSmoothing;

use base 'Entity::DataModel::RDataModel';

use strict;
use warnings;

use Kanopya::Exceptions;

# logger
use Log::Log4perl "get_logger";
my $log = get_logger("");

=pod

=begin classdoc

Make a prediction calling the ets method from the R forecast package.

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

# 1- Check parameters
    $self->_checkParams(timeserie_ref => \@timeserie,
                        freq          => $args{freq},
                        predict_end   => $args{predict_end},
    );

# 2- Compute horizon
    my $horizon     = $args{predict_end} - @{$args{data}} + 1;

# 3- Forecast with R
    my $R_forecast_ref = $self->_forecastFromR(timeserie_ref => \@timeserie,
                                               freq          => $args{freq},
                                               horizon       => $horizon,
    );
    my @forecasts = @{Utils::R->convertRForecast(R_forecast_ref => $R_forecast_ref,
                                                 freq           => $args{freq}
    )};

    return \@forecasts;
}

sub label {
    my $self = shift;
    return 'Exponential Smoothing ' . $self->time_label();
}

sub isSeasonal {
    return 1;
}

=pod

=begin classdoc

Checks that the given parameters for computing the ets method are valid.

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

    # Check that at least two periods are present in the timeserie
    if (@{$args{timeserie_ref}}/$args{freq} < 2) {
        throw Kanopya::Exception(error => 'Exponential Smoothing : bad parameters (there must be'
                                          .' at least two periods in the given data)');
    }

    # Check that the given end time is strictly after the last available data from the given set
    if ($args{predict_end} <= $#{$args{timeserie_ref}}) {
        throw Kanopya::Exception(error => 'Exponential Smoothing : bad parameters (trying to ' .
                                          'forecast the past...)');
    }
}

=pod

=begin classdoc

Initializes the R binding and the R objects, fits the ets model with the automated algorithm from the
forecast package.

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
            . qq`forecast <- forecast(ets(time_serie), h=$hor);`);           # fit and forecast with ets

    # Return the forecast computed by R
    return $R->get('forecast');
}

1;