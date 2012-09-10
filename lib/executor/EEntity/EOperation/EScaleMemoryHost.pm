# EScaleMemoryHost.pm - Operation class implementing memory scale in

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

EOperation::EScaleMemoryHost - Operation class implementing memory scale in

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement cluster activation operation

=head1 DESCRIPTION

Component is an abstract class of operation objects

=head1 METHODS

=cut
package EEntity::EOperation::EScaleMemoryHost;
use base "EEntity::EOperation";

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;
use Kanopya::Exceptions;
use Entity::ServiceProvider::Inside::Cluster;
use Entity::Host;
use EFactory;
use CapacityManagement;

my $log = get_logger("");
my $errmsg;
our $VERSION = '1.00';

=head2 prepare

=cut

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
                    wanted_resource => $self->{params}->{memory} * 1024 * 1024, #GIVEN IN MB MUST BE IN B
                );

    my $mem_limit = $self->{context}->{host}->node->parent->service_provider->getLimit(type => 'ram');

    if ($mem_limit && ($check == 0 || $self->{params}->{memory} > $mem_limit)) {
        $errmsg = "Not enough memory in HV $hv_id for VM $vm_id. Infrastructure may have change between operation queing and its execution";
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    # Check if the given ram amount is not bellow the initial ram.
    my $host_manager_params = $self->{context}->{host}->node->parent->service_provider->getManagerParameters(manager_type => 'host_manager');
    my $initial_ram = $host_manager_params->{ram};

    if ($host_manager_params->{ram_unit} eq 'G') {
        $initial_ram *= 1024;
    }

    if ($initial_ram > $self->{params}->{memory}) {
        $errmsg = "Could not scale memory bellow the initial ram amount ($initial_ram)";
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
}

sub execute {
    my $self = shift;
    $self->{context}->{cloudmanager_comp}->scale_memory(host   => $self->{context}->{host},
                                                        memory => $self->{params}->{memory});

    $log->info("Host <" .  $self->{context}->{host}->getAttr(name => 'entity_id') .
               "> scale in to <$self->{params}->{memory}> ram.");
}


sub finish {
    my $self = shift;
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
    $log->info('one ram <' . $vm_ram . '> asked ram <' . ($self->{params}->{memory} * 1024 * 1024) . '> ');
    if (($vm_ram >= $self->{params}->{memory} * 1024 * 1024 * (1 - $precision)) &&
        ($vm_ram <= $self->{params}->{memory} * 1024 * 1024 * (1 + $precision))) {
        return 0;
    }
    elsif ($time < 3*10) {
        return 5;
    }
    else {
        my $error = 'ScaleIn of vm <' . $self->{context}->{host}->id . '> : Failed. Current RAM is <' . $vm_ram . '>';
        Message->send(
             from    => 'EScaleMemoryHost',
             level   => 'error',
             content => $error,
        );
        throw Kanopya::Exception(error => $error);
    }
}

sub _cancel {
    my $self = shift;

    $self->{context}->{host}->updateMemory(memory => $self->{context}->{host}->getTotalMemory);

    $log->info('Last mem update <' . $self->{context}->{host}->host_ram . '>');
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
