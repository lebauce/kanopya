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

General Combination class. Implement delete function of combinations and getDependencies.

@since    2012-Oct-20
@instance hash
@self     $self

=end classdoc
=cut

package Entity::Metric::Combination;
use base Entity::Metric;

use strict;
use warnings;

use Data::Dumper;
# logger
use Log::Log4perl "get_logger";
my $log = get_logger("");

use DataModelSelector;

use constant ATTR_DEF => {
    combination_id      =>  {
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_editable     => 0,
    },
    service_provider_id => {
        pattern         => '^.*$',
        is_mandatory    => 1,
        is_editable     => 1,
        is_delegatee    => 1
    },
    combination_unit => {
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_editable     => 1,
    },
    combination_formula_string => {
        is_virtual      => 1,
    }
};

sub getAttrDef { return ATTR_DEF; }

sub methods {
    return {
        evaluateFormula => {
            description => 'retrieve historical value of combination',
        },
        availableDataModels => {
            description => 'return available forecasting data models',
        },
        autoPredict => {
            description => 'forecast combination values',
        },
        getDependencies => {
            description => 'return dependencies tree for this object',
        }
    };
}


=pod
=begin classdoc

Get the list of conditions which depends on the combinations and all the combinations dependencies.

@return the list of conditions which depends on the combination and all the combinations dependencies.

=end classdoc
=cut

sub getDependencies {
    my $self = shift;

    my @conditions = $self->getDependentConditions;

    my %dependencies;
    for my $condition (@conditions) {
        $dependencies{$condition->label} = $condition->getDependencies;
    }
    return \%dependencies;
}


=pod
=begin classdoc

Find AggregateConditions and NodemetricConditions which depends on the combination.

@return array of AggregateConditions and NodemetricConditions

=end classdoc
=cut

sub getDependentConditions {
    my $self = shift;

    my @conditions = (
        $self->aggregate_condition_left_combinations,
        $self->aggregate_condition_right_combinations,
        $self->nodemetric_condition_left_combinations,
        $self->nodemetric_condition_right_combinations,
    );

    return @conditions;
}


=pod
=begin classdoc

Abstract method implemented in ConstantCombination. Used when deleting a condition which has created
a ConstantCombination. Also used to avoid deep recursion.

=end classdoc
=cut

sub deleteIfConstant {
};

sub combination_formula_string {
    return undef;
}


=pod
=begin classdoc

@deprecated

Return the unit attribute. Method used to ensure backward compatibility.
Preferable to get directly the attribute.

@return combination_unit attribute

=end classdoc
=cut

sub getUnit {
    my $self = shift;
    return $self->combination_unit;
}


=pod
=begin classdoc

Update the combination_unit attribute

=end classdoc
=cut

sub updateUnit {
    my $self = shift;
    $self->setAttr(name => 'combination_unit', value => $self->computeUnit());
    $self->save();
}

sub computeUnit {}


sub availableDataModels {
    my ($self, %args) = @_;

    return DataModelSelector->availableDataModels();
}

=pod
=begin classdoc

Combination data forecasting.
Retrieve combination values between data_start and data_end
then call DataModelSelector::autoPredict() to forecast data between specified date

Parameters are roughly the same than DataModelSelector::autoPredict()

@param predict_start_tstamps The starting point wished for the prediction (in timestamps !).
@param predict_end_tstamps The ending point wished for the prediction (in timestamps).
@param data_start The start time if the data is directly loaded from a combination.
@param data_end The end time if the data it directly loaded from a combination.

@optional node_id related node in case of NodemetricCombination
@optional model_list  : The list of the available models for the selection. By default all existing models are
                        used.

@return forecast data ref {timestamps => [t1,t2,...], values => [v1,v2,...]}

=end classdoc
=cut

sub autoPredict {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['data_start', 'data_end', 'predict_start_tstamps', 'predict_end_tstamps'],
                         optional => {'node_id' => undef, 'model_list' => undef}
                         );

    my %rawdata = $self->evaluateTimeSerie(start_time => $args{data_start},
                                           stop_time  => $args{data_end},
                                           node_id    => $args{node_id});
    my %predict_params = (
           timeserie                => \%rawdata,
           predict_start_tstamps    => $args{predict_start_tstamps},
           predict_end_tstamps      => $args{predict_end_tstamps},
       );

    if (defined $args{model_list}) {
        $predict_params{model_list} = $args{model_list};
    }

    return DataModelSelector->autoPredictData(%predict_params);
}

=pod
=begin classdoc

Remove duplicate from an array.

@param data Array ref of values with possible doublons

@return array without doublons.

=end classdoc
=cut

sub uniq {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => ['data']);
    return keys %{{ map { $_ => 1 } @{$args{data}}} };
}


=pod
=begin classdoc

Dynamic param checker.
The difference with General::checkParams is that it only check that required params exist, but they can be null.
TODO Is it really necessary to have this specific method?

@param required Array of required parameters
@param args the checked args

=end classdoc
=cut

sub checkMissingParams {
    my %args = @_;

    my $caller_args = $args{args};
    my $required = $args{required};
    my $caller_sub_name = (caller(1))[3];

    for my $param (@$required) {
        if (! exists $caller_args->{$param} ) {
            my $errmsg = "$caller_sub_name needs a '$param' named argument!";

            # Log in general logger
            # TODO log in the logger corresponding to caller package;
            $log->error($errmsg);
            throw Kanopya::Exception::Internal::IncorrectParam();
        }
    }
}


=pod
=begin classdoc

Utility method used to clone a formula
Clone all objects used in formula and translate formula to use cloned object ids

@param dest_sp_id id of the service provider where to import all cloned objects
@param formula string representing a formula (i.e operators and object ids in the format "idXXX")
@param formula_class class of object used in formula

@return the cloned object

=end classdoc
=cut

sub _cloneFormula {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => ['dest_sp_id', 'formula', 'formula_class']);

    my $formula = $args{formula};
    # Get ids in formula
    my %ids = map { $_ => undef } ($formula =~ m/id(\d+)/g);
    # Clone objects used in formula
    %ids = map {
        $_ => $args{formula_class}->get(id => $_)->clone(dest_service_provider_id => $args{dest_sp_id})->id
    } keys %ids;

    # Replace ids in formula with cloned objects ids
    $formula =~ s/id(\d+)/id$ids{$1}/g;

    return $formula;
}

1;
