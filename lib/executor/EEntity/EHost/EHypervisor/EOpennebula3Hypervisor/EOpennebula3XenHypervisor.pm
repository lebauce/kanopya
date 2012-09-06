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

package EEntity::EHost::EHypervisor::EOpennebula3Hypervisor::EOpennebula3XenHypervisor;;
use base "EEntity::EHost::EHypervisor::EOpennebula3Hypervisor";

use strict;
use warnings;

use General;
use Entity::Host::VirtualMachine::Opennebula3Vm;

use Hash::Merge qw(merge);

use Log::Log4perl "get_logger";
my $log = get_logger("");


my $resources_methods = {
    ram => \&getMemResources,
    cpu => \&getCpuResources,
};

=head2 getAvailableMemory

    Return the available memory amount.

=cut

sub getAvailableMemory {
    my ($self, %args) = @_;

    # Get the memory infos from xm infos
    my $result = $self->getEContext->execute(command => 'xm info');
    if ($result->{exitcode} != 0) {
        throw Kanopya::Exception::Execution(error => $result->{stdout});
    }

    # Total available memory is the sum of free, buffers and cached memory
    my @lines = split('\n', $result->{stdout});
    for my $line (@lines) {
        my ($key, $value) = split(':', $line);

        # Remove spaces before and after
        $key =~ s/\s+//;
        $value =~ s/\s+//;

        # Return the free memory in bytes
        if ($key eq 'free_memory') { return $value * 1024 * 1024 }
    }
}

=head2 getVmResources

    Return virtual machines resources. If no resssource type(s)
    specified in parameters, return all know ressouces.

=cut

sub getVmResources {
    my ($self, %args) = @_;

    General::checkParams(
        args     => \%args,
        optional => { vm => undef, resources => [ 'ram', 'cpu' ] }
    );

    # Call the corressponding method for all required resources,
    # and merge them into the result hash.
    my $vms_resources = {};
    for my $resource (@{ $args{resources} }) {
        merge($vms_resources, $resources_methods->{$resource}->(vm => $args{vm}));
    }
    return $vms_resources;
};

=head2 getMemResources

    Return specified virtual machine memory resources.
    If no vm specified in parameters, return all hosted vm
    memory resources.

=cut

sub getMemResources {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, optional => { vm => undef } );

    my $result = $self->getEContext->execute(command => 'xentop -b -i 1 ');
    if ($result->{exitcode} != 0) {
        throw Kanopya::Exception::Execution(error => $result->{stdout});
    }

    my @lines = split('\n', $result->{stdout});
    shift @lines; # Remove first line (titles)
    shift @lines; # Remove second line (Dom0)

    my %hash;
    for my $line (@lines) {
        $line =~ s/^\s+//;
        my @splited_line  = split('\s+', $line);
        my ($foo, $vm_id) = split '-', $splited_line[0];

        if (not defined $args{vm}) {
            my $one3vm = Entity::Host::VirtualMachine::Opennebula3Vm->find(hash => { onevm_id => $vm_id });
            $hash{$one3vm->id}->{ram} = $splited_line[4] * 1024;
        }
        elsif ($args{vm}->onevm_id == $vm_id) {
            $hash{$args{vm}->id}->{ram} = $splited_line[4] * 1024;
            last;
        }
    }
    return \%hash;
}

=head2 getCpuResources

    Return specified virtual machine cpu resources.
    If no vm specified in parameters, return all hosted vm
    cpu resources.

=cut

sub getCpuResources {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, optional => { vm => undef } );

    my $result = $args{hypervisor}->getEContext->execute(command => 'xm list');
    if ($result->{exitcode} != 0) {
        throw Kanopya::Exception::Execution(error => $result->{stdout});
    }

    my @lines = split('\n', $result->{stdout});
    shift @lines; # Remove first line (titles)
    shift @lines; # Remove second line (Dom0)

    my %hash;
    for my $line (@lines) {
        my @splited_line  = split('\s+', $line);
        my ($foo, $vm_id) = split '-', $splited_line[0];

        if (not defined $args{vm}) {
            my $one3vm = Entity::Host::VirtualMachine::Opennebula3Vm->find(hash => { onevm_id => $vm_id });
            $hash{$one3vm->id}->{cpu} = $splited_line[3];
        }
        elsif ($args{vm}->onevm_id == $vm_id) {
            $hash{$args{vm}->id}->{cpu} = $splited_line[3];
            last;
        }
    }
    return \%hash;
}

1;
