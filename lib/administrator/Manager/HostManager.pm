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

my $log = get_logger("");
my $errmsg;

use constant BOOT_POLICIES => {
    pxe_nfs      => 'PXE Boot via NFS',
    pxe_iscsi    => 'PXE Boot via ISCSI',
    root_iscsi   => 'Boot on root ISCSI',
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

sub getHostManagerParams {
    my $self = shift;
    my %args  = @_;

    return {};
}


=head2 addHost

=cut

sub addHost {
    my $self = shift;
    my %args  = @_;

    General::checkParams(args     => \%args,
                         required => [ "host_core", "host_serial_number", "host_ram" ]);

    # Instanciate new Host Entity
    my $host;
    eval {
        $host = Entity::Host->new(host_manager_id => $self->id, %args);
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
                         required => [ "host_core", "host_serial_number", "host_ram" ]);

    $self->service_provider->getManager(manager_type => 'ExecutionManager')->enqueue(
        type     => 'AddHost',
        params   => {
            context  => {
                host_manager => $self,
            },
            %args
        }
    );
}

sub removeHost {
    my $self = shift;
    my %args = @_;

    General::checkParams(args  => \%args, required => [ "host" ]);

    $self->service_provider->getManager(manager_type => 'ExecutionManager')->enqueue(
        type     => 'RemoveHost',
        params   => {
            context  => {
                host => $args{host},
            },
        },
    );
}

sub activateHost {
    my ($self, %args) = @_;

    General::checkParams(args  => \%args, required => [ "host" ]);

    $self->service_provider->getManager(manager_type => 'ExecutionManager')->enqueue(
        type     => 'ActivateHost',
        params   => {
            context => {
                host => $args{host},
           }
       }
   );
}

sub deactivateHost {
    my ($self, %args) = @_;

    General::checkParams(args  => \%args, required => [ "host" ]);

    $self->service_provider->getManager(manager_type => 'ExecutionManager')->enqueue(
        type     => 'DeactivateHost',
        params   => {
            context => {
                host_to_deactivate => $args{host},
            }
        }
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
        host_manager_id => $self->id
    };

    my @hosts = Entity::Host->search(hash => $where);
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
