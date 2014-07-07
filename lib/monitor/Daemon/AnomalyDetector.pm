#    Copyright © 2014 Hedera Technology SAS
#
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

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

=pod
=begin classdoc

Anomaly detector of Kanopya.
Computes current anomaly scores for each anomaly of the Kanopya DB

=end classdoc
=cut

package Daemon::AnomalyDetector;
use base Daemon;

use strict;
use warnings;
use Entity::Metric::Anomaly;

use Log::Log4perl "get_logger";
my $log = get_logger("");

use constant ATTR_DEF => {};

sub getAttrDef { return ATTR_DEF; }


=pod
=begin classdoc

Load configuration

@constructor

=end classdoc
=cut

sub new {
    my ($class, %args) = @_;
    my $self = $class->SUPER::new(confkey => 'anomaly-detector');
    return $self;
}


=pod

=begin classdoc

Main loop

=end classdoc

=cut
sub oneRun {
    my ($self) = @_;

    # Get the start time
    my $start_time = time();

    my $update_duration = time() - $start_time;

    my @anomalies = Entity::Metric::Anomaly->search(hash => {}, prefetch => [ 'related_metric' ]);

    $self->update(anomalies => \@anomalies);

    if ($update_duration > $self->{config}->{time_step}) {
        $log->warn("Anomaly detector duration > time step ($self->{config}->{time_step})");
    }
    else {
        my $waiting_time = $self->{config}->{time_step} - $update_duration;
        $log->info("Wainting for $waiting_time seconds");
        sleep($waiting_time);
    }
}

sub update {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => [ 'anomalies' ], optional => {time => time()});

    # Get metric values
    my %metrics;
    for my $anomaly (@{$args{anomalies}}) {

        my $num_periods = $anomaly->getParams()->{num_periods} || 2;
        my $period = $anomaly->getParams()->{period} || 1 * 24 * 60 * 60;

        my $start_time = $args{time} - ($num_periods + 1) * $period;

        my $values = $anomaly->related_metric->fetch(
                         start_time => $start_time,
                         stop_time  => $args{time},
                         output     => 'arrays'
                     );

        # Try to improve performance avoiding AUTOLOAD
        # TODO Optimize autoload in baseDB
        my $id = $anomaly->{_dbix}->{_column_data}->{anomaly_id} || $anomaly->id;
        my $related_metric_id = $anomaly->{_dbix}->{_column_data}->{related_metric_id}
                                || $anomaly->related_metric_id;

        my $value = $anomaly->computeAnomaly(values => $values);

        $anomaly->updateData(
            time             => $value->{timestamp},
            value            => $value->{value},
            time_step        => $self->{config}->{time_step},
            storage_duration => $self->{config}->{storage_duration}
        );
    }
}

1;
