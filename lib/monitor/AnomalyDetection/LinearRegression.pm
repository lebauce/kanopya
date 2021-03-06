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

package AnomalyDetection::LinearRegression;
use base AnomalyDetection;
use DataModelSelector;

use strict;
use warnings;
use TryCatch;
use Log::Log4perl "get_logger";
my $log = get_logger("");

=pod
=begin classdoc

Method based on linear regression

=end classdoc
=cut

sub detect {
    my ($class, %args) = @_;
    General::checkParams(args => \%args, required => ['values']);

    my $train_window = 20;
    my $predicted_window = 10;

    my $timestamp = $args{values}->{timestamps}->[-1];

    if (! defined $args{values}->{values}->[-1] ) {
        return {
            timestamp => $timestamp,
            value     => undef
        };
    }

    my $start_index = - $train_window - $predicted_window - 1;
    my $end_index = - $predicted_window - 1;
    my @learn_inds = $start_index..$end_index;

    my %timeserie;
    for my $i (@learn_inds) {
        $timeserie{$args{values}->{timestamps}->[$i]} = $args{values}->{values}->[$i];
    }

    my $pdata = {values => [undef]};

    try {
        $pdata = DataModelSelector->autoPredictData(
                     predict_start_tstamps => $args{values}->{timestamps}->[- $predicted_window - 1],
                     predict_end_tstamps   => $args{values}->{timestamps}->[-1],
                     timeserie             => \%timeserie,
                     model_list            => ['DataModel::AnalyticRegression::LinearRegression'],
                 );
    }
    catch ($err) {
        $log->warn($err);
        return {
            timestamp => $timestamp,
            value     => undef
        };
    }

    return {
        timestamp => $timestamp,
        value     => abs($args{values}->{values}->[-1] - $pdata->{values}->[-1])
    };
}