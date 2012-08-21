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

sub _onOffCpu {
    my $self    = shift;
    my %args    = @_;

    General::checkParams(args => \%args, required => [ 'cpu', 'online' ]);

    my $command = "echo $args{online} > /sys/devices/system/cpu/cpu$args{cpu}/online";

    $self->getEContext->execute(command => "$command");
}

=head2 unplugCpu

    Unplug a CPU by echoing 0 in his `online` file

=cut

sub unplugCpu {
    my $self    = shift;
    my %args    = @_;

    General::checkParams(args => \%args, required => [ 'cpu' ]);

    $self->_onOffCpu(cpu => $args{cpu}, online => 0);
}

=head2 plugCpu

    Plug a CPU by echoing 1 in his `online` file

=cut

sub plugCpu {
    my $self    = shift;
    my %args    = @_;

    General::checkParams(args => \%args, required => [ 'cpu' ]);

    $self->_onOffCpu(cpu => $args{cpu}, online => 1);
}

=hea2 updateCpus

=cut

sub updateCpus {
    my $self    = shift;

    my $i       = 0;
    while ($i < $self->opennebula3_kvm_vm_cores) {
        if ($i < $self->host_core) {
            $self->plugCpu(cpu => $i);
        }
        else {
            $self->unplugCpu(cpu => $i);
        }
        ++$i;
    }
}

1;
