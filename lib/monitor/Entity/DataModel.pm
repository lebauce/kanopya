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

Base class to configure a model for the data of a combination.
Can be configured from a start time to a end time.
Once configured, the DatamModel stores the parameters which allow data forecasting

@since    2013-Feb-13
@instance hash
@self     $self

=end classdoc

=cut

package Entity::DataModel;

use base 'Entity';

use strict;
use warnings;

use Kanopya::Exceptions;
use Log::Log4perl "get_logger";
use Data::Dumper;
use List::Util;
my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    combination_id => {
        pattern => '^\d+$',
        is_mandatory => 1,
        is_extended => 0
    },
    node_id => {
        pattern => '^\d+$',
        is_mandatory => 0,
        is_extended => 0
    },
    param_preset_id => {
        pattern => '^\d+$',
        is_mandatory => 0,
        is_extended => 0
    },
    start_time => {
        pattern => '^.*$',
        is_mandatory => 0,
        is_extended => 0
    },
    end_time => {
        pattern => '^.*$',
        is_mandatory => 0,
        is_extended => 0
    },
};

sub getAttrDef { return ATTR_DEF; }

sub methods {
    return {
        predict => {
            description => 'Predict metric values.',
            perm_holder => 'entity',
        }
    };
}

=pod

=begin classdoc

@constructor

Create a new instance of the class. Constructor is overridden to check params.
A DataModel of a NodemetricCombination needs a node_id parameter to specify which node is modeled.

@return a class instance

=end classdoc

=cut

sub new {
    my $class = shift;
    my %args = @_;

    if (defined $args{combination_id}) {
        my $combination = Entity->get(id => $args{combination_id});

        # DataModel of a NodemetricCombination needs a related node
        if ($combination->isa('Entity::Combination::NodemetricCombination')) {
            if (! defined $args{node_id}) {
                $errmsg = "A nodemetric combination datamodel needs a node_id argument";
                throw Kanopya::Exception(error => $errmsg);
            }
        }
        elsif ($combination->isa('Entity::Combination::ClustermetricCombination')) {
            $log->info('Ignoring node_id in the data model of a clustermetric combination');
            $args{node_id} = undef;
        }
    }
    my $self = $class->SUPER::new(%args);
    return $self;
}


=pod

=begin classdoc

Computes the coefficient of determination (or R squared) of a model.

@param data array containing the real data
@param data_model array containing the computed data

@return coefficient of determination (or R squared)

=end classdoc

=cut

sub computeRSquared {
    my ($self, %args) = @_;
    General::checkParams(args     => \%args, required => ['data', 'data_model']);

    # Compute the coefficient of determination according to its formal definition
    my $data_avg = List::Util::sum(@{$args{data}}) / @{$args{data}};
    my $SSerr = List::Util::sum( List::MoreUtils::pairwise {($a - $b)**2} @{$args{data}}, @{$args{data_model}});
    my $SStot = List::Util::sum( map {($_ - $data_avg)**2} @{$args{data}} );

    return (1 - $SSerr / $SStot);
}

=pod

=begin classdoc

Returns the already computed coefficient of determination (or R squared) of a model. Return undef
if the coefficient has not be computed yet

@return coefficient of determination (or R squared)

=end classdoc

=cut

sub getRSquared {
    my ($self, @args) = @_;
    my $pp = $self->param_preset->load;
    return $pp->{rSquared};
}

sub configure {
    throw Kanopya::Exception(error => 'Method not implemented');
}

sub predict {
    throw Kanopya::Exception(error => 'Method not implemented');
}

sub label {
    throw Kanopya::Exception(error => 'Method not implemented');
}


=pod

=begin classdoc

Format the current time in human readable form

@return the time in human readable form

=end classdoc

=cut

sub time_label {
    my $self = shift;

    my $time = time;    # or any other epoch timestamp
    my @months = ("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");

    my ($sec, $min, $hour, $day,$month,$year) = (localtime($self->start_time))[0,1,2,3,4,5];
    my $start_date = $months[$month]." ".$day.", ".($year+1900)." ".$hour.":".$min.":".$sec;

    ($sec, $min, $hour, $day,$month,$year) = (localtime($self->end_time))[0,1,2,3,4,5];
    my $end_date = $months[$month]." ".$day.", ".($year+1900)." ".$hour.":".$min.":".$sec;

    return "[$start_date -> $end_date]";
}



=pod

=begin classdoc

Contruct an array of time stamps from a start time to a end time w.r.t. a sampling period (step)

@param start_time the start time
@param end_time the end time
@param sampling_period the sampling period

@return array of time stamps from start_time

=end classdoc

=cut

sub constructTimeStamps {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => ['start_time', 'end_time', 'sampling_period']);

    my @timestamps= ();
    for (my $ts = $args{start_time} ; $ts <= $args{end_time} ; $ts += $args{sampling_period}) {
        push @timestamps, $ts;
    }
    return \@timestamps;
}


=pod

=begin classdoc

Method called from child class instance to compute the forcasting.
By default the method return a hash with two keys 'timestamps' (reference to an array of timestamps)
and 'values' (reference an array of forecasted values).

@param function_args all the arguments of the forcasting function

@optional time_format 'ms' returns time in milliseconds
@optional data_format 'pair' returns an array of references of pair [timestamp, value]

@return the timestamps and forecasted values with the chosen data_format.

=end classdoc

=cut

sub constructPrediction {
    my ($self, %args) = @_;

    my $function_args = $args{function_args};

    # Construct timestamps if not defined
    if (! defined $args{timestamps}) {
        $args{timestamps} = $self->constructTimeStamps(
                                start_time      => $args{start_time},
                                end_time        => $args{end_time},
                                sampling_period => $args{sampling_period},
                            );
    }

    my @predictions;
    my @timestamps_temp;

    # Compute prediction with good format
    for my $ts (@{$args{timestamps}}) {

        $function_args->{ts} = $ts;
        my $value = $self->prediction_function(function_args => $function_args);

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
1;
