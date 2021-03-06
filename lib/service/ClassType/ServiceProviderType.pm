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

package ClassType::ServiceProviderType;
use base 'ClassType';

use strict;
use warnings;

use constant ATTR_DEF => {
    service_provider_name => {
        pattern         => '^.*$',
        is_mandatory    => 1,
        is_editable     => 0
    },
    service_provider_type_component_types => {
        type         => 'relation',
        relation     => 'multi',
        link_to      => 'component_type',
        is_mandatory => 0,
        is_editable  => 1,
    },
};

sub getAttrDef { return ATTR_DEF; }



=pod
=begin classdoc

For component types, delegate the permissons to the ServiceProvider master group.

@return the delegatee entity.

=end classdoc
=cut

sub _delegatee {
    my $self = shift;
    my $class = "Entity::ServiceProvider";

    return $class->_delegatee;
}

1;
