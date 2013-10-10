# Copyright © 2012 Hedera Technology SAS
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

package EEntity::EHost::EHypervisor::EOpennebula3Hypervisor;
use base "EEntity::EHost::EHypervisor";

use strict;
use warnings;

use CapacityManagement;
use Entity::Workflow;

use Data::Dumper;
use Log::Log4perl "get_logger";

my $log = get_logger("");


sub checkStoppable {
    my $self = shift;

    my @vms = $self->getVms();

    if (scalar @vms) {
        $log->info('Some vms needs to be migrated before stopping this hypervisor');
        return 0;
    }
    else {
        $log->info('hypervisor is empty stop authorized');
        return 1;
    }
}

sub getMaxRamFreeVm {
    my ($self, %args) = @_;
    General::checkParams(
        args     => \%args,
        required => [ 'cluster' ]
    );
}

1;
