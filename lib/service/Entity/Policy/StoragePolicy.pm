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

The storage policy defines the parameters describing how
a service provider create/remove disks, export disk as root
filesystem to it's hosts.

@since    2012-Aug-16
@instance hash
@self     $self

=end classdoc

=cut

package Entity::Policy::StoragePolicy;
use base 'Entity::Policy';

use strict;
use warnings;

use Entity::Component;

use Data::Dumper;
use Log::Log4perl 'get_logger';

use Clone qw(clone);

my $log = get_logger("");

use constant ATTR_DEF => {};

sub getAttrDef { return ATTR_DEF; }

use constant POLICY_ATTR_DEF => {
    storage_manager_id => {
        label        => "Storage type",
        type         => 'relation',
        relation     => 'single',
        pattern      => '^\d*$',
        reload       => 1,
        is_mandatory => 1,
        order        => 1,
    },
};

use constant POLICY_SELECTOR_ATTR_DEF => {};

use constant POLICY_SELECTOR_MAP => {};

sub getPolicyAttrDef { return POLICY_ATTR_DEF; }
sub getPolicySelectorAttrDef { return POLICY_SELECTOR_ATTR_DEF; }
sub getPolicySelectorMap { return POLICY_SELECTOR_MAP; }

my $merge = Hash::Merge->new('LEFT_PRECEDENT');

1;
