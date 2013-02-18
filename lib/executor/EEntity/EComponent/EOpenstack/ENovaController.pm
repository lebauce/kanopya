#    Copyright © 2013 Hedera Technology SAS
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
package EEntity::EComponent::EOpenstack::ENovaController;

use base "EEntity::EComponent";
use base "EManager::EHostManager::EVirtualMachineManager";

use strict;
use warnings;

use JSON;
use OpenStack::API;

use Log::Log4perl "get_logger";
my $log = get_logger("");

sub api {
    my $self = shift;

    my $credentials = {
        auth => {
            passwordCredentials => {
                username    => "admin",
                password    => "pass"
            },
            tenantName      => "openstack"
        }
    };

    my $keystone = $self->keystone;
    my @glances  = $self->glances;
    my $glance   = shift @glances;
    my @computes = $self->novas_compute;
    my $compute  = shift @computes;
    my @quantums  = $self->quantums;
    my $quantum  = shift @quantums;

    my $config = {
        verify_ssl => 0,
        identity => {
            url     => 'http://' . $keystone->service_provider->getMasterNode->fqdn . ':5000/v2.0'
        },
        image => {
            url     => 'http://' . $glance->service_provider->getMasterNode->fqdn  . ':9292/v1'
        },
        compute => {
            url     => 'http://' . $compute->service_provider->getMasterNode->fqdn . ':8774/v2'
        },
        network => {
            url     => 'http://' . $quantum->service_provider->getMasterNode->fqdn . ':9696/v2.0'
        }
    };

    my $os_api = OpenStack::API->new(
        credentials => $credentials,
        config      => $config,
    );

    return $os_api;
}

sub addNode {
    my ($self, %args) = @_;

    General::checkParams(
        args     => \%args,
        required => [ 'host', 'mount_point', 'cluster' ]
    );
}

sub postStartNode {
    my ($self, %args) = @_;

    General::checkParams(
        args     => \%args,
        required => [ 'cluster', 'host' ]
    );
}

sub registerHypervisor {
    my ($self, %args) = @_;

    General::checkParams(
        args     => \%args,
        required => [ 'host' ]
    );
}

sub unregisterHypervisor {
    my ($self, %args) = @_;

    General::checkParams(
        args     => \%args,
        required => [ 'host' ]
    );
}

sub migrateHost {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ 'host', 'hypervisor_dst', 'hypervisor_cluster' ]);
}

sub getVMState {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args, required => [ 'host' ]);

    return { state => "unknown", hypervisor => undef };
}

sub scaleMemory {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host', 'memory' ]);
}

sub scaleCpu {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host', 'cpu_number' ]);
}

sub halt {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);
}

sub isUp {
    my ($self, %args) = @_;

    General::checkParams(
        args     => \%args,
        required => [ 'cluster', 'host' ]
    );

    return 1;
}

sub startHost {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);

    if (! defined $args{hypervisor}) {
        throw Kanopya::Exception::Internal(error => "No hypervisor available");
    }
}

sub stopHost {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);
}

sub postStart {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);
}

sub applyVLAN {
    my ($self, %args) = @_;

    General::checkParams(
        args     => \%args,
        required => [ 'iface', 'vlan' ]
    );
}

sub checkUp {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ "host" ]);

    return 0;
}

1;
