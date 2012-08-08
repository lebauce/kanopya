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

use Entity::Host::VirtualMachine::Opennebula3Vm;

use Hash::Merge qw(merge);

use Log::Log4perl "get_logger";
my $log = get_logger("executor");


my $ressources_methods = {
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

    Return virtual machines ressources. If no resssource type(s)
    specified in parameters, return all know ressouces.

=cut

sub getVmResources {
    my ($self, %args) = @_;

    General::checkParams(
        args     => \%args,
        optional => { vm => undef, ressources => [ 'ram', 'cpu' ] }
    );

    # Call the corressponding method for all required ressources,
    # and merge them into the result hash.
    my $vms_ressources = {};
    for my $ressource (@{ $args{ressources} }) {
        merge($vms_ressources, $ressources_methods->{$ressource}->(vm => $args{vm}));
    }
    return $vms_ressources;
};

=head2 getMemResources

    Return specified virtual machine memory ressources.
    If no vm specified in parameters, return all hosted vm
    memory ressources.

=cut

sub getMemResources {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, optional => { vm => undef } );

    my $result = $self->getEContext->execute(command => 'xentop -b -i 1 ');

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

    Return specified virtual machine cpu ressources.
    If no vm specified in parameters, return all hosted vm
    cpu ressources.

=cut

sub getCpuResources {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, optional => { vm => undef } );

    my $result = $args{hypervisor}->getEContext->execute(command => 'xm list');

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
