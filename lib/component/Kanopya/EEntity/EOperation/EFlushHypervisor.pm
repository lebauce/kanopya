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

=pod
=begin classdoc

TODO

=end classdoc
=cut

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

    if (not $self->{context}->{host}->isa('EEntity::EHost::EHypervisor')) {
        my $error = 'Operation can only be applied to an hypervisor';
        throw Kanopya::Exception(error => $error);
    }

    $self->{context}->{cloud_manager} = EEntity->new(
                                            data => $self->{context}->{host}->iaas
                                        );
}


sub prepare {
    my $self = shift;
    $self->{context}->{cloud_manager}->increaseConsumers(operation => $self);
}


sub prerequisites {
    my $self = shift;

    # First check of the hypervisor to flush
    my $diff_infra_db = $self->{context}
                             ->{cloud_manager}
                             ->checkHypervisorVMPlacementIntegrity(
                                   host => $self->{context}->{host}
                               );

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

    my $cm = CapacityManagement->new(
                 cloud_manager => $self->{context}->{cloud_manager},
             );

    my $flushRes = $cm->flushHypervisor(hv_id => $self->{context}->{host}->id);

    my $hypervisors = {};
    for my $operation (@{$flushRes->{ operation_plan }}) {
        $hypervisors->{$operation->{params}->{context}->{host}->id} = $operation->{params}->{context}->{host};
    }

    my @hvs_array = values %$hypervisors;

    # Second check of the hypervisors on which it flushs
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
        throw Kanopya::Exception(
                  error => 'The hypervisor '
                           . $self->{context}->{host}->node->node_hostname
                           . ' can not be flushed');
    }

    my $num_op = 0;
    for my $operation (@{$flushRes->{ operation_plan }}) {
        $num_op++;
        $self->workflow->enqueueBefore(
            operation         => $operation,
            operation_state   => 'prereported',
            current_operation => $self,
        );
    }
    return $num_op ? -1 : 0;
}

sub execute {
    my $self = shift;
}

sub finish {
    my $self = shift;

    $self->{context}->{cloud_manager}->decreaseConsumers(operation => $self);
    delete $self->{context}->{host};
    delete $self->{context}->{cloud_manager};
}


=pod
=begin classdoc

Restore the clutser and host states.

=end classdoc
=cut

sub cancel {
    my ($self, %args) = @_;
    $self->finish(%args);
}

1;
