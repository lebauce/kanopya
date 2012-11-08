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
        is_editable     => 0
    },
    service_provider_id =>  {
        pattern         => '^.*$',
        is_mandatory    => 1,
        is_extended     => 0,
        is_editable     => 1
    },
};

sub getAttrDef { return ATTR_DEF; }


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


=pod

=begin classdoc

Get the list of conditions which depends on the combinations and all the combinations dependencies.

@return the list of conditions which depends on the combination and all the combinations dependencies.

=end classdoc

=cut

sub getDependencies {
    my $self = shift;

    my @conditions = (
        $self->aggregate_condition_left_combinations,
        $self->aggregate_condition_right_combinations,
        $self->nodemetric_condition_left_combinations,
        $self->nodemetric_condition_right_combinations,
    );

    my %dependencies;
    for my $condition (@conditions) {
        $dependencies{$condition->nodemetric_condition_label} = $condition->getDependencies;
    }
    return \%dependencies;
}


=pod

=begin classdoc

Abstract class implemented in ConstantCombination. Used when deleting a condition which has created
a ConstantCombination. Also used to avoid deep recursion.

=end classdoc

=cut

sub deleteIfConstant {};
1;
