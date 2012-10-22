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

package EManager::EHostManager;
use base "EManager";

use strict;
use warnings;

use Kanopya::Exceptions;
use DecisionMaker::HostSelector;

use Entity::Processormodel;
use Entity::Hostmodel;
use Entity::Kernel;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");
my $errmsg;

=head2 createHost

=cut

sub createHost {
    my $self = shift;
    my %args  = @_;

    General::checkParams(args     => \%args,
                         required => [ "host_core", "kernel_id",
                                       "host_serial_number", "host_ram" ]);

    if (defined $args{erollback}) { delete $args{erollback}; }

    # Check if kernel_id exist
    $log->debug("checking kernel existence with id <$args{kernel_id}>");
    eval {
        Entity::Kernel->get(id => $args{kernel_id});
    };
    if($@) {
        $errmsg = "Wrong kernel_id attribute detected <$args{kernel_id}>\n" . $@;
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }

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

    my $host = $self->_getEntity()->delHost(host => $args{host}->_getEntity);

    #TODO: insert erollback ?
}

=head2 startHost

    Desc : This function starts a host in a cluster
    args : a cluster and a host

=cut

sub startHost {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "host" ]);

    throw Kanopya::Exception::NotImplemented();
}

=head2 stopHost

    Desc : This function stops a host in a cluster
    args : a cluster and a host

=cut

sub stopHost {
    my $self = shift;
    my %args = @_;

	General::checkParams(args => \%args, required => [ "host" ]);

    throw Kanopya::Exception::NotImplemented();
}

=head2 postStart

    Desc : This function is called once a host has started
    args : a cluster and a host

=cut

sub postStart {
    my $self = shift;
    my %args = @_;

	General::checkParams(args => \%args, required => [ "host" ]);
}

=head2 scaleHost

    Desc : This function dynamically scales a host
    args : host, cpus, memory

=cut

sub scaleHost {
    $log->debug("Scaling is not implemented by this host manager, doing nothing");
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

=head2 applyVLAN

    Desc: Apply a VLAN on an interface of a host
    Args: vlan, iface

=cut

sub applyVLAN {
    $log->debug("VLAN are not supported by this host manager, doing nothing");
}

1;
