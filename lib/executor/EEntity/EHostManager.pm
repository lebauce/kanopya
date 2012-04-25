# Copyright © 2012 Hedera Technology SAS
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

package EEntity::EHostManager;

use strict;
use warnings;

use Kanopya::Exceptions;
use DecisionMaker::HostSelector;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("administrator");

=head2 createHost

=cut

sub createHost {
    my $self = shift;
    my %args  = @_;

    General::checkParams(args     => \%args,
                         required => [ "processormodel_id", "host_core", "kernel_id",
                                       "hostmodel_id", "host_serial_number", "host_ram" ]);

    if (defined $args{erollback}) { delete $args{erollback}; }
    if (defined $args{econtext})  { delete $args{econtext}; }

    my $host = $self->_getEntity()->addHost(%args);

    #TODO: insert erollback ?
    return $host;
}

=head2 removeHost

=cut

sub removeHost {
    my $self = shift;
    my %args  = @_;

    General::checkParams(args => \%args, required => [ "host" ]);

    my $host = $self->_getEntity()->delHost(%args);

    #TODO: insert erollback ?
}

=head2 startHost

    Desc : This function starts a host in a cluster
    args : a cluster and a host

=cut

sub startHost {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "host", "econtext" ]);

    throw Kanopya::Exception::NotImplemented();
}

=head2 stopHost

    Desc : This function stops a host in a cluster
    args : a cluster and a host

=cut

sub stopHost {
    my $self = shift;
    my %args = @_;

	General::checkParams(args => \%args, required => [ "host", "econtext" ]);

    throw Kanopya::Exception::NotImplemented();
}

=head2 postStart

    Desc : This function is called once a host has started
    args : a cluster and a host

=cut

sub postStart {
    my $self = shift;
    my %args = @_;

	General::checkParams(args => \%args, required => [ "host", "econtext" ]);
}

=head2 scaleHost

    Desc : This function dynamically scales a host
    args : host, cpus, memory

=cut

sub scaleHost {
    $log->Debug("Scaling is not implemented by this host manager, doing nothing");
}

=head2 getFreeHost

    Desc : Return one free host that match the criterias
    args : ram, cpu

=cut

sub getFreeHost {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "ram", "cpu", "ifaces" ]);

    if ($args{ram_unit}) {
        $args{ram} .= $args{ram_unit};
        delete $args{ram_unit};
    }

    $args{host_manager_id} = $self->_getEntity->getAttr(name => 'entity_id');

    return DecisionMaker::HostSelector->getHost(%args);
}

1;
