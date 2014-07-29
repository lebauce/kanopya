#    Copyright © 2014 Hedera Technology SAS
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

Anomaly detection algorithm implementation

=end classdoc

=cut

package AnomalyDetection::Seasonality;
use base AnomalyDetection;
use DataModelSelector;
use List::Util qw(min);

use strict;
use warnings;
use TryCatch;
use Log::Log4perl "get_logger";
my $log = get_logger("");

=pod
=begin classdoc

Method based on computing the difference between a current window of the signal and
the same window one or more perdiods earlier. It computes the anomlaly score as
the minimum euclidian distance between the the current signal and the <num_periods>
corresponding periods

@param values hash {values => [...], timestamps => [...]}. Contains 2 arrays : values and timestamps
@param params parameters {window => int, period => int, num_periods => int}
              window corresponds to the size of the timeserie analyzed by the algorithm
              period corresponds to the period of the time series (the window will be compared with
                     the corresponding wondow 1 or more period erlier)
              num_periods corresponds to the number of periods analyzed in the past

=end classdoc
=cut

sub detect {
    my ($class, %args) = @_;
    General::checkParams(args => \%args, required => ['values'], optional => {params => {}});
    General::checkParams(
        args => $args{params},
        optional => {
            window => 20,
            period => 1 * 24 * 60 * 60, # 1 day in seconds
            num_periods => 1,
        }
    );


    my $step = $args{values}->{timestamps}->[-1] - $args{values}->{timestamps}->[-2];
    my $season_length = $args{params}->{period} / $step;

    my $values = [];
    my $length = scalar @{$args{values}->{timestamps}} - 1 ;

    # extract the different windows
    for my $i (0..$args{params}->{num_periods}) {
        $values->[$i] = [];
        for my $j (0..$args{params}->{window}-1) {
            my $ts_index = $length - $j - $i * $season_length;
            my $ts = $args{values}->{timestamps}->[$ts_index];
            my $value = $args{values}->{values}->[$ts_index];
            $values->[$i]->[$j] = $value;
        }
    }

    # compute distance between current window and other ones
    my @dists = ();
    for my $i (1..$args{params}->{num_periods}) {
        my $d = $class->dist(v1 => $values->[0], v2 => $values->[$i]);
        if (defined $d) {
            push @dists, $d;
        }
    }

    my $value = min @dists;

    return {
        timestamp => $args{values}->{timestamps}->[-1],
        value     => $value,
    };
}


=pod
=begin classdoc

Compute a distance between two vectors using the following formula:
sum_{i = 0}^{n} (v1(i) - v2(i) ^ 2 / n)

@param v1 vector 1
@param v2 vector 2

=end classdoc
=cut

sub dist {
    my ($class, %args) = @_;
    my $sum = 0;
    my $length = scalar @{$args{v1}};
    my $num_def = 0;
    for my $i (0..$length-1) {
        if (! defined $args{v1}->[$i] || ! defined $args{v2}->[$i]) {
            next;
        }
        $num_def++;
        $sum += ($args{v1}->[$i] - $args{v2}->[$i]) ** 2 ;
    }
    return ($num_def > 0 ) ? $sum / $num_def : undef;
}