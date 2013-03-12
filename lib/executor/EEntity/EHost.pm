# Copyright © 2011-2012 Hedera Technology SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

=head1 NAME

EHost - execution class of host entities

=head1 SYNOPSIS

=head1 DESCRIPTION

EHost is the execution class of host entities

=head1 METHODS

=cut

package EEntity::EHost;
use base "EEntity";

use strict;
use warnings;

use Entity;

use String::Random;
use Template;
use IO::Socket;

use Log::Log4perl "get_logger";

my $log = get_logger("");
my $errmsg;

sub getHostManager {
    my $self = shift;

    return EEntity->new(data => $self->SUPER::getHostManager);
}

sub start {
    my $self = shift;
    my %args = @_;

    $self->getHostManager->startHost(host       => $self,
                                     hypervisor => $args{hypervisor},
                                     cluster    => $args{cluster});

    $self->setState(state => 'starting');

    # Sommetimes a host can be promoted to another object type
    # So reload the object to be sure to have the good type.
    return EEntity->new(data => Entity->get(id => $self->id));
}

sub halt {
    my $self = shift;
    my %args = @_;

    my $result = $self->getEContext->execute(command => 'halt');
    $self->setState(state => 'stopping');
}

sub stop {
    my $self = shift;
    my %args = @_;

    $self->getHostManager->stopHost(host => $self);
}

sub postStart {
    my $self = shift;
    my %args = @_;

    $self->getHostManager->postStart(host => $self);
}

sub checkUp {
    my ($self, %args) = @_;

    return $self->getHostManager->checkUp(host => $self);
}

sub timeOuted {
    my $self = shift;

    $self->setState(state => 'broken');
}

=head2 getSystemComponent

    Return the component to interrogate to get system informations

=cut

sub getSystemComponent {
    my $self = shift;

    return EEntity->new(entity => $self->node->service_provider->getComponent(category => "System"));
}

=head2 getAvailableMemory

    Return the available memory amount.

=cut

sub getAvailableMemory {
    my $self = shift;

    return $self->getSystemComponent->getAvailableMemory(host => $self);
}

=head2 getTotalMemory

    Return the total memory amount.

=cut

sub getTotalMemory {
    my ($self, %args) = @_;

    return $self->getAvailableMemory()->{mem_total};
}

=head2 getTotalCpu

    Return the total cpu count.

=cut

sub getTotalCpu {
    my $self = shift;

    return $self->getSystemComponent->getTotalCpu(host => $self);
}

sub getEContext {
    my $self = shift;

    return $self->SUPER::getEContext(dst_host => $self);
}

1;
