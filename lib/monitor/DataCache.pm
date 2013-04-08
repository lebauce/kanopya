#    Copyright © 2012 Hedera Technology SAS
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

Manage indicator value by nodes, allowing local storage to avoid excessive requests on monitoring tool.

DataCache is build for time series (data are timestamped) so it can store/provide historical node data.

If $NODEMETRIC_STORAGE_ACTIVE is set to 1 then DataCache will store provided node metric data
and allow other modules to get nodes data from storage.

If $NODEMETRIC_STORAGE_ACTIVE is set to 0 data are not stored
and when other modules want retrieve nodes data then DataCache will do a request
to the monitoring tool using the appropriate collector manager.

It is important to notice that, for the moment, the data to store must be provided to the DataCache,
i.e. if cache is activated then DataCache will never do a request and will only be able to provide stored data.

=end classdoc

=cut

package DataCache;

use strict;
use warnings;

use Data::Dumper;
use TimeData::RRDTimeData;
use Kanopya::Config;
use Kanopya::Exceptions;

use Log::Log4perl "get_logger";
my $log = get_logger("");

# Flag to activate/deactivate nodes metrics values storage
# TODO conf by service provider or collector manager (?)
my $NODEMETRIC_STORAGE_ACTIVE = 1;

use constant ATTR_DEF => {};

sub getAttrDef { return ATTR_DEF; }

sub getMethods {

}

=pod
=begin classdoc

Allow to activate/deactivate node metric cache.

WARNING: Configuration only for the current process, can lead to inconsistency between sereval services.
         Useful for test purpose.

=end classdoc
=cut
sub cacheActive {
    my $activate = shift;
    $NODEMETRIC_STORAGE_ACTIVE = $activate;
}

=pod
=begin classdoc

Store provided indicators values by nodes, for a specified time.
Do not store if cache is not activated.

@param indicators Hash ref {indicator_oid => indicator}
@param values Hash ref of data to store {node_name => {indicator_oid => value}}
@param timestamp Seconds since Epoch

=end classdoc
=cut

sub storeNodeMetricsValues {
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'indicators', 'values', 'timestamp', 'time_step', 'storage_duration' ]);

    return if (!$NODEMETRIC_STORAGE_ACTIVE);

    while (my ($node_name, $indicators_values) = each %{$args{values}}) {
        while (my ($indicators_oid, $value) = each %$indicators_values) {
            my $metric_uid = $args{indicators}->{$indicators_oid}->id . '_' . $node_name;
            RRDTimeData::updateTimeDataStore(
                clustermetric_id => $metric_uid,
                time             => $args{timestamp},
                value            => $value,
                time_step        => $args{time_step},
                storage_duration => $args{storage_duration}
            );
        }
    }
}

=pod
=begin classdoc

Allow to retrieve the last value of an indicator for several nodes.
If cache is activated then get value from cache (rrd) else do a request to the appropriate collector manager

@param collector_indicator CollectorIndicator instance for which we want the value
@param node_names Array ref of nodes name for which we want the value
@param service_provider ServiceProvider instance holding the nodes

@return Hash ref of requested data {node_name => last_value}

=end classdoc
=cut

sub nodeMetricLastValue {
    my %args = @_;

    General::checkParams(args => \%args, required => ['collector_indicator', 'node_names', 'service_provider']);

    my $indicator = $args{collector_indicator}->indicator;

    my $value_by_nodes;
    if ($NODEMETRIC_STORAGE_ACTIVE) {
        $value_by_nodes = _nodeMetricLastValueFromStorage(
                              indicator                => $indicator,
                              monitored_objects_names  => $args{node_names}
                          );

    }
    else {
        my $cmg           = $args{collector_indicator}->collector_manager;
        my $mparams       = $args{service_provider}->getManagerParameters(manager_type => 'CollectorManager');
        my $indicator_oid = $indicator->indicator_oid;
        my $data = $cmg->retrieveData(
                       nodelist   => $args{node_names},
                       indicators => {$indicator_oid => $indicator},
                       time_span  =>  1200,
                       %$mparams
                   );
        my %values = map { $_ => $data->{$_}{$indicator_oid} } keys %$data;
        $value_by_nodes = \%values;
    }

    return $value_by_nodes;
}

sub _nodeMetricLastValueFromStorage {
    my %args = @_;

    General::checkParams(args => \%args, required => ['indicator', 'monitored_objects_names']);

    my %value_by_objects;
    for my $object_name (@{$args{monitored_objects_names}}) {
        my $metric_uid = $args{indicator}->id . '_' . $object_name;
        my ($timestamp, $value);
        eval {
            ($timestamp, $value) = RRDTimeData::getLastUpdatedValue(
                                       metric_uid => $metric_uid,
                                       fresh_only => 1
                                   );
        };
        if ($@) {
            $value = undef;
        }
        $value_by_objects{$object_name} = $value;
    }
    return \%value_by_objects;
}

=pod
=begin classdoc

Allows to retrieve indicator values between start_time and stop_time for several nodes
If cache is activated then get values from cache (rrd) else throw an exception (not implemented)

TODO Allow fetch directly from collector manager

@param collector_indicator CollectorIndicator instance for which we want the value
@param node_names Array ref of nodes name for which we want fetch values
@param start_time Start time in epoch
@param end_time Stop time in epoch

@return hashref { node_name => {timestamp => value} }

=end classdoc
=cut

sub nodeMetricFetch {
    my ($class, %args) = @_;

    General::checkParams args => \%args, required => ['indicator', 'node_names', 'start_time', 'end_time'];

    my $indicator = $args{indicator}; #$args{collector_indicator}->indicator;

    my %values_by_nodes;
    if ($NODEMETRIC_STORAGE_ACTIVE) {
        for my $object_name (@{$args{node_names}}) {
            my $metric_uid = $args{indicator}->id . '_' . $object_name;
            my %data = RRDTimeData::fetchTimeDataStore(
                          name   => $metric_uid,
                          start  => $args{start_time},
                          end    => $args{end_time}
                      );

            $values_by_nodes{$object_name} = \%data;
        }
    }
    else {
        throw Kanopya::Exception::NotImplemented(
                  error => 'Can not fetch historical data of node metric when data cache is not active'
              );
    }

    return \%values_by_nodes;
}
1;
