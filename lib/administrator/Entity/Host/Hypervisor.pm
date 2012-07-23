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

package Entity::Host::Hypervisor;
use base "Entity::Host";

use strict;
use warnings;

use Entity::Host::VirtualMachine;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("administrator");
my $errmsg;

use constant ATTR_DEF => {};

sub getAttrDef { return ATTR_DEF; }

sub methods {
    return {
        getVms => {
            description => 'get all vms from an hypervisor',
            perm_holder => 'entity'
        }
    };
}

=head2 getVms

=cut

sub getVms {
    my $self = shift;
    my %args = @_;

    my @vms = Entity::Host::VirtualMachine->search(hash => { hypervisor_id => $self->id });

    return wantarray ? @vms : \@vms;
}

1;
