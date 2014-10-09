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

=pod
=begin classdoc

TODO

=end classdoc
=cut

package Manager::HostManager;
use base "Manager";

use strict;
use warnings;

use Kanopya::Exceptions;
use Log::Log4perl "get_logger";
use Data::Dumper;

use Entity::Processormodel;
use Entity::Hostmodel;
use Entity::Host;
use Entity::Kernel;
use Entity::Tag;

my $log = get_logger("");
my $errmsg;

use constant BOOT_POLICIES => {
    pxe_nfs      => 'PXE Boot via NFS',
    pxe_iscsi    => 'PXE Boot via ISCSI',
    root_iscsi   => 'Boot on root ISCSI',
    virtual_disk => 'BootOnVirtualDisk',
    boot_on_san  => 'BootOnSan',
    local_disk   => 'BootOnLocalDisk'
};

sub methods {
    return {
        createHost => {
            description => 'create a host',
        },
        removeHost => {
            description => 'remove a host',
        },
        startHost  => {
            description => 'start a host',
        },
        stopHost => {
            description => 'stop a host',
        },
        releaseHost => {
            description => 'release a host',
        },
        getFreeHost => {
            description => 'get an available host',
        },
    };
}

sub getHostManagerParams {
    my ($self, %args) = @_;

    return {};
}

sub checkHostManagerParams {}


=pod
=begin classdoc

@return the manager params definition.

=end classdoc
=cut

sub getManagerParamsDef {
    my ($self, %args) = @_;

    return {};
}


sub createHost {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ "host_core", "host_serial_number", "host_ram" ]);

    my $host = Entity::Host->new(host_manager_id => $self->id, %args);

    # Set initial state to down
    $host->host_state("down:" . time);

    return $host;
}


sub removeHost {
    my ($self, %args) = @_;

    General::checkParams(args  => \%args, required => [ "host" ]);

    # check if host is not active
    # if ($args{host}->active) {
    #     throw Kanopya::Exception::Internal(
    #               error => "Host <" . $args{host}->label . "> is still active"
    #           );
    # }

    # Delete the host from db
    $args{host}->delete();
}


sub startHost {
    my ($self, %args) = @_;

    General::checkParams(args  => \%args, required => [ "host" ]);

    throw Kanopya::Exception::NotImplemented();
}


sub stopHost {
    my ($self, %args) = @_;

    General::checkParams(args  => \%args, required => [ "host" ]);

    throw Kanopya::Exception::NotImplemented();
}


sub getFreeHost {
    my ($self,%args) = @_;

    throw Kanopya::Exception::NotImplemented();
}


sub resubmitHost {
    my ($self, %args) = @_;

    General::checkParams(args  => \%args, required => [ "host" ]);

    return $self->executor_component->run(
        name   => 'ResubmitNode',
        params => {
            context => {
                host => $args{host}
            }
        }
    );
}


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


sub getBootPolicies {
    throw Kanopya::Exception::NotImplemented();
}

sub hostType {
    return "Host";
}

sub getRemoteSessionURL {
    throw Kanopya::Exception::NotImplemented();
}

sub selectHypervisor {
    throw Kanopya::Exception::NotImplemented();
}
1;
