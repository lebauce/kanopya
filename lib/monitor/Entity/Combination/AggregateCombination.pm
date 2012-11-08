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

@see <package>Entity::Clustermetric</package>

=end classdoc

=cut

package Entity::Combination::AggregateCombination;

use strict;
use warnings;
use Data::Dumper;
use base 'Entity::Combination';
use Entity::Clustermetric;
use TimeData::RRDTimeData;
use Kanopya::Exceptions;
use List::Util qw {reduce};
use List::MoreUtils qw {any} ;
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
        'getDependencies' => {
            'description' => 'return dependencies tree for this object',
            'perm_holder' => 'entity',
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
    return $self->toString();
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
        return $class->get( id => $args{aggregate_combination_id})->clone(
            dest_service_provider_id => $args{service_provider_id}
        );
    }

    my $formula = (\%args)->{aggregate_combination_formula};
    _verify ($args{aggregate_combination_formula});

    my $self = $class->SUPER::new(%args);
    my $toString = $self->toString();
    if ((! defined $args{aggregate_combination_label}) || $args{aggregate_combination_label} eq '') {
        $self->setAttr (name=>'aggregate_combination_label', value => $toString);
    }
    $self->setAttr (name=>'aggregate_combination_formula_string', value => $toString);
    $self->save ();
    return $self;
}


=pod

=begin classdoc

Verify that each ids of the given formula refers to a Clustermetric

=end classdoc

=cut

sub _verify {

    my $formula = shift;

    my @array = split(/(id\d+)/,$formula);

    for my $element (@array) {
        if ($element =~ m/id\d+/) {
            if (!(Entity::Clustermetric->search(hash => {'clustermetric_id'=>substr($element,2)}))){
                my $errmsg = "Creating combination formula with an unknown clusterMetric id ($element) ";
                $log->error($errmsg);
                throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
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
    my ($self, %args) = @_;

    my $depth = (defined $args{depth}) ? $args{depth} : -1;
    if ($depth == 0) {
        return $self->aggregate_combination_label;
    }

    my $formula = $self->aggregate_combination_formula;

    # Split aggregate_rule id from $formula
    my @array = split(/(id\d+)/, $formula);
    # replace each rule id by its evaluation
    for my $element (@array) {
        if ($element =~ m/id\d+/) {
            $element = ($depth > 0) ?
                Entity::Clustermetric->get('id'=>substr($element,2))->toString(depth => $depth - 1):
                Entity::Clustermetric->get('id'=>substr($element,2))->clustermetric_formula_string;
        }
    }
    return List::Util::reduce { $a . $b } @array;
}

=pod

=begin classdoc

Compute the combination value between two dates. Use getValuesFromDB() method of Clustermetric.
May be deprecated.

@param start_time the begining date
@param stop_time the ending date

@return the computed value

=end classdoc

=cut

sub computeValues{
    my $self = shift;
    my %args = @_;

    General::checkParams args => \%args, required => ['start_time','stop_time'];

    my @cm_ids = $self->dependentClusterMetricIds();
    my %allTheCMValues;
    foreach my $cm_id (@cm_ids){
        my $cm = Entity::Clustermetric->get('id' => $cm_id);
        $allTheCMValues{$cm_id} = $cm -> getValuesFromDB(%args);
    }
    return $self->computeFromArrays(%allTheCMValues);
}

=pod

=begin classdoc

Compute the combination value using the last Clustermetric values. Use getLastValueFromDB() method of Clustermetric.

@return the computed value or undef if one Clustermetric is undef

=end classdoc

=cut

sub computeLastValue{
    my $self = shift;
    my $formula = $self->aggregate_combination_formula;

    #Split aggregate_rule id from $formula
    my @array = split(/(id\d+)/,$formula);
    #replace each rule id by its evaluation
    for my $element (@array) {
        if ($element =~ m/id\d+/) {
            #Remove "id" from the begining of $element, get the corresponding aggregator and get the lastValueFromDB
            $element = Entity::Clustermetric->get('id'=>substr($element,2))->getLastValueFromDB();
            if (not defined $element) {
                return undef;
            }
        }
    }

    my $res = undef;
    my $arrayString = '$res = '."@array";

    #Evaluate the logic formula

    #$log->info('Evaluate combination :'.($self->toString()));
    eval $arrayString;

    $log->info("$arrayString");
    return $res;
}


=pod

=begin classdoc

Compute the combination value using a hash value for each Clustermetric.
May be deprecated.

@param a value for each clustermetric of the formula.

@return the computed value

=end classdoc

=cut

sub compute{
    my $self = shift;
    my %args = @_;

    my @requiredArgs = $self->dependentClusterMetricIds();

    checkMissingParams(args => \%args, required => \@requiredArgs);

    foreach my $cm_id (@requiredArgs) {
        if (! defined $args{$cm_id}) {
            return undef;
        }
    }

    my $formula = $self->aggregate_combination_formula;

    #Split aggregate_rule id from $formula
    my @array = split(/(id\d+)/,$formula);
    #replace each rule id by its evaluation
    for my $element (@array) {
        if ($element =~ m/id\d+/) {
            $element = $args{substr($element,2)};
            if (!defined $element) {
                return undef;
            }
        }
     }

    my $res = undef;
    my $arrayString = '$res = '."@array";

    #Evaluate the logic formula

    #$log->info('Evaluate combination :'.($self->toString()));
    eval $arrayString;
    $log->info("$arrayString");
    return $res;
}


=pod

=begin classdoc

Return the ids of Clustermetrics of the formulas with no doublon.

@return array of ids of Clustermetrics of the formulas with no doublon.

=end classdoc

=cut

sub dependentClusterMetricIds() {
    my $self = shift;
    my %ids = map { $_ => undef } ($self->aggregate_combination_formula =~ m/id(\d+)/g);
    return keys %ids;
}


=pod

=begin classdoc

Remove duplicate from an array.

@return array wi no doublons.

=end classdoc

=cut

sub uniq {
    return keys %{{ map { $_ => 1 } @_ }};
}


=pod

=begin classdoc

Compute the combination value using a hash of timestamped values for each Clustermetric.
May be deprecated.

@param a value for each clustermetric of the formula.

@return the timestamped computed values

=end classdoc

=cut

sub computeFromArrays{
    my $self = shift;
    my %args = @_;

    my @requiredArgs = $self->dependentClusterMetricIds();

    General::checkParams args => \%args, required => \@requiredArgs;

    # Merge all the timestamps keys in one arrays

    my @timestamps;
    foreach my $cm_id (@requiredArgs){
       @timestamps = (@timestamps, (keys %{$args{$cm_id}}));
    }
    @timestamps = uniq @timestamps;

    my %rep;
    foreach my $timestamp (@timestamps){
        my %valuesForATimeStamp;
        foreach my $cm_id (@requiredArgs){
            $valuesForATimeStamp{$cm_id} = $args{$cm_id}->{$timestamp};
        }
        $rep{$timestamp} = $self->compute(%valuesForATimeStamp);
    }
    return %rep;
}

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

Return the formula of the combination in which the indicator id is
replaced by its Unit or by '?' when unit is not specified in database

=end classdoc

=cut

sub getUnit {
    my ($self, %args) = @_;

    # Split aggregate_rule id from formula
    my @array = split(/(id\d+)/,$self->aggregate_combination_formula);
    # Replace each rule id by its evaluation
    my $ref_element;
    my $are_same_units = 0;
    for my $element (@array) {
        if( $element =~ m/id\d+/)
        {
            $element = Entity::Clustermetric->get('id'=>substr($element,2))->getUnit();

            if (not defined $ref_element) {
                $ref_element = $element;
            } else {
                if ($ref_element eq $element) {
                    $are_same_units = 1;
                } else {
                    $are_same_units = 0;
                }
            }
        }
    }
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
        my $attrs = $args{attrs};
        $attrs->{aggregate_combination_formula}  = $self->_cloneFormula(
            dest_sp_id              => $attrs->{service_provider_id},
            formula                 => $attrs->{aggregate_combination_formula},
            formula_object_class    => 'Entity::Clustermetric'
        );
        return %$attrs;
    };

    $self->_importToRelated(
        dest_obj_id         => $args{'dest_service_provider_id'},
        relationship        => 'service_provider',
        label_attr_name     => 'aggregate_combination_label',
        attrs_clone_handler => $attrs_cloner
    );
}

=pod

=begin classdoc

Method from NodemetricCombination call from mother class. Return the same value than >computeLastValue()

@return computeLastValue() method

=end classdoc

=cut

sub computeValueFromMonitoredValues {
    my $self = shift;
    return $self->computeLastValue()
}

sub combination_formula_string {
    my $self = shift;
    return $self->aggregate_combination_formula_string
}

sub updateFormulaString {
    my $self = shift;
    $self->setAttr (name=>'aggregate_combination_formula_string', value => $self->toString());
    $self->save ();
    my @conditions = $self->getDependentConditions;
    map { $_->updateFormulaString } @conditions;
    return $self;
}


sub update {
    my ($self, %args) = @_;
    my $rep = $self->SUPER::update (%args);
    $self->updateFormulaString;
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
