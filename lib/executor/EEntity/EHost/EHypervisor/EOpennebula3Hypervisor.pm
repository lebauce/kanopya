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

package EEntity::EHost::EHypervisor::EOpennebula3Hypervisor;
use base "EEntity::EHost::EHypervisor";

use strict;
use warnings;
use Data::Dumper;
use Log::Log4perl "get_logger";
use CapacityManagement;

my $log = get_logger("");

sub checkStoppable {
    my $self = shift;

    $log->info('entering prestopable');
    my @vms = $self->getVms();

    if (scalar @vms) {
        $log->info('Some vms needs to be migrated before stopping this hypervisor');
        my $cluster = Entity->get(id => $self->node->inside_id);
        $log->info(ref $cluster);
        my $opennebula3   = $cluster->getComponent(name => "Opennebula", version => "3");

        my $cm = CapacityManagement->new(
            hypervisor_cluster_id  => $self->node->inside_id,
            cloud_manager => $opennebula3,
        );
        my $flushRes = $cm->flushHypervisor(hv_id => $self->getId());
        if ($flushRes->{num_failed} == 0) {
            my $workflow = Workflow->new(workflow_name => 'remediation_hypervisor_'.$self->getId());
            for my $operation (@{$flushRes->{operation_plan}}){
                $log->info('Operation enqueuing');
                $workflow->enqueue(
                    %$operation
                );
            }
            return {remediation_workflow_id => $workflow->getId()}
        }
        else {
            throw Kanopya::Exception(error => "The hypervisor " . $self->host_hostname .
                                          " can't be stopped as it still runs virtual machines which can not be migrated");
        }
    }
    else {
        $log->info('hypervisor is empty stop authorized');
        return {};
    }
}

sub getMaxRamFreeVm{
    my ($self, %args) = @_;
    General::checkParams(
        args     => \%args,
        required => [ 'cluster' ]
    );
}

1;
