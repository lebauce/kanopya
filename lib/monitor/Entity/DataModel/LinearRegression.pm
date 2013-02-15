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

package Entity::DataModel::LinearRegression;

use base 'Entity::DataModel';

use strict;
use warnings;
use Data::Dumper;

use Statistics::LineFit;
use Kanopya::Exceptions;

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
    my $a  = $pp->{a};
    my $b  = $pp->{b};

    if ( (! defined $a) || (! defined $b) ) {
        throw Kanopya::Exception(error => 'DataModel LinearRegression seems to have been badly configured');
    }

    # configuration has been made with an offset value
    my $offset = $self->getAttr(name => 'start_time');

    # Construct timestamps if not defined
    if (! defined $args{timestamps}) {
        if (defined $args{start_time} &&
            defined $args{end_time} &&
            defined $args{sampling_period}) {

            for (my $ts = $args{start_time} ; $ts <= $args{end_time} ; $ts += $args{sampling_period}) {
                push @{$args{timestamps}}, $ts;
            }
        }
        else {
            throw Kanopya::Exception(error => 'predict method need either timestamps or
                                               a start_time, a end time and a sampling period');
        }
    }
    my @predictions;
    my @timestamps_temp;
    # Compute prediction with good format
    for my $ts (@{$args{timestamps}}) {
        my $value = $a * ($ts - $offset) + $b;

        # Need to use a local variable in order to avoid input data (by ref) modification
        my $ts_temp = ($args{time_format} eq 'ms') ? $ts * 1000 : $ts;

        my $prediction;
        if ($args{data_format} eq 'pair') {
            $prediction = [$ts_temp, $value];
        }
        else {
            push @timestamps_temp, $ts_temp;
            $prediction = $value
        }
        push @predictions, $prediction;
    }
    if ($args{data_format} eq 'pair') {
        return \@predictions;
    }
    else {
        return {timestamps => \@timestamps_temp, values => \@predictions};
    }
}

sub label {
    my $self = shift;
    return 'Linear regression '.$self->time_label();
}

1;
