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
package Combination::AggregateCombination;

use strict;
use warnings;
use Data::Dumper;
use base 'Combination';
use Clustermetric;
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
        is_editable     => 0
    },
    aggregate_combination_label => {
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_extended     => 0,
        is_editable     => 1
    },
    aggregate_combination_service_provider_id => {
        pattern         => '^.*$',
        is_mandatory    => 1,
        is_extended     => 0,
        is_editable     => 0
    },
    aggregate_combination_formula => {
        pattern         => '^((id\d+)|[ .+*()-/]|\d)+$',
        is_mandatory    => 1,
        is_extended     => 0,
        is_editable     => 1,
        description     =>  "Construct a formula by service metric's names with all mathematical operators."
                            ." It's possible to use parenthesis with spaces between each element of the formula."
                            ." Press a letter key to obtain the available choice."
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
    else {
        return $self->SUPER::getAttr(%args);
    }
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

# Virtual attribute getter
sub formula_label {
    my $self = shift;
    return $self->toString();
}

sub new {
    my $class = shift;
    my %args = @_;

    my $formula = (\%args)->{aggregate_combination_formula};

    _verify($formula);
    my $self = $class->SUPER::new(%args);
    if(!defined $args{aggregate_combination_label} || $args{aggregate_combination_label} eq ''){
        $self->setAttr(name=>'aggregate_combination_label', value => $self->toString());
        $self->save();
    }
    return $self;
}

sub _verify {

    my $formula = shift;

    my @array = split(/(id\d+)/,$formula);

    for my $element (@array) {
        if( $element =~ m/id\d+/)
        {
            if (!(Clustermetric->search(hash => {'clustermetric_id'=>substr($element,2)}))){
             my $errmsg = "Creating combination formula with an unknown clusterMetric id ($element) ";
             $log->error($errmsg);
             throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
            }
        }
    }
}


=head2 toString

    desc: return a string representation of the entity

=cut

sub toString {
    my ($self, %args) = @_;
    my $depth;
    if(defined $args{depth}) {
        $depth = $args{depth};
    }
    else {
        $depth = -1;
    }

    if ($depth == 0) {
        return $self->getAttr(name => 'aggregate_combination_label');
    }
    else {
        my $formula = $self->getAttr(name => 'aggregate_combination_formula');

        # Split aggregate_rule id from $formula
        my @array = split(/(id\d+)/, $formula);
        # replace each rule id by its evaluation
        for my $element (@array) {
            if( $element =~ m/id\d+/)
            {
                # Remove "id" from the begining of $element, get the corresponding aggregator and get the lastValueFromDB
                $element = Clustermetric->get('id'=>substr($element,2))->toString(depth => $depth - 1);
            }
        }
        return List::Util::reduce { $a . $b } @array;
    }
}

sub computeValues{
    my $self = shift;
    my %args = @_;

    General::checkParams args => \%args, required => ['start_time','stop_time'];

    my @cm_ids = $self->dependantClusterMetricIds();
    my %allTheCMValues;
    foreach my $cm_id (@cm_ids){
        my $cm = Clustermetric->get('id' => $cm_id);
        $allTheCMValues{$cm_id} = $cm -> getValuesFromDB(%args);
    }
    return $self->computeFromArrays(%allTheCMValues);
}

sub computeLastValue{
    my $self = shift;

    my $formula = $self->getAttr(name => 'aggregate_combination_formula');

    #Split aggregate_rule id from $formula
    my @array = split(/(id\d+)/,$formula);
    #replace each rule id by its evaluation
    for my $element (@array) {
        if( $element =~ m/id\d+/)
        {
            #Remove "id" from the begining of $element, get the corresponding aggregator and get the lastValueFromDB
            $element = Clustermetric->get('id'=>substr($element,2))->getLastValueFromDB();
            if(not defined $element){
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

sub compute{
    my $self = shift;
    my %args = @_;

    my @requiredArgs = $self->dependantClusterMetricIds();

    checkMissingParams(args => \%args, required => \@requiredArgs);

    foreach my $cm_id (@requiredArgs){
        if( ! defined $args{$cm_id}){
            return undef;
        }
    }

    my $formula = $self->getAttr(name => 'aggregate_combination_formula');

    #Split aggregate_rule id from $formula
    my @array = split(/(id\d+)/,$formula);
    #replace each rule id by its evaluation
    for my $element (@array) {
        if( $element =~ m/id\d+/)
        {
            $element = $args{substr($element,2)};
            if (!defined $element){
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

sub dependantClusterMetricIds() {
    my $self = shift;
    my $formula = $self->getAttr(name => 'aggregate_combination_formula');

    my @clusterMetricsList;

    #Split aggregate_rule id from $formula
    my @array = split(/(id\d+)/,$formula);

    #replace each rule id by its evaluation
    for my $element (@array) {
        if( $element =~ m/id\d+/)
        {
            push @clusterMetricsList, substr($element,2);
        }
     }
     return @clusterMetricsList;
}

# Remove duplicate from an array, return array without doublons
sub uniq {
    return keys %{{ map { $_ => 1 } @_ }};
}

sub computeFromArrays{
    my $self = shift;
    my %args = @_;

    my @requiredArgs = $self->dependantClusterMetricIds();

    General::checkParams args => \%args, required => \@requiredArgs;

    #Merge all the timestamps keys in one arrays

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

sub useClusterMetric {
    my $self = shift;
    my $clustermetric_id = shift;

    my @dep_cm = $self->dependantClusterMetricIds();
    my $rep = any {$_ eq $clustermetric_id} @dep_cm;
    return $rep;
}

=head2 getUnit

    desc: Return the formula of the combination in which the indicator id is
          replaced by its Unit or by '?' when unit is not specified in database

=cut

sub getUnit {
    my ($self, %args) = @_;

    my $formula             = $self->getAttr(name => 'aggregate_combination_formula');

    #Split aggregate_rule id from $formula
    my @array = split(/(id\d+)/,$formula);
    #replace each rule id by its evaluation
    my $ref_element;
    my $are_same_units = 0;
    for my $element (@array) {
        if( $element =~ m/id\d+/)
        {
            $element = Clustermetric->get('id'=>substr($element,2))->getUnit();

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

sub getDependencies {
    my $self = shift;
    my @conditions = $self->aggregate_conditions;
    my %dependencies;

    for my $condition (@conditions) {
        $dependencies{$condition->aggregate_condition_label} = $condition->getDependencies;
    }
    return \%dependencies;
}

sub delete {
    my $self = shift;
    my @conditions = $self->aggregate_conditions;

    while (@conditions) {
        (pop @conditions)->delete();
    }
    return $self->SUPER::delete();
}
1;
