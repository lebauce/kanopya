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

Constant value used as combination

@see <package>Entity::CollectorIndicator</package>
@see <package>Entity::NodemetricCondition</package>
@see <package>Entity::AggregateCondition</package>

=end classdoc

=cut

package Entity::Combination::ConstantCombination;

use strict;
use warnings;
use base 'Entity::Combination';
use Entity::Indicator;
use Data::Dumper;
# logger
use Log::Log4perl "get_logger";
my $log = get_logger("");

use constant ATTR_DEF => {
    value => {
        pattern         => '^((id\d+)|[ .+*()-/]|\d)+$',
        is_mandatory    => 1,
        is_extended     => 0,
        is_editable     => 1,
    }
};

sub getAttrDef { return ATTR_DEF; }

sub getAttr {
    my $self = shift;
    my %args = @_;
    return $self->SUPER::getAttr(%args);
}

# Virtual attribute getter
sub label {
    my $self = shift;
    return $self->value;
}

sub combination_formula_string {
    my $self = shift;
    return $self->value
}

=pod

=begin classdoc

Return empty string. Use to be compatible with other Combination subclasses.

@return empty string.

=end classdoc

=cut

sub getDependentIndicatorIds {
    my $self = shift;
    return ();
}


=pod

=begin classdoc

Call delete(). Used when deleting a condition which has created
a ConstantCombination. Also used to avoid deep recursion.

=end classdoc

=cut

sub deleteIfConstant {
    my $self = shift;
    return $self->delete();
}


=pod

=begin classdoc

Return the value attribute.

@return value attribute.

=end classdoc

=cut

sub toString {
    my $self = shift;
    return $self->value;
};

=pod

=begin classdoc

Clones the combination.
Links clone to the specified service provider

@param dest_service_provider_id id of the service provider where to import the clone

=end classdoc

=cut

sub clone {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => ['dest_service_provider_id']);

    return $self->_importToRelated(
        dest_obj_id  => $args{dest_service_provider_id},
        relationship => 'service_provider',
    );
}

=pod

=begin classdoc

Return the value attribute.

=end classdoc

=cut

sub evaluate {
    my ($self, %args) = @_;

    if (defined $args{nodes}) {
        my %rep;
        for my $node (@{$args{nodes}}) { $rep{$node->id} = $self->value } ;
        return \%rep;
    }
    else {
        return $self->value;
    }
}
1;
