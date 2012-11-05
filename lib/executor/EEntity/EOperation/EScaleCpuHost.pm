# EScaleCpuHost.pm - Operation class implementing vcpus scale in

#    Copyright © 2011 Hedera Technology SAS
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
# Created 14 july 2010

=head1 NAME

EOperation::EScaleCpuHost - Operation class implementing vcpus scale in

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement cluster activation operation

=head1 DESCRIPTION

Component is an abstract class of operation objects

=head1 METHODS

=cut
package EEntity::EOperation::EScaleCpuHost;
use base "EEntity::EOperation";

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;

use CapacityManagement;
use Kanopya::Exceptions;
use Entity::ServiceProvider::Inside::Cluster;
use Entity::Host;
use EFactory;

my $log = get_logger("");
my $errmsg;

our $VERSION = '1.00';

=head2 prepare

=cut

sub prepare {
    my $self = shift;
    my %args = @_;
    $self->SUPER::prepare();

    General::checkParams(args => $self->{context}, required => [ "host","cloudmanager_comp" ]);

    General::checkParams(args => $self->{params}, required => [ "cpu_number" ]);

    # Verify if there is enough resource in HV
    my $vm_id = $self->{context}->{host}->getId;
    my $hv_id = $self->{context}->{host}->hypervisor->getId;

    my $cm    = CapacityManagement->new(
        cluster_id    => $self->{context}->{host}->getClusterId(),
        cloud_manager => $self->{context}->{cloudmanager_comp},
    );

    my $check = $cm->isScalingAuthorized(
                    vm_id           => $vm_id,
                    hv_id           => $hv_id,
                    resource_type   => 'cpu',
                    wanted_resource => $self->{params}->{cpu_number},
                );

    my $cpu_limit = $self->{context}->{host}->node->parent->service_provider->getLimit(type => 'cpu');

    if ($cpu_limit && ($check == 0 || $self->{params}->{cpu_number} > $cpu_limit)) {
        my $errmsg = "Not enough CPU in HV $hv_id for VM $vm_id. Infrastructure may have change between operation queing and its execution";
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
}

sub execute{
    my $self = shift;

    $self->{context}->{cloudmanager_comp}->scaleCpu(host       => $self->{context}->{host},
                                                    cpu_number => $self->{params}->{cpu_number});

    $log->info("Host <" .  $self->{context}->{host}->getAttr(name => 'entity_id') .
               "> scale in to <$self->{params}->{cpu_number}> cpu number.");
}


sub finish {
      my $self = shift;
      # Delete all but cloudmanager
      # Do not delete host (need in Resubmit workflow)
      delete $self->{params}->{cpu_number};
}


sub postrequisites {
    my $self = shift;

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
    elsif ($time < 3*10) {
        return 5;
    }
    else {
        my $error = 'ScaleIn of vm <' . $self->{context}->{host}->id . '> : Failed. Current CPU is <' . $vm_cpu . '>';
        Message->send(
             from    => 'EScaleCpuHost',
             level   => 'error',
             content => $error,
        );
        throw Kanopya::Exception(error => $error);
    }
}

sub _cancel {
    my $self = shift;

    $self->{context}->{host}->updateCPU(cpu_number => $self->{context}->{host}->getTotalCpu);

    $log->info('Last cpu update <' . $self->{context}->{host}->host_core . '>');
}

=head1 DIAGNOSTICS

Exceptions are thrown when mandatory arguments are missing.
Exception : Kanopya::Exception::Internal::IncorrectParam

=head1 CONFIGURATION AND ENVIRONMENT

This module need to be used into Kanopya environment. (see Kanopya presentation)
This module is a part of Administrator package so refers to Administrator configuration

=head1 DEPENDENCIES

This module depends of

=over

=item KanopyaException module used to throw exceptions managed by handling programs

=item Entity::Component module which is its mother class implementing global component method

=back

=head1 INCOMPATIBILITIES

None

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to <Maintainer name(s)> (<contact address>)

Patches are welcome.

=head1 AUTHOR

<HederaTech Dev Team> (<dev@hederatech.com>)

=head1 LICENCE AND COPYRIGHT

Kanopya Copyright (C) 2009, 2010, 2011, 2012, 2013 Hedera Technology.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; see the file COPYING.  If not, write to the
Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
Boston, MA 02110-1301 USA.

=cut

1;

