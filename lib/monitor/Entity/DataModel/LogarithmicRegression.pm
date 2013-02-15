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

package Entity::DataModel::LogarithmicRegression;

use base 'Entity::DataModel';

use strict;
use warnings;
use Data::Dumper;

use Entity::DataModel::LinearRegression;

sub configure {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['data'],
                         optional => {'start_time' => undef, 'end_time' => undef });


    # Convert time to log(time)

    my @times = keys %{$args{data}};

    my $min_time = $times[0];
    my $max_time = $times[0];

    my $time;

    my @time_filter;

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
        if ($min_time > $time) {$min_time = $time}
        if ($max_time < $time) {$max_time = $time}
        push @time_filter, $time;
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

    $self->save();
    $linreg_preset->delete();
    $linreg->delete();

    return $preset;
}

sub predict {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [],
                         optional => { 'timestamps'      => undef,
                                       'start_time'      => undef,
                                       'end_time'        => undef,
                                       'sampling_period' => undef,});

    # TODO factorize code of prediction same code excepted the formula)

    my $pp         = $self->param_preset->load;
    my $a          = $pp->{a};
    my $b          = $pp->{b};
    my $offset_lin = $pp->{offset_lin};

    if ( (! defined $a) || (! defined $b) || (! defined $offset_lin )) {
        throw Kanopya::Exception(error => 'DataModel LogarithmicRegression seems to have been badly configured');
    }

    # configuration has been made with an offset value
    my $offset   = $self->getAttr(name => 'start_time');

    # Implement 2 different for loops in order to avoid two array traversals
    if (defined $args{timestamps}) {

        my @predictions;

        for my $ts (@{$args{timestamps}}) {
            if ($ts - $offset + 1 > 0) {
                push @predictions, $a * ( log ($ts - $offset + 1) - $offset_lin) + $b;
            }
            else {
                push @predictions, undef
            }
        }

        return {timestamps => $args{timestamps}, values => \@predictions};
    }
    else {

        if (defined $args{start_time} &&
            defined $args{end_time} &&
            defined $args{sampling_period}) {

            my @predictions;
            my @timestamps;

            for (my $ts = $args{start_time} ; $ts <= $args{end_time} ; $ts += $args{sampling_period}) {
                push @timestamps, $ts;
                if ($ts - $offset + 1 > 0) {
                    push @predictions, $a * (log ($ts - $offset + 1) - $offset_lin) + $b;
                }
                else {
                    push @predictions, undef;
                }
            }

            return {timestamps => \@timestamps, values => \@predictions};
        }
        else {
            throw Kanopya::Exception(error => 'predict method need either timestamps or
                                               a start_time, a end time and a sampling period');
        }
    }
}

1;
