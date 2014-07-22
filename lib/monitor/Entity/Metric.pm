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

@constructor

Metric are TimeSeries entities. They can be stored in database (RRD) and/or be evaluated

@optional store if store eq 'rrd' a rrd database will be linked to the metric

@return a class instance

=end classdoc
=cut

package Entity::Metric;
use base Entity;
use ParamPreset;
use TimeData;
use TryCatch;
use Formula;

use Log::Log4perl "get_logger";
my $log = get_logger("");

sub methods {
    return {
        evaluateTimeSerie => {
            description => 'retrieve historical value of a metric',
        }
    };
}

sub new {
    my ($class, %args) = @_;
    my $params;

    if (defined $args{store}) {
        if ($args{store} eq 'rrd') {
            $params->{store} = $args{store};
            delete $args{store};
        }
        else {
            throw Kanopya::Exception::Internal::IncorrectParam(
                      error => 'Unknown store method <'.$args{store}.'>'
                  );
        }
    }

    if (defined $args{formula}) {
        $params->{formula} = $args{formula};
        delete $args{formula};
    }

    if (defined $params) {
        $args{param_preset_id} = ParamPreset->new(params => $params)->id;
    }

    return $class->SUPER::new(%args);
}


=pod
=begin classdoc

This method evaluates a given formula w.r.t. given values for each variable of the formula.

A formula is a mathematical or logical equation in which variable are denoted 'idx' where x is
an integer.

If no formula is given, method will try to find a 'formula' field in the instance paramPresets

@param values hash of values for each variables (e.g. { 47 => 1, 32 => 2})

@optional formula a given formula (e.g. 'id47 + 2 * id32')

@return evaluation of the formula (e.g. '5' for the previous example)

=end classdoc
=cut

sub computeFormula {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => ['values']);

    if ((! defined $args{formula}) && (! $self->_hasFormula) ) {
        throw Kanopya::Exception::Internal(error => 'Metric has no formula')
    }

    my $formula = $args{formula} || $self->param_preset->load->{formula};

    return Formula->compute(values => $args{values}, formula => $formula);
}


=pod
=begin classdoc

Return the last value of the metric

@optional memoization hash table of memoization.
          If a memoization hash is given and contains a key/value {$self->id => value}, the method
          will return 'value' instead of retrieving it.
          If a memozation hash is given and has no key '$self->id' the method will retrieve the value
          and store it in the memoization hash table.

@return int last value of the metric

=end classdoc
=cut

sub lastValue {
    my ($self, %args) = @_;

    if (defined $args{memoization}->{$self->id}) {
        return $args{memoization}->{$self->id};
    }

    my $values = $self->lastData;

    if (defined $args{memoization}) {
        $args{memoization}->{$self->id} = $values->{value};
    }

    return $values->{value};
}


=pod
=begin classdoc

Return all values between two timestamps. Currently this method only works for metrics with storage.

@param start_time start timestamp
@param stop_time end timestamp

@return hashtable {timestamp => value} or empty hash for not stored metric

=end classdoc
=cut

sub evaluateTimeSerie {
    my ($self, %args) = @_;
    General::checkParams args => \%args, required => ['start_time','stop_time'];

    if (! $self->_hasStore) {
        throw Kanopya::Exception::Internal(
                  error => 'Metric <' . $self->id . '> has no storage, cannot be evaluated'
              );
    }

    my $hashref = {};

    if ($self->_hasStore) {
        $hashref = $self->fetch(%args);

        # Fetch values are directly received from rrd
        # When data is jsonified by the API, it considers them as string
        # instead of numbers. We force the data to be considers as a number by adding 0.0

        for my $key (keys %$hashref) {
            if (defined $hashref->{$key}) {
                $hashref->{$key} += 0.0;
            }
        }
        # return %$hashref;
        return wantarray ? %$hashref : $hashref;
    }

    # TODO deal with not stored metrics
    return $hashref;

}


=pod
=begin classdoc

Currently same method as lastValue.

=end classdoc
=cut

sub evaluate {
    my ($self, %args) = @_;

    if (! $self->_hasStore) {
        throw Kanopya::Exception::Internal(
                  error => 'Metric <' . $self->id . '> has no storage, cannot be evalated'
              );
    }

    # TODO Manage storage of not stored metrics
    return $self->lastValue;
}


=pod
=begin classdoc

General metric has no unit.
This method must be overriden to particular unit.

=end classdoc
=cut

sub getUnit {
    # TODO  store unit in param preset
    return '';
}


=pod
=begin classdoc

Update data in stored metric.
The method will create the DB if it has not been created yet

@param time timestamp

@optional value (undef if not defined)

@optional time_step Storage step for configuration database
@optional storage_duration Storage duration for configuration database

=end classdoc
=cut

sub updateData {
    my ($self, %args) = @_;
    General::checkParams(args => \%args,
                         optional => {time             => time(),
                                      value            => 'U',
                                      time_step        => undef,
                                      storage_duration => undef});

    if (! $self->_hasStore) {
        throw Kanopya::Exception::Internal(
                  error => 'Metric <' . $self->id . '> has no storage, cannot be updated'
              );
    }

    # If no time_step / storage_duration is given, check if some values are stored in param presets
    my $pp = $self->param_preset;
    my $param = $pp->load;
    $param->{time_step} = $param->{time_step} || $args{time_step};
    $param->{storage_duration} = $param->{storage_duration} || $args{storage_duration};
    $pp->update(params => $param);

    return $self->_timedata->updateTimeDataStore(metric_id => $self->id, %args);
}


=pod
=begin classdoc

Reset metric database

@optional time_step time_step of the new configuration
@optional storage_duration storage_duration of the new configuration

=end classdoc
=cut

sub resetData {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         optional => { time_step => $self->{config}->{time_step},
                                       storage_duration  => $self->{config}->{storage_duration}});

    if (! $self->_hasStore) {
        throw Kanopya::Exception::Internal(
                  error => 'Metric <' . $self->id . '> has no storage, cannot be reseted'
              );
    }

    my $pp = $self->param_preset->load;
    $args{storage_duration} = $args{storage_duration} || $pp->{storage_duration};
    $args{time_step} = $args{time_step} || $pp->{time_step};

    if (! (defined $args{time_step} && defined $args{storage_duration})) {
        throw Kanopya::Exception::Internal('Missing time_step or storage_duration');
    }
    # TODO instead of deleting & creating, one must export, delete and reimport
    # delete old rrd
    $self->_timedata->deleteTimeDataStore(name => $self->id);
    #create new rrd
    return $self->_timedata->createTimeDataStore(name => $self->id, %args);
}


=pod

=begin classdoc

Returns clustermetric values between start_time and stop_time

@param start_time start time in epoch
@param stop_time stop time in epoch

@return hashref {timestamp => value}

=end classdoc

=cut

sub fetch {
    my ($self, %args) = @_;
    General::checkParams(args     => \%args,
                         optional => {stop_time  => time(),
                                      start_time => time() - 60*60},
                                      output     => 'hash');

    if (! $self->_hasStore) {
        throw Kanopya::Exception::Internal(
                  error => 'Metric <' . $self->id . '> has no storage, cannot fetch data'
              );
    }

    return $self->_timedata->fetchTimeDataStore(
               name   => $self->id,
               start  => $args{start_time},
               end    => $args{stop_time},
               output => $args{output},
           );
}


=pod

=begin classdoc

Retrieve metric last data

@return hashref {timestamp => value}

=end classdoc

=cut

sub lastData {
    my ($self, %args) = @_;

    if (! $self->_hasStore) {
        throw Kanopya::Exception::Internal(
                  error => 'Metric <' . $self->id . '> has no storage, cannot retrieve last data'
              );
    }

    my $values = {};
    try  {
        $values = $self->_timedata->getLastUpdatedValue(metric_uid => $self->id);
    }
    catch (Kanopya::Exception::Internal $err) {
        $values = {};
    }
    catch ($err) {
        $err->rethrow();
    }
    return $values;
}


=pod

=begin classdoc

Delete instance

Method is overridden in order to delete storage database

=end classdoc

=cut

sub delete {
    my $self = shift;
    if ($self->_hasStore) {
        $self->_timedata->deleteTimeDataStore(name => $self->id);
    }
    return $self->SUPER::delete();
}


=pod

=begin classdoc

Resize storage

@param storage_duration
@param old_storage_duration
@param time_step

=end classdoc

=cut

sub resizeData {
    my ($self, %args) = @_;
    General::checkParams(args => \%args,
                         required => ['storage_duration', 'old_storage_duration', 'time_step']);

    if (! $self->_hasStore) {
        throw Kanopya::Exception::Internal(
                  error => 'Metric <' . $self->id . '> has no storage, cannot resize data'
              );
    }

    return $self->_timedata->resizeTimeDataStore(metric_id => $self->id, %args);
}


=pod

=begin classdoc

@return boolean whether metric has a storage system

=end classdoc

=cut

sub _hasStore {
    my ($self) = @_;
    my $pp = $self->param_preset;
    return (defined $pp) && (defined $pp->load->{store});
}


=pod

=begin classdoc

@return boolean whether metric has a formula

=end classdoc

=cut

sub _hasFormula {
    my ($self) = @_;
    my $pp = $self->param_preset;
    return (defined $pp) && (defined $pp->load->{formula});
}


=pod

=begin classdoc

    return instance storage manager

=end classdoc

=cut

sub _timedata {
    my ($self) = @_;

    if (defined $self->{_timedata}) {
        return $self->{_timedata};
    }

    if (! $self-> _hasStore) {
        throw Kanopya::Exception::Internal(
                  error => 'Metric has no store system'
              );
    }

    $self->{_timedata} = TimeData->new(store => $self->param_preset->load->{store});
    return  $self->{_timedata};
}



1;
