# Copyright © 2011-2013 Hedera Technology SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

=pod
=begin classdoc

TODO

=end classdoc 
=cut

package ClassType::ComponentType;
use base ClassType;

use strict;
use warnings;

use constant ATTR_DEF => {
    component_name => {
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 0
    },
    component_version => {
        pattern      => '^\d*$',
        is_mandatory => 0,
        is_editable  => 0
    },
    deployable => {
        pattern      => '^\d*$',
        is_mandatory => 0,
        is_editable  => 0,
        default      => 1
    },
    component_type_categories => {
        type         => 'relation',
        relation     => 'multi',
        link_to      => 'component_category',
        is_mandatory => 0,
        is_editable  => 1,
    },
    service_provider_type_component_types => {
        type         => 'relation',
        relation     => 'multi',
        link_to      => 'service_provider_type',
        is_mandatory => 0,
        is_editable  => 1,
    },
};

sub getAttrDef { return ATTR_DEF; }


=pod
=begin classdoc

Overrride the BaseDB search to make easier the search of ComponentType
in function of ComponentCategory.

@return the search result

=end classdoc
=cut

sub search {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, optional => { 'hash' => {} });

    if (defined $args{custom}) {
        if (defined $args{custom}->{category}) {
            # TODO: try to use the many-to-mnay relation name 'component_categories.category_name'
            my $categoryfilter = 'component_type_categories.component_category.category_name';
            $args{hash}->{$categoryfilter} = delete $args{custom}->{category};
        }
        delete $args{custom};
    }

    return $class->SUPER::search(%args);
}

=pod
=begin classdoc

For component types, delegate the permissons to the Component master group.

@return the delegatee entity.

=end classdoc
=cut

sub _delegatee {
    my $self = shift;
    my $class = "Entity::Component";

    return $class->_delegatee;
}

1;
