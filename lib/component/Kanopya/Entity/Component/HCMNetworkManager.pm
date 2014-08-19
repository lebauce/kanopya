 # Copyright © 2014 Hedera Technology SAS
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

HCM native network manager.
Configure the nodes network insterface using the HCM lib based on
ifaces, interfaces, netconfs, poolip and networks.

=end classdoc
=cut

package Entity::Component::HCMNetworkManager;
use parent Entity::Component;
use parent Manager::NetworkManager;

use strict;
use warnings;

use TryCatch;
use Hash::Merge;
use Date::Simple (':all');
use Log::Log4perl "get_logger";

my $log = get_logger("");

use constant ATTR_DEF => {
    executor_component_id => {
        label        => 'Workflow manager',
        type         => 'relation',
        relation     => 'single',
        pattern      => '^[0-9\.]*$',
        is_mandatory => 0,
        is_editable  => 0,
    },
};

sub getAttrDef { return ATTR_DEF; }


my $merge = Hash::Merge->new();


=pod
=begin classdoc

Not supported.

@see <package>Manager::NetworkManager</package>

=end classdoc
=cut

sub ApplyVLAN {
    my ($self, %args) = @_;

    $log->warn("ApplyVLAN not supported by network manager " . $self->label);
}

1;
