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

package Manager::HostManager;
use base "Manager";

use strict;
use warnings;

use Kanopya::Exceptions;
use Log::Log4perl "get_logger";
use Data::Dumper;

use Entity::Processormodel;
use Entity::Hostmodel;
use Entity::Kernel;
use Entity::Operation;

my $log = get_logger("");
my $errmsg;

use constant BOOT_POLICIES => {
    pxe_nfs      => 'PXE Boot via NFS',
    pxe_iscsi    => 'PXE Boot via ISCSI',
    virtual_disk => 'BootOnVirtualDisk',
    boot_on_san  => 'BootOnSan',
};

=head2 checkHostManagerParams

=cut

sub checkHostManagerParams {
    my $self = shift;
    my %args  = @_;

    General::checkParams(args => \%args, required => [ "cpu", "ram" ]);
}

=head2 addHost

=cut

sub addHost {
    my $self = shift;
    my %args  = @_;

    General::checkParams(args     => \%args,
                         required => [ "host_core", "kernel_id", "host_serial_number", "host_ram" ]);

    my $host_manager_id = $self->getAttr(name => 'entity_id');

    # Instanciate new Host Entity
    my $host;
    eval {
        $host = Entity::Host->new(host_manager_id => $host_manager_id, %args);
    };
    if($@) {
        my $errmsg = "Wrong host attributes detected\n" . $@;
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }

    # Set initial state to down
    $host->setAttr(name => 'host_state', value => 'down:' . time);

    # Save the Entity in DB
    $host->save();

    return $host;
}

=head2 delHost

=cut

sub delHost {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ "host" ]);

    # Delete the host from db
    $args{host}->delete();
}

=head2 createHost

    Desc : Implement createHost from HostManager interface.
           This function enqueue a EAddHost operation.
    args :

=cut

sub createHost {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "host_core", "kernel_id", "host_serial_number", "host_ram" ]);

    my $composite_params = {};
    if (defined $args{ifaces}) {
        # Make a hash from the iface list, as composite params
        # are in store as param presets, and it do not support array yet.
        my $index = 0;
        for my $iface (@{$args{ifaces}}) {
            $composite_params->{ifaces}->{'iface_' . $index} = $iface;
            $index++;
        }
        delete $args{ifaces};
    }

    Entity::Operation->enqueue(
        priority => 200,
        type     => 'AddHost',
        params   => {
            context  => {
                host_manager => $self,
            },
            presets  => $composite_params,
            %args
        }
    );
}

sub removeHost {
    my $self = shift;
    my %args = @_;

    General::checkParams(args  => \%args, required => [ "host" ]);

    $log->debug("New Operation RemoveHost with host_id : <" .
                $args{host}->getAttr(name => "host_id") . ">");

    Entity::Operation->enqueue(
        priority => 200,
        type     => 'RemoveHost',
        params   => {
            context  => {
                host => $args{host},
            },
        },
    );
}


sub getOvercommitmentFactors {
    my ($self) = @_;
    return {
        overcommitment_cpu_factor    => 1.0,
        overcommitment_memory_factor => 1.0,
    }
}


=head2 getFreeHosts

    Desc: return a list containing available hosts for this hosts manager

=cut

sub getFreeHosts {
    my ($self) = @_;

    my $where = {
        active          => 1,
        host_state      => {-like => 'down:%'},
        host_manager_id => $self->getAttr(name => 'entity_id')
    };

    my @hosts = Entity::Host->getHosts(hash => $where);
    my @free;
    foreach my $m (@hosts) {
        if(not $m->node) {
            push @free, $m;
        }
    }
    return @free;
}

=head2 getBootPolicies

    Desc: return a list containing boot policies available
        on hosts manager ; MUST BE IMPLEMENTED IN CHILD CLASSES

=cut

sub getBootPolicies {
    throw Kanopya::Exception::NotImplemented();
}

sub hostType {
    return "Host";
}

=head2 getRemoteSessionURL

    Desc: return an URL to a remote session to the host

=cut

sub getRemoteSessionURL {
    throw Kanopya::Exception::NotImplemented();
}

1;
