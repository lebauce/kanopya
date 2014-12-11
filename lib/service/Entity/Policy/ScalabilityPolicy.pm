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

=pod

=begin classdoc

The scalability policy defines the parameters describing how a service
manage it scalability.

@since    2012-Aug-16
@instance hash
@self     $self

=end classdoc

=cut

package Entity::Policy::ScalabilityPolicy;
use base 'Entity::Policy';

use strict;
use warnings;

use Data::Dumper;
use Log::Log4perl 'get_logger';

use Clone qw(clone);

my $log = get_logger("");

use constant ATTR_DEF => {};

sub getAttrDef { return ATTR_DEF; }

use constant POLICY_ATTR_DEF => {
    cluster_min_node => {
        label        => 'Minimum node number',
        type         => 'integer',
        pattern      => '^[1-9][0-9]*$',
        is_mandatory => 1,
        order        => 1,
        description  => 'It is the minimal size of your service instance. '.
                        'In most case it is 1 but if you want high availability set 2',
    },
    cluster_max_node => {
        label        => 'Maximum node number',
        type         => 'integer',
        pattern      => '^[1-9][0-9]*$',
        is_mandatory => 1,
        order        => 2,
        description  => 'It is maximum number of node in a service instance. '.
                        'If you want a simple vm set 1, a scalable one set >2',
    },
};

sub getPolicyAttrDef { return POLICY_ATTR_DEF; }

my $merge = Hash::Merge->new('RIGHT_PRECEDENT');

1;
