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

package EEntity::EHost::EVirtualMachine;
use base "EEntity::EHost";

use strict;
use warnings;

use Entity;
use EFactory;

use Log::Log4perl "get_logger";
my $log = get_logger("");


=head2 getTotalMemory

    Return the total memory amount.

=cut

sub getTotalMemory {
    my ($self, %args) = @_;

    my $vm_resources = $self->getHypervisor->getVmResources(vm => $self, resources => [ 'ram' ]);
    return $vm_resources->{$self->id}->{ram};
}

=head2 getTotalCpu

    Return the total cpu count.

=cut

sub getTotalCpu {
    my ($self, %args) = @_;

    my $vm_resources = $self->getHypervisor->getVmResources(vm => $self, resources => [ 'cpu' ]);
    return $vm_resources->{$self->id}->{cpu};
}

=head2 getHypervisor

    Return EEntity corresponding to the hypervisor.

=cut

sub getHypervisor {
    my ($self, %args) = @_;

    # Can not use $self->hypervisor to get the hypervisor as this call
    # do not return the concrete class of the hypervisor yet, and do not
    # return the corresponding EEntity.
    return EFactory::newEEntity(data => Entity->get(id => $self->hypervisor->id));
}

1;
