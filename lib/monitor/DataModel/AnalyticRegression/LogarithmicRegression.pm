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

Class which configures a logarithmic regression model for the data of a combination.
Once configured, the LogarithmicRegression stores the parameters which allow data
forecasting through the function: forcasted_data = zero + slopes * log (time)

@since    2013-Feb-13
@instance hash
@self     $self

=end classdoc

=cut

package DataModel::AnalyticRegression::LogarithmicRegression;

use base 'DataModel::AnalyticRegression';

use strict;
use warnings;
use Data::Dumper;

use DataModel::AnalyticRegression::LinearRegression;


# logger
use Log::Log4perl "get_logger";
my $log = get_logger("");

=pod

=begin classdoc

Apply a logarithmic regression to the input datas.
Logarihmic regression transform the time to log(time)
and use the Linear Regression module.
Store parameters in database

The model use the first non-undef value as the logarithmic reference (1,0)
The model does not implement incomplete time-shifted logarithmic functions

@param data A reference to an array containing the values of the time serie.
@param combination_id : The combination's id linked to the DataModel.
@param node_id : The node's id linked to the DataModel.

@return hash time of store parameters.

=end classdoc

=cut

sub configure {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['data'],);

    # Convert time to log(time)
    my @data_values = @{$args{data}};
    my @times = (0..$#data_values);

    my %datash;
    for my $i (0..$#data_values) {
        $datash{$times[$i]} = $data_values[$i];
    }

    my $min_time;
    my $max_time;
    my $time;
    my @time_filter;

    # Init min/max with first defined value
    TIME_INIT:
    while (@times) {
        $time = pop @times;
        if (! (defined $datash{$time})) {
            next TIME_INIT;
        }
        if ((defined $args{start_time}) && $time < $args{start_time}) {
            next TIME_INIT;
        }
        if ((defined $args{end_time}) && $time > $args{end_time}) {
            next TIME_INIT;
        }

        $min_time = $time;
        $max_time = $time;
        push @time_filter, $time;
        last TIME_INIT;
    }

    # Get max time and min time and filter times outside input range
    TIME:
    while (@times) {
        $time = pop @times;
        if (! (defined $datash{$time})) {
            next TIME;
        }
        if ((defined $args{start_time}) && $time < $args{start_time}) {
            next TIME;
        }
        if ((defined $args{end_time}) && $time > $args{end_time}) {
            next TIME;
        }

        if ($min_time > $time) {$min_time = $time}
        if ($max_time < $time) {$max_time = $time}
        push @time_filter, $time;
    }

    if ((! defined $min_time) || ($min_time == $max_time)) {
        throw Kanopya::Exception::Internal::WrongValue(error => 'Not enough data to configure model');
    }

    $args{start_time} = $min_time;
    $args{end_time}   = $max_time;

    my $min_value = $datash{$args{start_time}};

    # Transform time to log(time) in order to apply a linear regression
    my %log_data;
    my @log_tstamps;
    my @log_values;
    for my $time (@time_filter){
        $log_tstamps[$time] = log($time - $args{start_time} + 1);
        $log_values[$time]  = $datash{$time} - $min_value;
        $log_data{ log($time - $args{start_time} + 1) } = $datash{$time} - $min_value;
    }

    my $linreg = DataModel::AnalyticRegression::LinearRegression->new();

    my $pp_lin = $linreg->configure(
                     data      => \@log_values,
                     time_keys => \@log_tstamps,
                 );

    $pp_lin->{b} += $min_value;

    $self->setAttr(name => 'param_preset', value => $pp_lin);

    $log->info('Learnt parameters = '.(Dumper $pp_lin));

    return $pp_lin;
}

=pod

=begin classdoc

Compute forecasted values from timestamps with logarithmic function and parameters.
Model must have been configured first (see configure method).

@param data A reference to an array containing the values of the time serie.
@param freq The frequency (or seasonality) of the time serie.
@param predict_start The starting point wished for the prediction (in points, and not in timestamps !).
@param predict_end The ending point wished for the prediction (in points !).
@param combination_id (optional) : The combination's id linked to the DataModel.
@node_id (optional) : The node's id linked to the DataModel.

@return A reference to an array containing the forecast values.

=end classdoc

=cut

sub predict {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['predict_start', 'predict_end'],);

    my $pp = $self->{param_preset};

    if ((! defined $pp->{a}) ||
        (! defined $pp->{b}) ) {

        throw Kanopya::Exception::Internal(
                  error => 'DataModel LogarithmicRegression seems to have been badly configured'
              );
    }

    my $function_args = {
        a          => $pp->{a},
        b          => $pp->{b},
    };

    return $self->constructPrediction (
               function_args => $function_args,
               %args,
           );
}

=pod

=begin classdoc

Compute the regression function

@param function_args hash which contains the parameters of the function (a, b, ts) values.

@return evaluation of the function

=end classdoc

=cut

sub prediction_function {
    my ($self, %args) = @_;
    General::checkParams(args     => \%args,
                         required => ['function_args'],);

    # (ts - offset + 1 > 0)
    if ($args{function_args}->{ts} + 1 > 0) {
        # a * ( log (ts + 1) ) + b
        return $args{function_args}->{a} * (log ($args{function_args}->{ts} + 1)) + $args{function_args}->{b};
    }
    return undef;
}

=pod

=begin classdoc

Construct a human readable label for the model:
'Logarithmic regression : [$human_readable_start_date -> $human_readable_end_date]'

@return contructed label

=end classdoc

=cut

sub label {
    my $self = shift;
    return 'Logarithmic regression '.$self->time_label();
}

sub isSeasonal {
    return 0;
}

1;
