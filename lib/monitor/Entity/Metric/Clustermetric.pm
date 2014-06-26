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

Aggregation of a collector indicator value for each node of the service, according to a statistic function

@see <package>Entity::CollectorIndicator</package>

=end classdoc

=cut

package Entity::Metric::Clustermetric;
use base 'Entity::Metric';

use strict;
use warnings;

use General;
use Entity::CollectorIndicator;
use Entity::Metric::Clustermetric;
use Entity::Metric::Nodemetric;
use Entity::Metric::Combination::AggregateCombination;

use DescriptiveStatisticsFunction;
use TryCatch;

use Data::Dumper;
use Log::Log4perl "get_logger";
my $log = get_logger("");

use constant ATTR_DEF => {
    clustermetric_service_provider_id => {
        pattern         => '^.*$',
        is_mandatory    => 1,
        is_editable     => 0,
    },
    clustermetric_label => {
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_editable     => 1
    },
    clustermetric_formula_string => {
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_editable     => 1,
    },
    clustermetric_unit => {
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_editable     => 1,
    },
    clustermetric_indicator_id => {
        pattern         => '^.*$',
        is_mandatory    => 1,
        is_editable     => 0
    },
    clustermetric_statistics_function_name => {
        pattern         => '^(mean|variance|std|max|min|kurtosis|skewness|dataOut|sum|count)$',
        is_mandatory    => 1,
        is_editable     => 0
    },
    clustermetric_window_time => {
        pattern         => '^.*$',
        is_mandatory    => 1,
        is_editable     => 0,
        default         => 1200,
    },
    indicator_label => {
        is_virtual      => 1,
    }
};

sub getAttrDef { return ATTR_DEF; }

sub methods {
    return {
        getDependencies => {
            description => 'return dependencies tree for this object',
        },
    }
}

sub _labelAttr {
    return 'clustermetric_formula_string';
}

=pod
=begin classdoc

@constructor

Create a new instance of the class. Create the RRD which will store the computed data.
Set the formula string, the unit and the label if not defined.

@return a class instance

=end classdoc
=cut

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new(%args, store => 'rrd');

    my $service_provider = $self->clustermetric_service_provider;
    my $collector = $service_provider->getManager(manager_type => "CollectorManager");
    $collector->collectIndicator(indicator_id        => $self->clustermetric_indicator_id,
                                 service_provider_id => $self->clustermetric_service_provider_id);

    my $toString = $self->toString();
    $self->setAttr(name=>'clustermetric_formula_string', value=>$toString);
    $self->setAttr(name=>'clustermetric_unit', value=>$self->computeUnit());
    if ((! defined $args{clustermetric_label}) || $args{clustermetric_label} eq '') {
        $self->setAttr(name=>'clustermetric_label', value=>$toString);
    }
    $self->save();

    # Create Nodemetrics for all existing nodes fo the service provider
    for my $node ($service_provider->nodes) {
        Entity::Metric::Nodemetric->findOrCreate(
            nodemetric_node_id      => $node->id,
            nodemetric_indicator_id => $self->clustermetric_indicator_id
        );
    }

    return $self;
}


=pod

=begin classdoc

Return related indicator label
@return Return related indicator label

=end classdoc

=cut

sub indicator_label {
    my $self = shift;
    return $self->getIndicator()->indicator_label;
}


=pod

=begin classdoc

Return related indicator
@return Return related indicator

=end classdoc

=cut

sub getIndicator {
    my $self = shift;
    return $self->clustermetric_indicator->indicator;
}


=pod

=begin classdoc

Aggregate values according to the related function of the clustermetric

@param all the values to aggregate
@return computed value

=end classdoc

=cut

sub compute {
    my ($self, %args) = @_;
    General::checkParams args => \%args, required => ['values'];

    #my $stat = Statistics::Descriptive::Full->new();
    my $stat = DescriptiveStatisticsFunction->new();
    $stat->add_data($args{values});

    my $funcname = $self->clustermetric_statistics_function_name;
    return $stat->$funcname();
}


=pod

=begin classdoc

Compute a readable string of the formula.

@return the string representation of the entity

=end classdoc

=cut

sub toString {
    my $self = shift;
    return $self->clustermetric_statistics_function_name .
           '(' . $self->getIndicator()->toString() . ')';
}


=pod

=begin classdoc

@deprecated

Return the unit attribute. Method used to ensure backward compatibility.
Preferable to get directly the attribute.

@return clustermetric_unit attribute

=end classdoc

=cut

sub getUnit {
    my $self = shift;
    return $self->clustermetric_unit;
}


=pod

=begin classdoc

Compute a readable string of the unit.

@return computed unit of the clustermetric

=end classdoc

=cut

sub computeUnit {
    my $self = shift;

    my $stat_func = $self->clustermetric_statistics_function_name;
    my $keep_unit = grep { $_ eq $stat_func } qw(mean variance std max min sum);
    if (!$keep_unit) {
        return '-';
    }

    return  $self->getIndicator()->indicator_unit || '?';
}


=pod

=begin classdoc

Compute the aggregate combinations instances which depend on the clustermetric instance.

@return Array of dependent aggregate combinations.

=end classdoc

=cut

sub getDependentCombinations {
    my $self = shift;

    my @combs = Entity::Metric::Combination::AggregateCombination->search(hash => {
                    service_provider_id => $self->clustermetric_service_provider_id
                });

    my $id = $self->id;

    my @combinations =();
    LOOP:
    for my $aggregate_combination (@combs) {
        my @metric_ids = $aggregate_combination->dependentMetricIds;

        for my $metric_id (@metric_ids) {
            if ($id == $metric_id) {
                push @combinations, $aggregate_combination;
                next LOOP;
            }
        }
    }

    return @combinations;
}


=pod

=begin classdoc

Compute a hierarchical tree of the names of the objects which depend on the clustermetric instance.

@return hash reference of the tree.

=end classdoc

=cut

sub getDependencies {
    my $self = shift;
    my @combinations = $self->getDependentCombinations;

    my %dependencies;
    for my $combination (@combinations) {
        $dependencies{$combination->aggregate_combination_label} = $combination->getDependencies;
    }
    return \%dependencies;
}

=pod

=begin classdoc

Clones the cluster metric and links clone to the specified service provider.
Only clone object if do not exists in service provider.
Source and dest linked service providers must have the same collector manager.

throw Kanopya::Exception::Internal::NotFound if dest service provider does not have a collector manager
throw Kanopya::Exception::Internal::Inconsistency if both services haven't the same collector manager

@param dest_service_provider_id id of the service provider where to import the clone

=end classdoc

=cut

sub clone {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => ['dest_service_provider_id']);

    # Check that both services use the same collector manager
    my $src_collector_manager = ServiceProviderManager->find(
                                    hash   => { service_provider_id => $self->clustermetric_service_provider_id },
                                    custom => { category => 'CollectorManager' }
                                );

    my $dest_collector_manager = ServiceProviderManager->find(
                                     hash => { service_provider_id => $args{dest_service_provider_id} },
                                     custom => { category => 'CollectorManager' }
                                 );

    if ($src_collector_manager->manager_id != $dest_collector_manager->manager_id) {
        throw Kanopya::Exception::Internal::Inconsistency(
            error => "Source and dest service provider have not the same collector manager"
        );
    }

    return $self->_importToRelated(
        dest_obj_id         => $args{dest_service_provider_id},
        relationship        => 'clustermetric_service_provider',
        label_attr_name     => 'clustermetric_label',
    );
}

=pod

=begin classdoc

Delete the instance, the RRD and all the instances which depend on it.

=end classdoc

=cut

sub delete {
    my $self = shift;

    my @aggregate_combinations = Entity::Metric::Combination::AggregateCombination->search(hash => {
                                     service_provider_id => $self->clustermetric_service_provider_id
                                 });

    my $id = $self->id;

    COMBI:
    while (@aggregate_combinations) {
        my $aggregate_combination = pop @aggregate_combinations;
        my @metric_ids = $aggregate_combination->dependentMetricIds();

        for my $metric_id (@metric_ids) {
            if ($id == $metric_id) {
                $aggregate_combination->delete();
                next COMBI;
            }
        }
    }
    return $self->SUPER::delete();
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

    $self->SUPER::update (%args);
    $self->setAttr(name => 'clustermetric_formula_string', value => $self->toString());
    $self->setAttr(name => 'clustermetric_unit', value => $self->computeUnit());
    $self->save();

    my @combinations = $self->getDependentCombinations;
    map { $_->updateFormulaString ; $_->updateUnit } @combinations;
    return $self;
}

1;
