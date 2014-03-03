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

DataModel is an abstract class which represent any model able to perform a prediction (forecast) on a given
dataset. A DataModel can need a configuration for being able to predict something (configure method), and
predictions can be proceeded using the predict method. The label method must give a text representation of
the data model, and is generally used for debugging.

The main target of that abstract class is to provide a standard interface for forecasting model in Kanopya,
enabling a simple way to enrich the Kanopya's forecast module with new forecasting models.

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

my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    combination_id => {
        pattern => '^\d+$',
        is_mandatory => 0,
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

First method called when using a DataModel. All the operations required to configure a model or train it
before it is able to perform any prediction should be done in this method, especially the one that need to be
stored in database.

@param data A reference to an array containing the values of the time serie.
@param freq The frequency (or seasonality) of the time serie.
@param predict_start The starting point wished for the prediction (in points, and not in timestamps !).
@param predict_end The ending point wished for the prediction (in points !).
@param combination_id (optional) : The combination's id linked to the DataModel.
@param node_id (optional) : The node's id linked to the DataModel.

=end classdoc

=cut

sub configure {
    throw Kanopya::Exception::NotImplemented(error => 'DataModel : Method configure not implemented');
}

=pod

=begin classdoc

Method called to perform a prediction (forecast) using a DataModel.

@param data A reference to an array containing the values of the time serie.
@param freq The frequency (or seasonality) of the time serie.
@param predict_start The starting point wished for the prediction (in points, and not in timestamps !).
@param predict_end The ending point wished for the prediction (in points !).
@param combination_id (optional) : The combination's id linked to the DataModel.
@node_id (optional) : The node's id linked to the DataModel.

@return A reference to an array containing the forecast values.

=end classdoc

=cut

sub predict {
    throw Kanopya::Exception::NotImplemented(error => 'DataModel : Method predict not implemented');
}

=pod

=begin classdoc

Gives a human readable string representation of a DataModel (to implement using the time_label method).

@return A human readable string representation of a DataModel.

=end classdoc

=cut

sub label {
    throw Kanopya::Exception::NotImplemented(error => 'DataModel : Method label not implemented');
}

=pod

=begin classdoc

Indicates whether the model is seasonal or not, ie if the model need a seasonality value to be able to
configure itself and forecast.

@return true if the model needs a seasonality value to configure or/and forecast, false else.

=end classdoc

=cut

sub isSeasonal {
    throw Kanopya::Exception::NotImplemented(error => 'DataModel : Method isSeasonal not implemented');
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
    my $format = '%02i-%02i-%02i %02i:%02i';

    my ($sec, $min, $hour, $day,$month,$year) = (localtime($self->start_time))[0,1,2,3,4,5];
    my $start_date = sprintf($format, $month+1, $day, ($year+1900)%100, $hour, $min);

    ($sec, $min, $hour, $day,$month,$year) = (localtime($self->end_time))[0,1,2,3,4,5];
    my $end_date = sprintf($format, $month+1, $day, ($year+1900)%100, $hour, $min);

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

1;
