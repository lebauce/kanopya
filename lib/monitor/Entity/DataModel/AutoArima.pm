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

Data Model for performing a forecast using the auto.arima method implemented in R.

@since 2012-Feb-27 
@instance hash
@self $self

=end classdoc

=cut

package Entity::DataModel::AutoArima;

use base 'Entity::DataModel';

use strict;
use warnings;
use Data::Dumper;


# Module for binding R into Perl
use Statistics::R;

# Module for R objects conversions
use Utils::R;

use Kanopya::Exceptions;

# logger
use Log::Log4perl "get_logger";
my $log = get_logger("");

# Not necessary here
sub configure {
    
}

=pod

=begin classdoc

See super method's doc.

@param data_ref A reference to the data hash to use for the extraction (timestamp => value). 
@param freq The frequence (ie seasonality) of the time serie.
@param end_time The horizon of the forecast.
@param data_format See super method's doc.

@return See super method's doc.

=end classdoc

=cut

sub predict {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['data_ref', 'freq', 'end_time'],
                         optional => { 'data_format' => undef});

# 0- Extract and sort arrays
    my %extracted  = %{$self->_extractAndSort(data_ref => $args{data_ref})};

    my @timestamps = @{$extracted{timestamps_ref}}; 
    my @timeserie  = @{$extracted{timeserie_ref}};

# 1- Check parameters
    $self->_checkParams(timestamps_ref => \@timestamps,
                        timeserie_ref  => \@timeserie,
                        freq           => $args{freq},
                        end_time       => $args{end_time},
    );

# 2- Compute horizon and granularity
    my %temp = %{$self->_computeHorizon(timestamps_ref => \@timestamps,
                                         end_time      => $args{end_time},
    )};
    my $granularity = $temp{granularity};
    my $horizon     = $temp{horizon};

# 3- Forecast with R
    my $R_forecast_ref = $self->_forecastFromR(timeserie_ref => \@timeserie,
                                               freq          => $args{freq},
                                               horizon       => $horizon,
    );
    my @forecasts = @{Utils::R->convertRForecast(R_forecast_ref    => $R_forecast_ref,
                                                    freq           => $args{freq}
                    )};
    my @n_timestamps;
    foreach (1..scalar(@forecasts)) {
        push(@n_timestamps, $timestamps[-1] + $_ * $granularity);
    }

# 4- Return the results with the desired format

    # Pair format
    if (defined($args{data_format}) && $args{data_format} eq 'pair') {
        my @pairs;
        foreach my $forecast_index (1..scalar(@forecasts)) {
            push(@pairs, [ $n_timestamps[$forecast_index], $forecasts[$forecast_index-1] ]);
        }
        return \@pairs;
    }
    # Hash format
    else {
        return {'timestamps' => \@n_timestamps,
                'values'     => \@forecasts,
        };
    }
}

sub label {
    my $self = shift;
    return 'Auto Arima ' . $self->time_label();
}

=pod

=begin classdoc

Extract and sort the time serie from a given hash (timestamp => data).

@param data_ref A reference to the data to use for the extraction.

@return the timestamps and value as array references ('timestamps_ref' && 'timeserie_ref').

=end classdoc

=cut

sub _extractAndSort {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['data_ref']);

    # Extract the time serie from the data param (and sort it too)
    my @timestamps = sort {$a <=> $b} keys(%{$args{data_ref}});

    # Declaration and construction of the time serie
    my @values;
    for my $key (@timestamps) {
        push (@values, $args{data_ref}->{$key});
    }

    return {
        timestamps_ref => \@timestamps,
        timeserie_ref  => \@values,
    };
}

=pod

=begin classdoc

Checks that the given parameters for computing the auto arima method are valid.

@param timestamps_ref A reference to the timestamps of the time serie (array).
@param timeserie_ref A reference to the values of the time serie (array).
@param freq The frequence (ie seasonality) of the time serie.
@param end_time The horizon of the forecast.

=end classdoc

=cut

sub _checkParams {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['timestamps_ref', 'timeserie_ref', 'freq', 'end_time']);

    # Check that at least two periods are present in the timeserie
    if (@{$args{timestamps_ref}}/$args{freq} < 2) {
        throw Kanopya::Exception(error => 'AutoArima : bad parameters (there must be at least two periods
                                           in the given data)');
    }

    # Check that the given end time is strictly after the last available data from the given set
    if ($args{end_time} <= $args{timestamps_ref}[-1]) {
        throw Kanopya::Exception(error => 'AutoArima : bad parameters (trying to forecast the past...)');
    }

    # For the moment we assume that there is the same period between every adjacent timestamp
}

=pod

=begin classdoc

Compute the granularity of the timeserie and the horizon in terms of points.

@param timestamps_ref A reference to the timestamps of the time serie.
@param end_time The horizon of the forecast.

@return the granularity of the timeserie and the horizon in a hash ('granularity' && 'horizon').

=end classdoc

=cut

sub _computeHorizon {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['timestamps_ref', 'end_time']);

    # Compute the granularity
    my $granularity = ($args{timestamps_ref}[-1] - $args{timestamps_ref}[0]) / (@{$args{timestamps_ref}} - 1);

    # Compute the horizon
    my $relative_end = ($args{end_time} - $args{timestamps_ref}[0]);
    my $horizon      = ($relative_end % $granularity) == 0 ? $relative_end / $granularity
                     :                                       int($relative_end / $granularity) + 1
                     ;

    return {
        granularity => $granularity,
        horizon     => ($horizon - @{$args{timestamps_ref}} + 1),
    };
}

=pod

=begin classdoc

Initializes the R binding and the R objects, fits the Arima model with the automated algorithm from the
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
            . qq`forecast <- forecast(auto.arima(time_serie), h=$hor);`);    # fit and forecast with arima

    # Return the forecast computed by R
    return $R->get('forecast');
}

1;