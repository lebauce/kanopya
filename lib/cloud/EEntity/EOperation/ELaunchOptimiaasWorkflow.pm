#    Copyright © 2011-2013 Hedera Technology SAS
#
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

package EEntity::EOperation::ELaunchOptimiaasWorkflow;
use base EEntity::EOperation;

use strict;
use warnings;

use Kanopya::Exceptions;
use CapacityManager::HCMCapacityManager;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");
my $errmsg;

sub check {
    my ($self, %args) = @_;
    General::checkParams(args => $self->{context}, required => [ "cloudmanager_comp" ]);
}


sub prepare {
    my $self = shift;
    $self->{context}->{cloudmanager_comp}->increaseConsumers(operation => $self);
}

sub prerequisites {
    my $self = shift;

    if (defined $self->{params}->{optimiaas}) {
        return 0;
    }

    my $diff_infra_db = $self->{context}
                        ->{cloudmanager_comp}
                        ->checkAllInfrastructureIntegrity();

    if (! $self->{context}->{cloudmanager_comp}->isInfrastructureSynchronized(hash => $diff_infra_db)) {

        $self->workflow->enqueueBefore(
            current_operation => $self,
            operation => {
                priority => 200,
                type     => 'SynchronizeInfrastructure',
                params   => {
                    context => {
                        cloud_manager => $self->{context}->{cloudmanager_comp}
                    },
                diff_infra_db => $diff_infra_db,
                }
            }
        );
        return -1;
    }



    my $cm  = CapacityManager::HCMCapacityManager->new(
                  cloud_manager => $self->{context}->{cloudmanager_comp},
              );

    my $operation_plan = $cm->optimIaas(policy => $self->{params}->{policy});

    my $num_op = 0;
    for my $operation (@$operation_plan){
        if (defined $operation->{params}->{context}->{vm}->node) {
            $log->info('Operation enqueuing');
            $self->workflow->enqueueBefore(
                operation         => $operation,
                operation_state   => 'prereported',
                current_operation => $self,
            );
            $num_op++;
        }
        else {
            $log->info('Vm <'.$operation->{params}->{context}->{vm}->id.'> has no node, maybe not managed by Kanopya');
        }
    }
    $self->{params}->{optimiaas} = 1;

    return $num_op ? -1 : 0;
}


sub finish {
    my $self = shift;

    $self->{context}->{cloudmanager_comp}->decreaseConsumers(operation => $self);
    delete $self->{context}->{cloudmanager_comp};
}

sub cancel {
    my $self = shift;
    $self->finish;
}
1;
