# EFlushHypervisor.pm - Operation class implementing

#    Copyright © 2012 Hedera Technology SAS
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

package EEntity::EOperation::EFlushHypervisor;
use base "EEntity::EOperation";

use strict;
use warnings;
use Entity;
use CapacityManagement;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");
my $errmsg;

sub check {
    my $self = shift;

    General::checkParams(args => $self->{context}, required => [ "host" ]);
}

sub prerequisites {
    my $self = shift;
    $self->SUPER::prerequisites();

    if (not $self->{context}->{host}->isa('EEntity::EHost::EHypervisor')) {
        my $error = 'Operation can only be applied to an hypervisor';
        throw Kanopya::Exception(error => $error);
    }

    # variable used in maintenance workflows
    $self->{context}->{host_to_deactivate} = $self->{context}->{host};

    $self->{context}->{cloud_manager} = EEntity->new(
                                            data => $self->{context}->{host}->getCloudManager(),
                                        );

    my $cm = CapacityManagement->new(
                 cloud_manager => $self->{context}->{cloud_manager},
             );

    my $host_id = $self->{context}->{host}->id;

    my $flushRes = $cm->flushHypervisor(hv_id => $host_id);

    my $hypervisors = {};
    for my $operation (@{$flushRes->{ operation_plan }}) {
        $hypervisors->{$operation->{params}->{context}->{host}->id} = $operation->{params}->{context}->{host};
    }

    my @hvs_array = values %$hypervisors;

    my $diff_infra_db = $self->{context}
                             ->{cloud_manager}
                             ->checkHypervisorsVMPlacementIntegrity(hypervisors => \@hvs_array);

    if (! $self->{context}->{cloud_manager}->isInfrastructureSynchronized(hash => $diff_infra_db)) {

        $self->workflow->enqueueBefore(
            current_operation => $self,
            operation => {
                priority => 200,
                type     => 'SynchronizeInfrastructure',
                params   => {
                    context => {
                        cloud_manager => $self->{context}->{cloud_manager}
                    },
                    diff_infra_db => $diff_infra_db,
                }
            }
        );
        return -1;
    }

    if ($flushRes->{num_failed} > 0) {
        throw Kanopya::Exception(error => "The hypervisor ".$self->{context}->{host}->node->node_hostname." can't be flushed");
    }
}

sub execute {
    my $self = shift;
    $self->SUPER::execute();
    $log->info('Flush hypervisor '.$self->{context}->{host}->node->node_hostname);

    for my $operation (@{$flushRes->{operation_plan}}) {
        $log->debug('Operation enqueuing host = '.$operation->{params}->{context}->{host}->id);
        $self->workflow->enqueueNow(operation => $operation);
    }
}

sub finish {
    my ($self) = @_;

    delete $self->{context}->{host};
}

1;
