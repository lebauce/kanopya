# Copyright © 2011-2012 Hedera Technology SAS
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

package Entity::Policy::ScalabilityPolicy;
use base 'Entity::Policy';

use strict;
use warnings;

use Data::Dumper;
use Log::Log4perl 'get_logger';

my $log = get_logger("");

use constant ATTR_DEF => {};

sub getAttrDef { return ATTR_DEF; }


my $merge = Hash::Merge->new('RIGHT_PRECEDENT');

sub getPolicyDef {
    my $self  = shift;
    my $class = ref($self) || $self;
    my %args  = @_;

    General::checkParams(args => \%args, optional => { 'set_mandatory' => 0 });

    %args = %{ $self->mergeValues(values => \%args) };

    my $attributes = {
        displayed  => [ 'cluster_min_node', 'cluster_max_node', 'cluster_priority' ],
        attributes =>  {
            cluster_min_node => {
                label    => 'Minimum node number',
                type     => 'integer',
                pattern  => '^[1-9][0-9]*$',
            },
            cluster_max_node => {
                label    => 'Maximum node number',
                type     => 'integer',
                pattern  => '^[1-9][0-9]*$',
            },
            cluster_priority => {
                label    => 'Cluster priority',
                type     => 'integer',
                pattern  => '^[1-9][0-9]*$',
            },
        }
    };

    # Complete the attributes with common ones
    $attributes = $merge->merge($self->SUPER::getPolicyDef(%args), $attributes);

    $self->setValues(attributes => $attributes, values => \%args);
    return $attributes;
}

1;
