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
# Created 26 sept 2012

=head1 NAME

EEntity::Operation::EFlushHypervisor - Operation class implementing

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement

=head1 DESCRIPTION

Component is an abstract class of operation objects

=head1 METHODS

=cut
package EEntity::EOperation::EFlushHypervisor;
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

    # variable used in maintenance workflows
    $self->{context}->{host_to_deactivate} = $self->{context}->{host};
}

sub execute {
    my $self = shift;

    $self->{context}->{cloud_manager} = EEntity->new(
                                            data => $self->{context}->{host}->getCloudManager(),
                                        );

    my $cm = CapacityManagement->new(
        cloud_manager => $self->{context}->{cloud_manager},
    );

    my $host_id = $self->{context}->{host}->id;

    my $flushRes = $cm->flushHypervisor(hv_id => $host_id);
    if ($flushRes->{num_failed} == 0) {
        my $workflow = $self->workflow;
        for my $operation (@{$flushRes->{operation_plan}}) {
            $log->info('Operation enqueuing host = '.$operation->{params}->{context}->{host}->id);
            $workflow->enqueueNow(operation => $operation);
        }
    }
    else {
        throw Kanopya::Exception(
                  error => "The hypervisor ".$self->{context}->{host}->node->node_hostname." can't be flushed"
              );
    }
    $self->SUPER::execute();
}

sub finish {
    my ($self) = @_;
    delete $self->{context}->{host};
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

