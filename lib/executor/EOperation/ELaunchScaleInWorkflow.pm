# ELaunchSCOWorkflow.pm - Launch a SCP Workflow

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
# Created 30 may 2012

=head1 NAME

EOperation::ELaunchSCOWorkflow - Operation class implementing SCO workflow launching

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement SCO workflow launching

=head1 DESCRIPTION

Component is an abstract class of operation objects

=head1 METHODS

=cut
package EOperation::ELaunchScaleInWorkflow;
use base "EOperation";

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;
use Kanopya::Exceptions;
use EFactory;
use CapacityManagement;
#use Entity::ServiceProvider::Inside::Cluster;
#use Entity::Host;

my $log = get_logger("executor");
my $errmsg;
our $VERSION = '1.00';

=head2 prepare

=cut

sub prepare {
    my $self = shift;
    my %args = @_;
    $self->SUPER::prepare();

    General::checkParams(args => $self->{params}, required => [
        'scalein_value',
        'scalein_type',
    ]);

    General::checkParams(args => $self->{context}, required => [ "host" ]);

}

sub execute{
    my $self = shift;
    $self->SUPER::execute();

    my $scalein_value    = $self->{params}->{scalein_value};
    my $scalein_type     = $self->{params}->{scalein_type};

    delete $self->{params}->{scalein_value};
    delete $self->{params}->{scalein_type};

    my $cluster_id = $self->{context}->{host}->getClusterId();
    my $cm         = CapacityManagement->new(cluster_id => $cluster_id);
    my $operation_plan;
    $log->info('____scaleintype'.$scalein_type);
    if ($scalein_type eq 'memory') {
        $operation_plan = $cm->scaleMemoryHost(
            host_id => $self->{context}->{host}->getId(),
            memory  => $scalein_value,
        );
    }
    elsif ($scalein_type eq 'cpu') {
        $operation_plan = $cm->scaleCpuHost(
            host_id     => $self->{context}->{host}->getId(),
            vcpu_number => $scalein_value,
        );
    }
    for my $operation (@$operation_plan){
        $log->info('Operation enqueuing');
        $self->getWorkflow()->enqueue(
            %$operation
        );
    }
}


sub finish{
    my $self = shift;
    delete $self->{context}->{host};
}
=head1 DIAGNOSTICS
Exceptions are thrown when mandatory arguments are missing.
Exception : Kanopya::Exception::Internal::IncorrectParam

=head1 CONFIGURATION AND ENVIRONMENT

This module need to be used into Kanopya environment. (see Kanopya presentation)
This module is a part of Executor package so refers to Executor configuration

=head1 DEPENDENCIES

This module depends of

=over

=item Kanopya::Exception module used to throw exceptions managed by handling programs

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
