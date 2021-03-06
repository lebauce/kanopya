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

Mathematical formula of cluster metrics.

@see <package>Entity::Metric::Clustermetric</package>
@see <package>Entity::Rule::AggregateRule</package>

=end classdoc

=cut

package Entity::Metric::Combination::AggregateCombination;
use base Entity::Metric::Combination;

use strict;
use warnings;
use Data::Dumper;
use Entity::Metric;
use Kanopya::Exceptions;
use List::Util qw {reduce};
use DataModelSelector;
use TryCatch;

# logger
use Log::Log4perl "get_logger";
my $log = get_logger("");

use constant ATTR_DEF => {
    aggregate_combination_id => {
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_extended     => 0,
        is_editable     => 0,
    },
    aggregate_combination_label => {
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_extended     => 0,
        is_editable     => 1,
    },
    aggregate_combination_formula => {
        pattern         => '^((id\d+)|[ .+*()-/]|\d)+$',
        is_mandatory    => 1,
        is_extended     => 0,
        is_editable     => 1,
        description     =>  "Construct a formula by service metric's names with all mathematical operators."
                            ." It's possible to use parenthesis with spaces between each element of the formula."
                            ." Press a letter key to obtain the available choice.",
    },
    aggregate_combination_formula_string => {
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_extended     => 0,
        is_editable     => 1,
    },
    formula_label => {
        is_virtual      => 1,
    }
};

sub getAttrDef { return ATTR_DEF; }

sub getAttr {
    my $self = shift;
    my %args = @_;

    if ($args{name} eq "unit") {
        return $self->getUnit();
    }
    return $self->SUPER::getAttr(%args);
}

sub methods {
    return {
        'toString'  => {
          'description' => 'toString',
          'perm_holder' => 'entity'
        },
    }
}


=pod

=begin classdoc

Label virtual attribute getter

=end classdoc

=cut

sub label {
    my $self = shift;
    return $self->aggregate_combination_label;
}


=pod

=begin classdoc

Formula label virtual attribute getter

=end classdoc

=cut

sub formula_label {
    my $self = shift;
    return $self->aggregate_combination_formula_string;
}


=pod

=begin classdoc

@constructor

Create a new instance of the class. Compute automatically the label if not specified in args.

@return a class instance

=end classdoc

=cut

sub new {
    my $class = shift;
    my %args = @_;

    # Clone case
    if ($args{aggregate_combination_id}) {
        return $class->get(id => $args{aggregate_combination_id})->clone(
            dest_service_provider_id => $args{service_provider_id}
        );
    }

    my $formula = (\%args)->{aggregate_combination_formula};
    _verify ($args{aggregate_combination_formula});

    my $self = $class->SUPER::new(%args);

    my $toString = $self->toString();
    if ((! defined $args{aggregate_combination_label}) || $args{aggregate_combination_label} eq '') {
        $self->setAttr(name => 'aggregate_combination_label', value => $toString);
    }
    $self->setAttr(name => 'combination_unit', value => $self->computeUnit());
    $self->setAttr(name => 'aggregate_combination_formula_string', value => $toString);
    $self->save();
    return $self;
}


=pod

=begin classdoc

Verify that each ids of the given formula refers to a Metric

=end classdoc

=cut

sub _verify {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, optional => {formula => ''});

    my @array = split(/(id\d+)/,$args{formula});

    for my $element (@array) {
        if ($element =~ m/id\d+/) {
            try {
                Entity::Metric->get(id => substr($element,2));
            }
            catch (Kanopya::Exception::Internal::NotFound $err) {
                my $errmsg = "Creating combination formula with an unknown metric id ($element) ";
                throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
            }
            catch ($err) {
                $err->rethrow();
            }
        }
    }
}


=pod

=begin classdoc

Return a string representation of the entity

@return a string representation of the entity

=end classdoc

=cut

sub toString {
    my $self = shift;

    # Split aggregate_rule id from $formula
    my @array = split(/(id\d+)/, $self->aggregate_combination_formula);
    # replace each rule id by its evaluation
    for my $element (@array) {
        if ($element =~ m/id\d+/) {
            $element = Entity::Metric->get('id' => substr($element,2))->label;
        }
    }
    return List::Util::reduce { $a . $b } @array;
}


=pod
=begin classdoc

Compute the combination value between two dates.

@param start_time the begining date
@param stop_time the ending date

@return the computed value

=end classdoc
=cut

sub evaluateTimeSerie {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => ['start_time','stop_time']);

    $args{formula} = $self->aggregate_combination_formula;

    return $self->evaluateFormula(%args);
}


=pod
=begin classdoc

Compute the a given formula value between two dates.

@param start_time the begining date
@param stop_time the ending date
@param formula a given formula 'idxxx + idyyy'
       where xxx and yyy are ids of Metric instances which can be fetched

@return the computed value

=end classdoc
=cut

sub evaluateFormula {
    my ($class, %args) = @_;

    General::checkParams(
        args => \%args,
        required => ['start_time','stop_time', 'formula'],
    );

    my %allTheCMValues;
    foreach my $cm_id (Formula->getDependentIds(formula => $args{formula})){
        my $metric = Entity::Metric->get('id' => $cm_id);
        $allTheCMValues{$cm_id} = $metric->fetch(%args);
    }

    my $res = Formula->computeTimeSerie(
                  values => \%allTheCMValues,
                  formula => $args{formula},
              );
    return wantarray ? %$res : $res;
}

=pod

=begin classdoc

Evaluate current or predicted combination value.

@optional timestamp if timestamp > actual time, the method evaluate predicted value at timestamp() using
       DataModelSelector of the combinations. Otherwise evaluate with the lastValue.

@optional nodes array used to return a hashref of the same value for each node

@return evaluation (value or hashref depending on the context (noderule or aggregaterule)

=end classdoc

=cut

sub evaluate {
    my ($self, %args) = @_;
     General::checkParams(args => \%args, optional => {'nodes' => undef, 'timestamp' => 0});

    if (defined $args{memoization}->{$self->id}) {
        return $args{memoization}->{$self->id};
    }

    my $value = ($args{timestamp} > time()) ? $self->_predict(%args)
                                            : $self->_evaluateLastValue(%args);

    if (defined $args{memoization}) {
        $args{memoization}->{$self->id} = $value;
    }

    return $value;
}


=pod

=begin classdoc

Evaluate predicted combination value.

@param timestamp assume that timestamp > actual time. Compute predicted value at timestamp with best DataModel.
       Use same the delta time between actual time and timestamp for training data.

@return evaluation

=end classdoc

=cut

sub _predict {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => ['timestamp'],
                                         optional => {'nodes'      => undef,
                                                      'model_list' => undef});
    my $time = time();

    my $timeserie = $self->evaluateTimeSerie(start_time => 2 * $time - $args{timestamp},
                                             stop_time  => $time,);

    my $prediction = DataModelSelector->autoPredictData(
                         predict_start_tstamps => $args{timestamp},
                         predict_end_tstamps   => $args{timestamp},
                         timeserie             => $timeserie,
                         model_list            => $args{model_list},
                     );

    my $res = $prediction->{values}->[0];

    if (defined $args{nodes}) {
        my %hash = map {$_->id => $res} @{$args{nodes}};
        return \%hash;
    }

    return $res;
}


=pod

=begin classdoc

Compute the combination value using the last Metric values.

@return the computed value or undef if one Metric is undef

=end classdoc

=cut

sub _evaluateLastValue {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, optional => {'nodes' => undef});

    my $values = {};

    my @ids = $self->dependentMetricIds();
    for my $id (@ids) {
        $values->{$id} = Entity::Metric->get(id => $id)->evaluate(%args);
    }

    my $res = Formula->compute(formula => $self->aggregate_combination_formula,
                               values  => $values);

    if (defined $args{nodes}) {
        my %hash = map {$_->id => $res} @{$args{nodes}};
        return \%hash;
    }
    return $res;
}


=pod

=begin classdoc

Return the Entity::Metric ids of the formulas with no doublon.

@return array of Entity::Metric ids of the formulas with no doublon.

=end classdoc

=cut

sub dependentMetricIds {
    my $self = shift;
    return Formula->getDependentIds(formula => $self->aggregate_combination_formula);
}


=pod

=begin classdoc

Compute the formula of the combination in which the indicator id is
replaced by its Unit or by '?' when unit is not specified in database

=end classdoc

=cut

sub computeUnit {
    my ($self, %args) = @_;

    # Split aggregate_rule id from formula
    my @array = split(/(id\d+)/,$self->aggregate_combination_formula);
    # Replace each rule id by its evaluation
    my $ref_element;
    my $are_same_units = 0;

    for my $element (@array) {
        if ($element =~ m/id\d+/) {
            $element = Entity::Metric->get('id' => substr($element,2))->getUnit();

            if (not defined $ref_element) {
                $ref_element = $element;
            } else {
                $are_same_units = ($ref_element eq $element) ? 1 : 0;
            }
        }
    }

    # Warning, this code works only when combination is composed by + or - operator
    # return wrong value when composed by / or *
    # TODO improve

    if ($are_same_units == 1) {
        @array = $ref_element;
    }
    #$log->info(@array);
    return join('',@array);
}

=pod

=begin classdoc

Return the dependent indicator ids. Since AggregateCombination formula does not contains indicator,
this method return void.

@return void array

=end classdoc

=cut

sub getDependentIndicatorIds {
    return ();
}

=pod

=begin classdoc

Clones the combination and all related objects.
Links clones to the specified service provider. Only clones objects that do not exist in service provider.

@param dest_service_provider_id id of the service provider where to import the clone

@return clone object

=end classdoc

=cut

sub clone {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => ['dest_service_provider_id']);

    my $attrs_cloner = sub {
        my %args = @_;
        $args{attrs}->{aggregate_combination_formula} = $self->_cloneFormula(
            dest_sp_id    => $args{attrs}->{service_provider_id},
            formula       => $args{attrs}->{aggregate_combination_formula},
            formula_class => 'Entity::Metric'
        );
        return $args{attrs};
    };

    return $self->_importToRelated(
        dest_obj_id         => $args{'dest_service_provider_id'},
        relationship        => 'service_provider',
        label_attr_name     => 'aggregate_combination_label',
        attrs_clone_handler => $attrs_cloner
    );
}

# Virtual attribute
sub combination_formula_string {
    my $self = shift;
    return $self->aggregate_combination_formula_string
}


=pod

=begin classdoc

Compute and update the instance formula_string attribute and call the update of the formula_string
attribute of the objects which depend on the instance.

=end classdoc

=cut

sub updateFormulaString {
    my $self = shift;
    $self->setAttr (name=>'aggregate_combination_formula_string', value => $self->toString());
    $self->save ();
    my @conditions = $self->getDependentConditions;
    map { $_->updateFormulaString } @conditions;
}


=pod

=begin classdoc

Redefine update to call formula_string and unit attributes update.

=end classdoc

=cut

sub update {
    my ($self, %args) = @_;
    my $rep = $self->SUPER::update(%args);
    $self->updateFormulaString;
    $self->updateUnit;
    return $rep;
}


=pod

=begin classdoc

Delete the object and all the conditions which depend on it.

=end classdoc

=cut

sub delete {
    my $self = shift;
    my @conditions = (
        $self->aggregate_condition_left_combinations,
        $self->aggregate_condition_right_combinations,
        $self->nodemetric_condition_left_combinations,
        $self->nodemetric_condition_right_combinations,
    );

    while (@conditions) {
        (pop @conditions)->delete();
    }
    return $self->SUPER::delete();
};
1;
