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
forecasting through the function: forcasted_data = zero + slopes * log (time - start_time)

@since    2013-Feb-13
@instance hash
@self     $self

=end classdoc

=cut

package Entity::DataModel::LogarithmicRegression;

use base 'Entity::DataModel';

use strict;
use warnings;
use Data::Dumper;

use Entity::DataModel::LinearRegression;


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

@param data hash {timestamp => value} of datas to be modeled

@optional start_time model consider only time_stamp > start_time
@optional end_time model consider only time_stamp < end_time

@return hash time of store parameters

=end classdoc

=cut

sub configure {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['data'],
                         optional => {'start_time' => undef, 'end_time' => undef });

    $log->info('Input start time = ['.($args{start_time}).'], stop time = ['.($args{end_time}).']');

    # Convert time to log(time)

    my @times = keys %{$args{data}};

    my $min_time;
    my $max_time;
    my $time;
    my @time_filter;

    # Init min/max with first defined value
    TIME_INIT:
    while (@times) {
        $time = pop @times;
        if (! (defined $args{data}->{$time})) {
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
        if (! (defined $args{data}->{$time})) {
            next TIME;
        }
        if ((defined $args{start_time}) && $time < $args{start_time}) {
            next TIME;
        }
        if ((defined $args{end_time}) && $time > $args{end_time}) {
            next TIME;
        }

        if ($min_time > $time) {$min_time = $time; $log->info('up min')}
        if ($max_time < $time) {$max_time = $time; $log->info('up max')}
        push @time_filter, $time;
    }

    if ((! defined $min_time) || ($min_time == $max_time)) {
        throw Kanopya::Exception(error => 'Not enough data to configure model');
    }

    $args{start_time} = $min_time;
    $args{end_time}   = $max_time;

    my $min_value = $args{data}->{$args{start_time}};

    # Transform time to log(time) in order to apply a linear regression
    my %log_data;
    for my $time (@time_filter){
        $log_data{ log($time - $args{start_time} + 1) } = $args{data}->{$time} - $min_value;
    }

    my $linreg = Entity::DataModel::LinearRegression->new(
                    combination_id => $self->combination_id,
                    node_id        => $self->node_id,
                 );

    my $linreg_preset = $linreg->configure(
                            data       => \%log_data,
                        );

    my $pp_lin = $linreg_preset->load;
    $pp_lin->{b} += $min_value;
    $pp_lin->{offset_lin} = $linreg->start_time;

    my $preset = ParamPreset->new(params => $pp_lin);

    $self->setAttr(name => 'param_preset_id', value => $preset->id);
    $self->setAttr(name => 'start_time',      value => $args{start_time});
    $self->setAttr(name => 'end_time',        value => $args{end_time});

    $log->info('Start_time = '.($args{start_time}).', end_time = '.($args{end_time}).')');
    $log->info('Learnt parameters = '.(Dumper $pp_lin));

    $self->save();
    $linreg_preset->delete();
    $linreg->delete();

    return $preset;
}


=pod

=begin classdoc

Compute forecasted values from timestamps with logarithmic function and parameters.
Model must have been configured first (see configure method)
Timestamps can have 2 formats: either an array of (timestamps) or
a (start_time, end_time, sampling period).

By default the method return a hash with two keys 'timestamps' (reference to an array of timestamps)
and 'values' (reference an array of forecasted values).

@optional timestamps array of timestamps when using the (timestamps) format
@optional start_time start_time when using the format (start_time, end_time, sampling_period)
@optional end_time end_time when using the format (start_time, end_time, sampling_period)
@optional sampling_period sampling_period when using the format (start_time, end_time, sampling_period)
@optional time_format 'ms' returns time in milliseconds
@optional data_format 'pair' returns an array of references of pair [timestamp, value]

@return the timestamps and forecasted values with the chosen data_format.

=end classdoc

=cut

sub predict {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [],
                         optional => { 'timestamps'      => undef,
                                       'start_time'      => undef,
                                       'end_time'        => undef,
                                       'sampling_period' => undef,});

    my $pp     = $self->param_preset->load;
    my $offset = $self->getAttr(name => 'start_time');

    # configuration has been made with an offset value


    if ((! defined $pp->{a}) ||
        (! defined $pp->{b}) ||
        (! defined $pp->{offset_lin} ) ||
        (! defined $offset) ) {

        throw Kanopya::Exception(error => 'DataModel LogarithmicRegression seems to have been badly configured');
    }

    my $function_args = {
        a          => $pp->{a},
        b          => $pp->{b},
        offset_lin => $pp->{offset_lin},
        offset     => $offset,
    };

    return $self->constructPrediction (
               function_args => $function_args,
               %args,
           );
}


=pod

=begin classdoc

Compute the regression function

@param function_args hash which contains the parameters of the function (a, b, ts, offset, offset_lin) values.

@return evaluation of the function

=end classdoc

=cut

sub prediction_function {
    my ($self, %args) = @_;
    General::checkParams(args     => \%args,
                         required => ['function_args'],);

    # (ts - offset + 1 > 0)
    if ($args{function_args}->{ts} - $args{function_args}->{offset} + 1 > 0) {
        # a * ( log (ts - offset + 1) - offset_lin) + b
        return $args{function_args}->{a} *
               (log ($args{function_args}->{ts} - $args{function_args}->{offset} + 1) -
               $args{function_args}->{offset_lin}) +
               $args{function_args}->{b}
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
    my $r_rounded = sprintf("%.2f", $self->getRSquared());
    return 'Logarithmic regression '.$self->time_label()." (R = $r_rounded)";
}

sub isSeasonal {
    return 0;
}

1;
