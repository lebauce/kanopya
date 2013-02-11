# ERelieveHypervisor.pm - Operation class implementing

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
# Created 26 sept 2012

=head1 NAME

EEntity::Operation::ERelieveHypervisor - Operation class implementing

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement

=head1 DESCRIPTION

Component is an abstract class of operation objects

=head1 METHODS

=cut
package EEntity::EOperation::ERelieveHypervisor;
use base "EEntity::EOperation";

use strict;
use warnings;
use Entity;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");
my $errmsg;

sub check {
    my $self = shift;
    General::checkParams(args => $self->{context}, required => [ "host" ]);
}


sub prepare {
    my $self = shift;
    $self->SUPER::prepare();

    if (not $self->{context}->{host}->isa('EEntity::EHost::EHypervisor')) {
        my $error = 'Operation can only be applied to an hypervisor';
        throw Kanopya::Exception(error => $error);
    }

    my @cloudmanagers = $self->{context}->{host}->node->service_provider->getComponents(category => 'HostManager');
    $self->{context}->{cloud_manager} = EFactory::newEEntity(data => $cloudmanagers[0]);

    my $vm_min_effective_ram = $self->{context}->{host}->getMinEffectiveRamVm(); #vm / ram
    my $hv_max_effective_freeram = $self->{context}->{cloud_manager}->getMaxRamFreeHV();  #hv / ram

    if ($hv_max_effective_freeram->{hypervisor}->id eq  $self->{context}->{host}->id) {
        my $error = 'Hypervisor is already the least loaded one';
        throw Kanopya::Exception(error => $error);
    }

# Transmit new context to next operation defined in workflow_def (migratehost)
    $self->{context}->{vm}   = $vm_min_effective_ram->{vm},
    $self->{context}->{host} = $hv_max_effective_freeram->{hypervisor},
  }

sub execute {
    my $self = shift;
    $self->SUPER::execute();
}

sub finish {
    my ($self) = @_;
#    $self->getWorkflow()->enqueue(
#        type => 'MigrateHost',
#        priority => 1,
#        params => {
#            context => {
#                vm    => $self->{context}->{virtual_machine},
#                host  => $self->{context}->{hypervisor_destination},
#            },
#        }
#    );
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

