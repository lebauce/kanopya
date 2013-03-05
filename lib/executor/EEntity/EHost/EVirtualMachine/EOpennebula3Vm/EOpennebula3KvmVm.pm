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
    (EEntity->new(data => $hypervisor))->updatePinning(
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

sub getRamUsedByVm {
    my ($self,%args) = @_;
    my $e_hypervisor = EEntity->new(data => $self->hypervisor);

    #this command get the pid of the kvm process then get the RAM used and SWAP used by this process
    my $cmd = 'cat /proc/$(cat /var/run/libvirt/qemu/one-'.($self->onevm_id).'.pid)/status | grep "VmRSS\|VmSwap"';

    my $stdout = $e_hypervisor->getEContext->execute(command => "$cmd")->{stdout};

    my @lines = split('\n',$stdout);

    my $mem;
    for my $line (@lines) {
        my @line_split = split('\s+',$line);
        $mem->{$line_split[0]} =  $line_split[1] * 1024; #Value given in kB, converted in bytes

      }
    return {
        mem_ram  => $mem->{'VmRSS:'},
        mem_swap => $mem->{'VmSwap:'},
        total    => $mem->{'VmRSS:'} + $mem->{'VmSwap:'},
    }
}

1;
