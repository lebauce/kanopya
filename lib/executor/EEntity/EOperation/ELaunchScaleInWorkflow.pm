#    Copyright © 2011 Hedera Technology SAS
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

package EEntity::EOperation::ELaunchScaleInWorkflow;
use base "EEntity::EOperation";

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;
use Kanopya::Exceptions;
use EEntity;
use CapacityManagement;

my $log = get_logger("");
my $errmsg;


sub check {
    my $self = shift;
    my %args = @_;
    $self->SUPER::check();

    General::checkParams(args => $self->{params}, required => [ 'scalein_value', 'scalein_type' ]);
    General::checkParams(args => $self->{context}, required => [ 'host', 'cloudmanager_comp' ]);
    $self->{context}->{host_manager_sp} = $self->{context}->{cloudmanager_comp}->service_provider;
}


sub prepare {
    my ($self, %args) = @_;
    $self->SUPER::prepare();

    # Check host manager sp states
    my @entity_states =  $self->{context}->{host_manager_sp}->entity_states;

    for my $entity_state (@entity_states) {
        throw Kanopya::Exception::Execution::InvalidState(
                  error => "The host manager cluster <" .$self->{context}->{host_manager_sp}->cluster_name .
                           "> is <" . $entity_state->state .
                           "> which is not a correct state to accept scale-in"
              );
    }
    # TODO Manage 'scalein' state to controll operation allowed during scalein
}

sub execute{
    my $self = shift;
    $self->SUPER::execute();

    my $scalein_value = $self->{params}->{scalein_value};
    my $scalein_type  = $self->{params}->{scalein_type};

    delete $self->{params}->{scalein_value};
    delete $self->{params}->{scalein_type};

    my $cluster_id = $self->{context}->{host}->getClusterId();

    my $cm = CapacityManagement->new(
                 cloud_manager => $self->{context}->{cloudmanager_comp},
             );

    # Do not call getServiceProvider() method, because it returns HV Cluster
    # Here we need VM Cluster
    my $service_provider = $self->{context}->{host}->node->service_provider;

    my $operation_plan;
    $log->info('Launch Scale type <'.($scalein_type).'>');
    if ($scalein_type eq 'memory') {
        $operation_plan = $cm->scaleMemoryHost(
            host_id      => $self->{context}->{host}->id(),
            memory       => $scalein_value,
        );
    }
    elsif ($scalein_type eq 'cpu') {
        $operation_plan = $cm->scaleCpuHost(
            host_id      => $self->{context}->{host}->id(),
            vcpu_number  => $scalein_value,
        );
    }
    $log->info('Total of <'.(scalar @$operation_plan).'> operation(s) to enqueue');
    for my $operation (@$operation_plan){
        $log->info('Operation enqueuing');
        $self->workflow->enqueue(
            %$operation
        );
    }
}


sub finish{
    my $self = shift;

    delete $self->{context}->{host};
}

1;
