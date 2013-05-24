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

package EEntity::EOperation::EScaleMemoryHost;
use base "EEntity::EOperation";

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;
use Kanopya::Exceptions;
use Entity::ServiceProvider::Cluster;
use Entity::Host;
use EEntity;
use CapacityManagement;

my $log = get_logger("");
my $errmsg;


sub prepare {
    my $self = shift;
    my %args = @_;
    my $errmsg;

    $self->SUPER::prepare();

    General::checkParams(args => $self->{context}, required => [ "host", "cloudmanager_comp"]);
    General::checkParams(args => $self->{params}, required => [ "memory" ]);

    # Verify if there is enough resource in HV
    my $vm_id = $self->{context}->{host}->getId;
    my $hv_id = $self->{context}->{host}->hypervisor->getId;

    my $cm = CapacityManagement->new(
                 cluster_id    => $self->{context}->{host}->getClusterId(),
                 cloud_manager => $self->{context}->{cloudmanager_comp},
             );

    my $check = $cm->isScalingAuthorized(
                    vm_id           => $vm_id,
                    hv_id           => $hv_id,
                    resource_type   => 'ram',
                    wanted_resource => $self->{params}->{memory},
                );

    my $mem_limit = $self->{context}->{host}->node->service_provider->getLimit(type => 'ram');

    if ($mem_limit && ($check == 0 || $self->{params}->{memory} > $mem_limit)) {
        $errmsg = "Not enough memory in HV $hv_id for VM $vm_id. Infrastructure may have change between operation queing and its execution";
        $log->debug($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    # Check if the given ram amount is not bellow the initial ram.
    my $host_manager_params = $self->{context}->{host}->node->service_provider->getManagerParameters(manager_type => 'HostManager');
    if ($host_manager_params->{ram} > $self->{params}->{memory}) {
        $errmsg = "Could not scale memory bellow the initial ram amount <" .
                  ($host_manager_params->{ram} / 1024 / 1024) . "Mo >";
        $log->debug($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
}

sub execute {
    my ($self, %args) = @_;
    $self->SUPER::execute(%args);

    $self->{context}->{cloudmanager_comp}->scaleMemory(host   => $self->{context}->{host},
                                                       memory => $self->{params}->{memory});

    $log->info("Host <" .  $self->{context}->{host}->id . "> scale in to <$self->{params}->{memory}> ram.");
}


sub finish {
    my ($self, %args) = @_;
    $self->SUPER::finish(%args);

    # Delete all but cloudmanager
    delete $self->{context}->{host};
    delete $self->{params}->{memory};
}

sub postrequisites {
    my $self = shift;
    my $vm_ram = $self->{context}->{host}->getTotalMemory;

    $self->{context}->{host}->updateMemory(memory => $vm_ram);

    my $time = 0;
    if (defined $self->{params}->{old_mem} && $self->{params}->{old_mem} == $vm_ram) {
         # RAM amount has not moved
        if(not defined $self->{params}->{time}) {
            $self->{params}->{time} = time();
        }

        $time = time() - $self->{params}->{time};
        $log->info("Checker scale time = $time");
    }
    else {
       $self->{params}->{old_mem} = $vm_ram;
       delete $self->{params}->{time};
    }

    my $precision = 0.00;
    $log->info('one ram <' . $vm_ram . '> asked ram <' . ($self->{params}->{memory}) . '> ');
    if (($vm_ram >= $self->{params}->{memory} * (1 - $precision)) &&
        ($vm_ram <= $self->{params}->{memory} * (1 + $precision))) {
        return 0;
    }
    elsif ($time < 3*10) {
        return 5; 
    }
    else {
        my $lastmessage = $self->{context}->{cloudmanager_comp}->vmLoggedErrorMessage(vm => $self->{context}->{host});
        my $error = 'ScaleIn of vm <' . $self->{context}->{host}->id . '> : Failed. Current RAM is <' . $vm_ram . '>. Cloud manager logs: '.$lastmessage;
        $log->warn($error);
        Message->send(
             from    => 'EScaleMemoryHost',
             level   => 'error',
             content => $error,
        );
        throw Kanopya::Exception(error => $error);
    }
}

sub cancel {
    my ($self, %args) = @_;
    $self->SUPER::cancel(%args);

    $self->{context}->{host}->updateMemory(memory => $self->{context}->{host}->getTotalMemory);

    $log->info('Last mem update <' . $self->{context}->{host}->host_ram . '>');
}

1;
