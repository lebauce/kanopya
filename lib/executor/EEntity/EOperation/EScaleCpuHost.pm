#    Copyright © 2011-12013 Hedera Technology SAS
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

package EEntity::EOperation::EScaleCpuHost;
use base EEntity::EOperation;

use strict;
use warnings;

use CapacityManagement;
use Kanopya::Exceptions;
use Entity::ServiceProvider::Cluster;
use Entity::Host;
use EEntity;

use Data::Dumper;

use Log::Log4perl "get_logger";
my $log = get_logger("");
my $errmsg;


sub check {
    my ($self, %args) = @_;
    $self->SUPER::check();

    General::checkParams(args => $self->{context}, required => [ "host", "cloudmanager_comp" ]);

    General::checkParams(args => $self->{params}, required => [ "cpu_number" ]);
}

sub execute {
    my ($self, %args) = @_;
    $self->SUPER::execute(%args);

    # Verify if there is enough resource in HV
    my $vm_id = $self->{context}->{host}->id;
    my $host_cluster = Entity::ServiceProvider::Cluster->find(hash => {
                           cluster_id => $self->{context}->{host}->getClusterId(),
                       });

    my $cm    = CapacityManagement->new(
        cluster_id    => $self->{context}->{host}->getClusterId(),
        cloud_manager => $self->{context}->{cloudmanager_comp},
    );

    my $check = $cm->isScalingAuthorized(
                    vm_id           => $vm_id,
                    resource_type   => 'cpu',
                    wanted_resource => $self->{params}->{cpu_number},
                );

    if ($check == 0) {
        my $hv_id = $self->{context}->{host}->hypervisor->id;
        my $errmsg = "Not enough CPU in HV $hv_id for VM $vm_id. " .
                     "Infrastructure may have change between operation queing and its execution";
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    # Check billing limit before launching scale, but only in case of scale up
    if ($self->{params}->{cpu_number} > $self->{context}->{host}->host_core) {
        my $cpu_to_add = $self->{params}->{cpu_number} - $self->{context}->{host}->host_core;
        $host_cluster->checkBillingLimits(metrics => { cpu => $cpu_to_add });
    }

    $self->{context}->{cloudmanager_comp}->scaleCpu(host       => $self->{context}->{host},
                                                    cpu_number => $self->{params}->{cpu_number});

    $log->info("Host <" .  $self->{context}->{host}->id . "> " .
               "scaled in to <$self->{params}->{cpu_number}> cpu number.");
}


sub finish {
    my ($self, %args) = @_;
    $self->SUPER::finish(%args);

    # Delete all but cloudmanager
    # Do not delete host (need in Resubmit workflow)
    delete $self->{params}->{cpu_number};
}


sub postrequisites {
    my ($self, %args) = @_;

    my $vm_cpu = $self->{context}->{host}->getTotalCpu;

    $self->{context}->{host}->updateCPU(cpu_number => $vm_cpu);

    my $time = 0;
    if (defined $self->{params}->{old_cpu} && $self->{params}->{old_cpu} == $vm_cpu) {
        # CPU amount has not moved
        if(not defined $self->{params}->{time}) {
            $self->{params}->{time} = time();
        }

        $time = time() - $self->{params}->{time};
        $log->info("Checker scale time = $time");
    }
    else {
       $self->{params}->{old_cpu} = $vm_cpu;
       delete $self->{params}->{time};
    }

    $log->info('one cpu <' . $vm_cpu . '> asked cpu <' . $self->{params}->{cpu_number} . '> ');
    if ($vm_cpu == $self->{params}->{cpu_number}) {
        return 0;
    }
    elsif ($time < 9*10) {
        return 5;
    }
    else {
        my $error = 'Timeout - ScaleIn of vm <' . $self->{context}->{host}->id . '> : Failed. Current CPU is <' . $vm_cpu . '>';
        $log->warn($error);
        Message->send(
             from    => 'EScaleCpuHost',
             level   => 'error',
             content => $error,
        );
        throw Kanopya::Exception(error => $error);
    }
}

sub cancel {
    my ($self, %args) = @_;
    $self->SUPER::cancel(%args);

    $self->{context}->{host}->updateCPU(cpu_number => $self->{context}->{host}->getTotalCpu);

    $log->info('Last cpu update <' . $self->{context}->{host}->host_core . '>');
}

1;

