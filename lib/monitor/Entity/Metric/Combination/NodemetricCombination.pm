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

Mathematical formula of collector indicators

@see <package>Entity::CollectorIndicator</package>
@see <package>Entity::NodemetricCondition</package>

=end classdoc

=cut

package Entity::Metric::Combination::NodemetricCombination;
use base Entity::Metric::Combination;

use strict;
use warnings;

use Entity::CollectorIndicator;
use Data::Dumper;

use Log::Log4perl "get_logger";
my $log = get_logger("");

use constant ATTR_DEF => {
    nodemetric_combination_label => {
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_extended     => 0,
        is_editable     => 1,
    },
    nodemetric_combination_formula => {
        pattern         => '^((id\d+)|[ .+*()-/]|\d)+$',
        is_mandatory    => 1,
        is_extended     => 0,
        is_editable     => 1,
        description     => "Construct a formula by indicator's names with all mathematical operators.
                            It's possible to use parenthesis with spaces between each element
                            of the formula.",
    },
    nodemetric_combination_formula_string => {
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_extended     => 0,
        is_editable     => 1,
    },
    formula_label => {
        is_virtual      => 1,
    },
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
        getUnit   => {
            description => 'getUnit',
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
    return $self->nodemetric_combination_label;
}

=pod

=begin classdoc

Formula label virtual attribute getter

=end classdoc

=cut

sub formula_label {
    my $self = shift;
    return $self->nodemetric_combination_formula_string;
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

    # Clone case
    if ($args{nodemetric_combination_id}) {
        return $class->get( id => $args{nodemetric_combination_id})->clone(
            dest_service_provider_id => $args{service_provider_id}
        );
    }

    my $self = $class->SUPER::new(%args);

    my $toString = $self->toString();
    if(!defined $args{nodemetric_combination_label} || $args{nodemetric_combination_label} eq ''){
        $self->setAttr(name=>'nodemetric_combination_label', value => $toString);
    }
    $self->setAttr (name=>'nodemetric_combination_formula_string', value => $toString);
    $self->setAttr (name=>'combination_unit', value => $self->computeUnit());
    $self->save ();


    # Ask the collector manager to collect the related indicator
    my $service_provider = $self->service_provider;
    my $collector = $service_provider->getManager(manager_type => "CollectorManager");

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
    my $self = shift;

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

sub getDependentCollectorIndicatorIds{
    my $self = shift;
    my %ids = map { $_ => undef } ($self->nodemetric_combination_formula =~ m/id(\d+)/g);
    return keys %ids;
}


=pod

=begin classdoc

Return an array of the Indicator ids of the formula

@return an array of the Indicator ids of the formula

=end classdoc

=cut

sub getDependentIndicatorIds{
    my $self = shift;

    my @indicator_ids;

    #Split nodemetric_rule id from $formula
    my @array = split(/(id\d+)/,$self->nodemetric_combination_formula);

    #replace each rule id by its evaluation
    for my $element (@array) {
        if ($element =~ m/id\d+/) {
            my $collector_indicator_id = substr($element,2);
            push @indicator_ids, Entity::CollectorIndicator->get(id => $collector_indicator_id)->indicator_id;
        }
     }
     return @indicator_ids;
}

=pod

=begin classdoc

Evaluate last value of the NodemetricCombination

@return value combination value

=end

=cut

sub evaluate {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => ['node']);

    if (exists $args{memoization}->{$self->id}->{$args{node}->id}) {
        return $args{memoization}->{$self->id}->{$args{node}->id};
    }

    my @col_ind_ids = ($self->nodemetric_combination_formula =~ m/id(\d+)/g);

    my %values;
    for my $ci_id (@col_ind_ids) {
        my $collector_indicator = Entity::CollectorIndicator->get(id => $ci_id);
        $values{$ci_id} = $collector_indicator->lastValue(nodes => [$args{node}], %args)->{$args{node}->id};
        if (! defined $values{$ci_id}) {
            if (defined $args{memoization}) {
                $args{memoization}->{$self->id}->{$args{node}->id} = undef;
            }
            return undef;
        }

    }

    my $value = $self->SUPER::computeFormula(formula => $self->nodemetric_combination_formula,
                                             values => \%values);

    if (defined $args{memoization}) {
        $args{memoization}->{$self->id}->{$args{node}->id} = $value;
    }

    return $value;
}


=pod

=begin classdoc

Compute the combination value between two dates for each nodes. Use fetch() method of CollectorIndicator.

@param start_time the begining date
@param stop_time the ending date
@optional nodes Array ref of nodes to compute. Default is all enabled nodes.
@optional node_ids Array ref of nodes id to compute. Used if 'nodes' is undef. Default is all enabled nodes.

@return the computed value

=end classdoc

=cut

sub evaluateTimeSerie {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => ['start_time','end_time'],
                         optional => {nodes => undef, node_ids => undef});

    # If @nodes not provided, get from ids if provided else get all non-disabled nodes of the service provider
    my @nodes = (defined $args{nodes}) ? @{$args{nodes}}
              : $self->service_provider->searchRelated(
                    filters => ['nodes'],
                    hash    => (defined $args{node_ids}) ? {node_id => $args{node_ids}}
                             : {-not => {monitoring_state => 'disabled'}}
                );
    $args{nodes} = \@nodes;

    my @ci_ids = $self->getDependentCollectorIndicatorIds();
    my %allTheCIValues;
    foreach my $ci_id (@ci_ids){
        my $ci = Entity::CollectorIndicator->get('id' => $ci_id);
        $allTheCIValues{$ci_id} = $ci->fetch(%args);
    }

    return $self->_computeFromArrays(%allTheCIValues);
}


=pod

=begin classdoc

Compute the combination value using a hash of timestamped values for each CollectorIndicator and nodes.


@param dynamic A value for each collectorIndicator of the formula, for each nodes.
               (ci_id => {node_id => {timestamp=>value}})

@return A reference to computed values. {node_id => {timestamp=>value}}

=end classdoc

=cut

sub _computeFromArrays {
    my ($self, %args) = @_;
    my @requiredArgs = $self->getDependentCollectorIndicatorIds();

    General::checkParams(args => \%args, required => \@requiredArgs);

    # Merge all the timestamps keys in one arrays. Do the Same for node ids.
    my @timestamps;
    my @node_ids;
    foreach my $ci_id (@requiredArgs){
        while (my ($node_id, $data) = each %{$args{$ci_id}}){
            @timestamps = (@timestamps, (keys %$data));
            push @node_ids, $node_id;
        }
    }
    @timestamps = $self->uniq(data => \@timestamps);
    @node_ids   = $self->uniq(data => \@node_ids);

    my %rep;
    foreach my $timestamp (@timestamps){
        foreach my $node_id (@node_ids) {
            my %valuesForATimeStamp;
            foreach my $ci_id (@requiredArgs){
                $valuesForATimeStamp{$ci_id} = $args{$ci_id}->{$node_id} ? $args{$ci_id}->{$node_id}{$timestamp}
                                                                         : undef;
            }
            $rep{$node_id}{$timestamp} = $self->SUPER::computeFormula(
                                            formula => $self->nodemetric_combination_formula,
                                            values => \%valuesForATimeStamp
                                         );
        }
    }

    return \%rep;
}

=pod

=begin classdoc

Compute the formula of the combination in which the indicator id is
replaced by its Unit or by '?' when unit is not specified in database

=end classdoc

=cut

sub computeUnit {
    my $self = shift;

    #Split nodemtric_rule id from $formula
    my @array = split(/(id\d+)/,$self->nodemetric_combination_formula);
    #replace each rule id by its evaluation
    my $ref_element;
    my $are_same_units = 0;
    for my $element (@array) {
        if ($element =~ m/id\d+/) {
            $element = Entity::CollectorIndicator->get(id => substr($element,2))->indicator->indicator_unit || '?';

            if (not defined $ref_element) {
                $ref_element = $element;
            } else {
                $are_same_units = ($ref_element eq $element) ? 1 : 0;
            }
        }
    }
    if ($are_same_units == 1) {
        @array = $ref_element;
    }
    return join('',@array);
}

sub combination_formula_string {
    my $self = shift;
    return $self->nodemetric_combination_formula_string
}


=pod

=begin classdoc

Compute and update the formula_string attribute and call the update of the formula_string attribute
 of objects which depend on the instance.

=end classdoc

=cut

sub updateFormulaString {
    my $self = shift;
    $self->setAttr(name => 'nodemetric_combination_formula_string', value => $self->toString());
    $self->save();
    my @conditions = $self->getDependentConditions;
    return map { $_->updateFormulaString } @conditions;
}

=pod

=begin classdoc

Redefine update() in order to update the formula string and unit of instance which depend on the
updated instance.

@return updated instance.

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

Clones the combination and links clone to the specified service provider.
Only clone object if do not exists in service provider.
Source and dest linked service providers must have the same collector manager.

throw Kanopya::Exception::Internal::NotFound if dest service provider does not have a collector manager
throw Kanopya::Exception::Internal::Inconsistency if both services haven't the same collector manager

@param dest_service_provider_id id of the service provider where to import the clone

@return clone object

=end classdoc

=cut

sub clone {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => ['dest_service_provider_id']);

    # Check that both services use the same collector manager
    my $src_collector_manager = ServiceProviderManager->find(
                                    hash   => { service_provider_id => $self->service_provider_id },
                                    custom => { category => 'CollectorManager' }
                                );

    my $dest_collector_manager = ServiceProviderManager->find(
                                     hash   => { service_provider_id => $args{'dest_service_provider_id'} },
                                     custom => { category => 'CollectorManager' }
                                 );

    if ($src_collector_manager->manager_id != $dest_collector_manager->manager_id) {
        throw Kanopya::Exception::Internal::Inconsistency(
            error => "Source and dest service provider have not the same collector manager"
        );
    }

    return $self->_importToRelated(
        dest_obj_id         => $args{'dest_service_provider_id'},
        relationship        => 'service_provider',
        label_attr_name     => 'nodemetric_combination_label',
    );
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
}

1;
