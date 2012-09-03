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

package EEntity::EHost::EVirtualMachine::EOpennebula3Vm::EOpennebula3KvmVm;
use base "EEntity::EHost::EVirtualMachine::EOpennebula3Vm";

use strict;
use warnings;

use Log::Log4perl "get_logger";

my $log = get_logger("executor");

=head2 updateCpus

=cut

sub updateCpus {
    my $self    = shift;
    my %args    = @_;

    General::checkParams(args => \%args, optional => { cpus => $self->host_core });

    my $i       = 0;
    my $cmd     = "";
    while ($i < $self->opennebula3_kvm_vm_cores) {
        if ($i < $args{cpus}) {
            $cmd  .= "echo 1 > /sys/devices/system/cpu/cpu$i/online ; ";
        }
        else {
            $cmd  .= "echo 0 > /sys/devices/system/cpu/cpu$i/online ; ";
        }
        ++$i;
    }
    $self->getEContext->execute(command => "$cmd");

    my $hypervisor = Entity->get(id => $self->hypervisor->id);
    (EFactory::newEEntity(data => $hypervisor))->updatePinning(
        vm      => $self,
        cpus    => $args{cpus}
    );
}

=head2

=cut

sub postStart {
    my $self = shift;
    my %args = @_;

    $self->updateCpus();

    return $self->SUPER::postStart(%args);
}

1;
