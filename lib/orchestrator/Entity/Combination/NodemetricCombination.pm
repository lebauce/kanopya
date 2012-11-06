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

Nodemetric Combination. Represented by a mathematic combination formula if indicator ids.

@since    2012-Feb-01
@instance hash
@self     $self

=end classdoc

=cut

package Entity::Combination::NodemetricCombination;

use strict;
use warnings;
require 'Entity/Indicator.pm';
use Entity::CollectorIndicator;
use base 'Entity::Combination';
use Data::Dumper;
# logger
use Log::Log4perl "get_logger";
my $log = get_logger("");

use constant ATTR_DEF => {
    formula_label => {
        is_virtual      => 1,
    },
    nodemetric_combination_label     =>  {pattern       => '^.*$',
                                 is_mandatory   => 0,
                                 is_extended    => 0,
                                 is_editable    => 1},
    nodemetric_combination_formula =>  {pattern       => '^((id\d+)|[ .+*()-/]|\d)+$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 1,
                                 description    => "Construct a formula by indicator's names with all mathematical operators. It's possible to use parenthesis with spaces between each element of the formula."},
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
        'getUnit'   => {
            'description' => 'getUnit',
            'perm_holder' => 'entity',
        },
        'getDependencies' => {
            'description' => 'return dependencies tree for this object',
            'perm_holder' => 'entity',
        },
    }
}

=pod

=begin classdoc

Virtual attribute getter

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
Launch indicator collection in order to create RRD.

@return a class instance

=end classdoc

=cut

sub new {
    my $class = shift;
    my %args = @_;
    my $self = $class->SUPER::new(%args);

    if(!defined $args{nodemetric_combination_label} || $args{nodemetric_combination_label} eq ''){
        $self->setAttr(name=>'nodemetric_combination_label', value => $self->toString());
        $self->save();
    }

    # Ask the collector manager to collect the related indicator
    my $service_provider = $self->service_provider;
    my $collector = $service_provider->getManager(manager_type => "collector_manager");

    my %ids = map { $_ => undef } ($self->nodemetric_combination_formula =~ m/id(\d+)/g);
    for my $indicator_id (keys %ids) {
        $collector->collectIndicator(indicator_id        => $indicator_id,
                                     service_provider_id => $service_provider->id);
    }

    return $self;
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

    if($depth == 0) {
        return $self->nodemetric_combination_label;
    }

    #Split nodemetric_rule id from $formula
    my @array = split(/(id\d+)/, $self->nodemetric_combination_formula);
    #replace each rule id by its evaluation
    for my $element (@array) {
        if( $element =~ m/id\d+/)
        {
            #Remove "id" from the begining of $element, get the corresponding aggregator and get the lastValueFromDB
            $element = Entity::CollectorIndicator->get(id => substr($element,2))->indicator->toString();
        }
    }
    return join('',@array);
    
}

=pod

=begin classdoc

Return an array of the CollectorIndicator ids of the formula

@return an array of the CollectorIndicator ids of the formula

=end classdoc

=cut

sub getDependantCollectorIndicatorIds{
    my $self = shift;
    my %ids = map { $_ => undef } ($self->nodemetric_combination_formula =~ m/id(\d+)/g);
    return keys %ids;
}


=pod

=begin classdoc

Return an array of the Indicator ids of the formula

@return an array of the CollectorIndicator ids of the formula

=end classdoc

=cut

sub getDependantIndicatorIds{
    my $self = shift;

    my @indicator_ids;

    #Split nodemetric_rule id from $formula
    my @array = split(/(id\d+)/,$self->nodemetric_combination_formula);

    #replace each rule id by its evaluation
    for my $element (@array) {
        if( $element =~ m/id\d+/)
        {
            my $collector_indicator_id = substr($element,2);
            push @indicator_ids, Entity::CollectorIndicator->get(id => $collector_indicator_id)->indicator_id;
        }
     }
     return @indicator_ids;
}


=pod

=begin classdoc

Compute the combination value with the formula from given Indicator values

@return the computed value

=end classdoc

=cut

sub computeValueFromMonitoredValues {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => [ 'monitored_values_for_one_node' ]);
    my $monitored_values_for_one_node = $args{monitored_values_for_one_node};

    #Split aggregate_rule id from $formula
    my @array = split(/(id\d+)/,$self->nodemetric_combination_formula);

    #replace each rule id by its evaluation
    for my $element (@array) {
        if( $element =~ m/id\d+/)
        {
            #Remove "id" from the begining of $element, get the corresponding aggregator and get the lastValueFromDB
            my $indicator_id  = substr($element,2);
            my $indicator_oid = Entity::CollectorIndicator->get(id => $indicator_id)->indicator->indicator_oid;
            # Replace $element by its value
            $element          = $monitored_values_for_one_node->{$indicator_oid};

            if(not defined $element){
                return undef;
            }
        }
     }

    my $res = -1;
    my $arrayString = '$res = '."@array";

    #Evaluate the logic formula
    eval $arrayString;

    $log->info("NM Combination value = $arrayString");
    return $res;
}


=pod

=begin classdoc

Return the formula of the combination in which the indicator id is
replaced by its Unit or by '?' when unit is not specified in database

@return the formula of the combination

=end classdoc

=cut

sub getUnit {
    my $self = shift;

    #Split nodemtric_rule id from $formula
    my @array = split(/(id\d+)/,$self->nodemetric_combination_formula);
    #replace each rule id by its evaluation
    my $ref_element;
    my $are_same_units = 0;
    for my $element (@array) {
        if( $element =~ m/id\d+/)
        {
            $element = Entity::CollectorIndicator->get(id => substr($element,2))->indicator->indicator_unit || '?';
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
    return join('',@array);
}

1;
