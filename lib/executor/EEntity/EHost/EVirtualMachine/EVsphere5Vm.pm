#    Copyright © 2011-2012 Hedera Technology SAS
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

# Maintained by Dev Team of Hedera <>Technology <dev@hederatech.com>.

package EEntity::EHost::EVirtualMachine::EVsphere5Vm;
use base "EEntity::EHost::EVirtualMachine";

use strict;
use warnings;

use Log::Log4perl "get_logger";

my $log = get_logger("executor");

=head2 checkUp

    Desc: return the state of the VM

=cut

sub checkUp {
    my $self = shift;

#    my $vm_state = $self->{host_manager}->getVMState(host => $self);

#    $log->info('Vm <'.$self->{host}->getId().'> vsphere status <'.($vm_state->{state}).'>');

    return 1;
    #return $self->SUPER::checkUp();
}

1;
