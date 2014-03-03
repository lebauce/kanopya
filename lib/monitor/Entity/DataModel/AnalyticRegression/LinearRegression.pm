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

package Entity::DataModel::AnalyticRegression::LinearRegression;

use base 'Entity::DataModel::AnalyticRegression';

use strict;
use warnings;

use Statistics::LineFit;
use Kanopya::Exceptions;

# logger
use Log::Log4perl "get_logger";
my $log = get_logger("");


=pod

=begin classdoc

Apply a linear regression to the input datas.
Store parameters (slope 'a', zero 'b') in database

@param data A reference to an array containing the values of the time serie.

@return hash time of store parameters

=end classdoc

=cut

sub configure {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['data'],
                         optional => {'time_keys' => undef});

    my @data_values = @{$args{data}};
    my @time_keys;
    if (!defined($args{time_keys})) {
        @time_keys = (0..$#data_values);
    }
    else {
        @time_keys = @{$args{time_keys}};
    }

    # Compute coef
    my $lineFit = Statistics::LineFit->new();

    $lineFit->setData(\@time_keys, \@data_values);

    # line equation is $a * x + $b
    my ($b, $a) = $lineFit->coefficients();

    # Store coefficients in param_presets
    my $preset = ParamPreset->new(params => {a => $a, b => $b});

    $self->setAttr(name => 'param_preset_id', value => $preset->id);

    $self->save();
    return $preset;
}


=pod

=begin classdoc

Compute forecasted values from timestamps with linear function and parameters.
Model must have been configured first (see configure method).

@param predict_start The starting point wished for the prediction (in points, and not in timestamps !).
@param predict_end The ending point wished for the prediction (in points !).

@return A reference to an array containing the forecast values.

=end classdoc

=cut

sub predict {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['predict_start', 'predict_end'],);

    my $pp = $self->param_preset->load;

    if ( (! defined $pp->{a}) ||
         (! defined $pp->{b})) {
        throw Kanopya::Exception::Internal(
                  error => 'DataModel LinearRegression seems to have been badly configured'
              );
    }

    my $function_args = {a => $pp->{a},
                         b => $pp->{b},};

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
    my ($class, %args) = @_;
    General::checkParams(args     => \%args,
                         required => ['function_args'],);

    # a * (ts) + b
    return $args{function_args}->{a} * ($args{function_args}->{ts}) + $args{function_args}->{b};
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
    return 'Linear regression '.$self->time_label();
}

sub isSeasonal {
    return 0;
}

1;
