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

use Log::Log4perl "get_logger";
my $log = get_logger("executor");


my $ressources_keys = {
    ram => 'memory',
    cpu => 'vcpu',
};

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

    # If no vm specified, get resssources for all hypervisor vms.
    my @vms;
    if (not defined $args{vm}) {
        @vms = $self->getVms;
    } else {
        push @vms, $args{vm};
    }

    my $vms_ressources = {};
    for my $vm (@vms) {
        # Get the vm configuration in xml
        my $result = $self->getEContext->execute(command => 'virsh dumpxml one-' . $vm->onevm_id);
        if ($result->{exitcode} != 0) {
            throw Kanopya::Exception::Execution(error => $result->{stdout});
        }

        my $hxml = XMLin($result->{stdout});

        # Build the resssources hash according to required ressources
        my $vm_ressources = {};
        for my $ressource (@{ $args{ressources} }) {
            $vm_ressources->{$vm->id}->{$ressource} = $hxml->{$ressources_keys->{$ressource}};
        }

        merge($vms_ressources, $vm_ressources);
    }
    return $vms_ressources;
};

1;
