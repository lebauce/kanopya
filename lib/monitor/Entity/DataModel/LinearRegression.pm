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

Class which configures a linear regression model for the data of a combination.
Once configured, the LinearRegression stores the parameters (slopes, zero) which allow data
forecasting through the function: forcasted_data = zero + slopes * (time - start_time)

@since    2013-Feb-13
@instance hash
@self     $self

=end classdoc

=cut

package Entity::DataModel::LinearRegression;

use base 'Entity::DataModel';

use strict;
use warnings;
use Data::Dumper;

use Statistics::LineFit;
use Kanopya::Exceptions;

# logger
use Log::Log4perl "get_logger";
my $log = get_logger("");


=pod

=begin classdoc

Apply a linear regression to the input datas.
Store parameters (slope 'a', zero 'b' and Rsquared value) in database

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

    # Split data hashtable in two time-sorted arrays
    my @time_keys            = keys( %{$args{data}} );
    my @sorted_all_time_keys = sort {$a <=> $b} @time_keys;

    if (! defined $args{start_time}) {
        $args{start_time} = $sorted_all_time_keys[0];
    }

    if (! defined $args{end_time}) {
        $args{end_time} = $sorted_all_time_keys[-1];
    }

    my @sorted_data_values;
    my @sorted_time_keys;

    for my $key (@sorted_all_time_keys) {
        # Keep only data between start_time and end_time
        if ((defined $args{data}->{$key}) && ($args{start_time} <= $key) && ($key <= $args{end_time})) {
            push @sorted_time_keys, ($key - $args{start_time}); # Offset all data to zero
            push @sorted_data_values, $args{data}->{$key};
        }
    }

    # Compute coef and Rsquare
    my $lineFit = Statistics::LineFit->new();

    $lineFit->setData(\@sorted_time_keys, \@sorted_data_values);

    # line equation is $a * x + $b
    my ($b, $a) = $lineFit->coefficients();
    my $rSquared = $lineFit->rSquared();

    # Store coefficients in param_presets
    my $preset = ParamPreset->new(params => {a => $a, b => $b, rSquared => $rSquared});

    $self->setAttr(name => 'param_preset_id', value => $preset->id);
    $self->setAttr(name => 'start_time',      value => $args{start_time});
    $self->setAttr(name => 'end_time',        value => $args{end_time});

    $self->save();
    return $preset;
}


=pod

=begin classdoc

Compute forecasted values from timestamps with linear function and parameters.
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
                                       'sampling_period' => undef,
                                       'time_format'     => undef,
                                       'data_format'     => undef});

    my $pp = $self->param_preset->load;

    # configuration has been made with an offset value
    my $offset = $self->getAttr(name => 'start_time');

    if ( (! defined $pp->{a}) ||
         (! defined $pp->{b}) ||
         (! defined $offset)) {
        throw Kanopya::Exception(error => 'DataModel LinearRegression seems to have been badly configured');
    }

    my $function_args = {a      => $pp->{a},
                         b      => $pp->{b},
                         offset => $offset,};

    return $self->constructPrediction (
               function_args => $function_args,
                %args,
           );
}


=pod

=begin classdoc

Compute the regression function

@param function_args hash which contains the parameters of the function (a, b, ts and offset) values.

@return evaluation of the function

=end classdoc

=cut

sub prediction_function {
    my ($self, %args) = @_;
    General::checkParams(args     => \%args,
                         required => ['function_args'],);

    # a * (ts - offset) + b
    return $args{function_args}->{a} *
           ($args{function_args}->{ts} - $args{function_args}->{offset}) +
           $args{function_args}->{b};
}


=pod

=begin classdoc

Construct a human readable label for the model:
'Linear regression : [$human_readable_start_date -> $human_readable_end_date]'

@return contructed label

=end classdoc

=cut

sub label {
    my $self = shift;
    my $r_rounded = sprintf("%.2f", $self->getRSquared());
    return 'Linear regression '.$self->time_label()." (R = $r_rounded)";
}

1;
