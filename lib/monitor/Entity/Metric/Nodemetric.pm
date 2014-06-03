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

Make the relation from a node with the collector indicators.

@see <package>Entity::CollectorIndicator</package>

=end classdoc

=cut

package Entity::Metric::Nodemetric;
use base 'Entity::Metric';

use strict;
use warnings;

use General;
use Entity::CollectorIndicator;

use TryCatch;
use Data::Dumper;
use Log::Log4perl "get_logger";
my $log = get_logger("");


use constant ATTR_DEF => {
    nodemetric_node_id => {
        pattern         => '^.*$',
        is_mandatory    => 1,
        is_editable     => 0,
    },
    nodemetric_label => {
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_editable     => 1
    },
    nodemetric_indicator_id => {
        pattern         => '^.*$',
        is_mandatory    => 1,
        is_editable     => 0
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

# sub _labelAttr {
#     return 'nodemetric_label';
# }

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

    my $collector = $self->nodemetric_node->service_provider->getManager(manager_type => "CollectorManager");
    $collector->collectIndicator(indicator_id        => $self->nodemetric_indicator_id,
                                 service_provider_id => $self->nodemetric_node->service_provider->id);
    return $self;
}


=pod
=begin classdoc

@return the related indicator label

=end classdoc
=cut

sub indicatorLabel {
    my $self = shift;
    return $self->clustermetric_indicator->indicator->indicator_label;
}


# =pod

# =begin classdoc

# Compute the aggregate combinations instances which depend on the clustermetric instance.

# @return Array of dependent aggregate combinations.

# =end classdoc

# =cut

# sub getDependentCombinations {
#     my $self = shift;

#     my @combs = Entity::Metric::Combination::AggregateCombination->search(hash => {
#                     service_provider_id => $self->clustermetric_service_provider_id
#                 });

#     my $id = $self->id;

#     my @combinations =();
#     LOOP:
#     for my $aggregate_combination (@combs) {
#         my @metric_ids = $aggregate_combination->dependentMetricIds;

#         for my $metric_id (@metric_ids) {
#             if ($id == $metric_id) {
#                 push @combinations, $aggregate_combination;
#                 next LOOP;
#             }
#         }
#     }

#     return @combinations;
# }


# =pod

# =begin classdoc

# Compute a hierarchical tree of the names of the objects which depend on the clustermetric instance.

# @return hash reference of the tree.

# =end classdoc

# =cut

# sub getDependencies {
#     my $self = shift;
#     my @combinations = $self->getDependentCombinations;

#     my %dependencies;
#     for my $combination (@combinations) {
#         $dependencies{$combination->aggregate_combination_label} = $combination->getDependencies;
#     }
#     return \%dependencies;
# }


1;
