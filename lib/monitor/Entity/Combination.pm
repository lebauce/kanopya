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

package Entity::Combination;

use strict;
use warnings;
use base 'Entity';
use Data::Dumper;
# logger
use Log::Log4perl "get_logger";
my $log = get_logger("");

use constant ATTR_DEF => {
    combination_id      =>  {
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_extended     => 0,
        is_editable     => 0,
    },
    service_provider_id => {
        pattern         => '^.*$',
        is_mandatory    => 1,
        is_extended     => 0,
        is_editable     => 1,
    },
    combination_unit => {
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_extended     => 0,
        is_editable     => 1,
    },
    combination_formula_string => {
        is_virtual      => 1,
    }
};

sub getAttrDef { return ATTR_DEF; }

sub methods {
    return {
        computeDataModel => {
            description => 'Enqueue the select data model operation.',
            perm_holder => 'entity',
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

sub computeUnit {
}


=pod

=begin classdoc

Enqueue ESelectDataModel operation

@param start_time define the start time of historical data taken to configure
@param end_time define the end time of historical data taken to configure

@optional node_id modeled node in case of NodemetricCombination

=end classdoc

=cut

sub computeDataModel {
    my ($self, %args) = @_;
    General::checkParams(args     => \%args,
                         required => ['start_time', 'end_time'],
                         optional => { 'node_id' => undef });

    my $params = {context => {combination => $self},
                  start_time => $args{start_time},
                  end_time => $args{end_time},};

    if (defined $args{node_id}) {$params->{node_id} = $args{node_id}}

    $log->info('Enqueuing combination id='.$self->id);
    Entity::Operation->enqueue(
        priority => 200,
        type     => 'SelectDataModel',
        params   => $params
    );
}

1;
