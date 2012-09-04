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

package EEntity::EHost::EHypervisor::EOpennebula3Hypervisor::EOpennebula3KvmHypervisor;
use base "EEntity::EHost::EHypervisor::EOpennebula3Hypervisor";

use strict;
use warnings;

use General;
use List::Util qw(reduce);
use XML::Simple;
use Hash::Merge qw(merge);

use Log::Log4perl "get_logger";
my $log = get_logger("");


my $resources_keys = {
    ram => { name => 'currentMemory/content', factor => 1024 },
    cpu => { name => 'vcpu/content', factor => 1 }
};


sub getAvailableMemory {
    my ($self, %args) = @_ ;

    my @vms = $self->virtual_machines;
    my $command = '';
    my $onevm_id;
    for my $vm (@vms) {
        $onevm_id = $vm->opennebula3_vm->onevm_id;
        $command .= "virsh dumpxml one-$onevm_id | grep currentMemory; "
    }

    my $result = $self->getEContext->execute(command => $command);

    my $parser = XML::Simple->new();
    my $stdout = '<root>' . $result->{stdout} . '</root>';
    my $res_array = $parser->XMLin($stdout, ForceArray => 'currentMemory')->{currentMemory};
    my $mem = 0;
    for my $res (@$res_array) {
        $mem += $res->{content} * 1024;
    }

    return $self->host_ram - $mem;

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

    # If no vm specified, get resssources for all hypervisor vms.
    my @vms;
    if (not defined $args{vm}) {
        @vms = $self->getVms;
    } else {
        push @vms, $args{vm};
    }

    my $vms_resources = {};
    for my $vm (@vms) {
        # Get the vm configuration in xml
        my $result = $self->getEContext->execute(command => 'virsh dumpxml one-' . $vm->onevm_id);
        if ($result->{exitcode} != 0) {
            throw Kanopya::Exception::Execution(error => $result->{stdout});
        }

        my $parser = XML::Simple->new();
        my $hxml = $parser->XMLin($result->{stdout});

        # Build the resssources hash according to required resources
        my $vm_resources = {};
        for my $resource (@{ $args{resources} }) {
            my $value = $hxml;
            for my $selector (split('/', $resources_keys->{$resource}->{name})) {
                $value = $value->{$selector};
            }
            $vm_resources->{$vm->id}->{$resource} = $value * $resources_keys->{$resource}->{factor};

            if ($resource eq "cpu") {
                my $pins = $hxml->{cputune}->{vcpupin};
                for my $pinning (@{$pins}) {
                    if ($pinning->{cpuset} eq '0') {
                        $vm_resources->{$vm->id}->{$resource} -= 1;
                    }
                }
            }
        }

        $vms_resources = merge($vms_resources, $vm_resources);
    }

    return $vms_resources;
};

=head2 updatePinning

=cut

sub updatePinning {
    my $self    = shift;
    my %args    = @_;

    General::checkParams(
        args        => \%args,
        required    => [ 'vm' ],
        optional    => { cpus => -1 }
    );

    if ($args{cpus} == -1) {
        $args{cpus} = $args{vm}->host_core;
    }

    my $i   = 0;
    my $cmd = "";
    while ($i < $args{vm}->opennebula3_kvm_vm_cores) {
        if ($i < $args{cpus}) {
            $cmd    .= "virsh vcpupin one-" . $args{vm}->onevm_id
                . " " . $i . " 0-" . ($self->host_core - 1) . " ; ";
        }
        else {
            $cmd    .= "virsh vcpupin one-" . $args{vm}->onevm_id
                . " " . $i . " 0 ; ";
        }
        ++$i;
    }
    $self->getEContext->execute(command => "$cmd");
}

1;
