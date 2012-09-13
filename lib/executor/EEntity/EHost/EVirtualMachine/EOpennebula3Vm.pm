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

package EEntity::EHost::EVirtualMachine::EOpennebula3Vm;
use base "EEntity::EHost::EVirtualMachine";

use strict;
use warnings;

use Log::Log4perl "get_logger";

my $log = get_logger("");

sub timeOuted {
    my $self = shift;

    $self->{host_manager}->forceDeploy(vm => $self, hypervisor => $self->hypervisor);
}

=head2 checkUp

    Desc: check the state of the vm
    Return: error if vm state is 'fail'

=cut

sub checkUp {
    my $self = shift;

    my $vm_state = $self->{host_manager}->getVMState(host => $self);

    $log->info('Vm <'.$self->{host}->getId().'> opennebula status <'.($vm_state->{state}).'>');

    if ($vm_state->{state} eq 'runn') {
        $log->info('VM running try to contact it');
    }
    elsif ($vm_state->{state} eq 'boot') {
        $log->info('VM still booting');
        return 0;
    }
    elsif ($vm_state->{state} eq 'fail' ) {
        my $lastmessage = $self->{host_manager}->vmLoggedErrorMessage(opennebula3_vm => $self->{host});
        throw Kanopya::Exception(error => 'Vm fail on boot: '.$lastmessage);
    }
    elsif ($vm_state->{state} eq 'pend' ) { 
        $log->info('timeout in '.($broken_time - $starting_time).' s');
        $log->info('VM still pending'); #TODO check HV state
        return 0;
    }

    return $self->SUPER::checkUp();
}
1;
