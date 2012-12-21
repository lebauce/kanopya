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

package EEntity::EHost::EHypervisor;
use base "EEntity::EHost";

use strict;
use warnings;

use EEntity;

use Log::Log4perl "get_logger";

my $log = get_logger("");

sub vmm {
    my $self = shift;

    return EEntity->new(entity => $self->node->service_provider->getComponent(category => "Hypervisor"));
}

=head2 getAvailableMemory

    Return the available memory amount.

=cut

sub getAvailableMemory {
    my ($self, %args) = @_;

    return $self->vmm->getAvailableMemory(host => $self,
                                          %args);
}

=head2 getVmResources

    Return virtual machines resources. If no resssource type(s)
    specified in parameters, return all know ressouces.

=cut

sub getVmResources {
    my ($self, %args) = @_;
    return $self->vmm->getVmResources(host => $self, %args);
}

=head2 getAvailableMemory

    Update the CPU pinning of the hypervisor

=cut

sub updatePinning {
    my ($self, %args) = @_;

    return $self->vmm->updatePinning(host => $self,
                                     %args);
}

sub getMinEffectiveRamVm {
    my ($self, %args) = @_;

    return $self->vmm->getMinEffectiveRamVm(host => $self,
                                            %args);
}

1;
