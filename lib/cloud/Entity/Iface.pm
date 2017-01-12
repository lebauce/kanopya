
# Copyright © 2011 Hedera Technology SAS
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

package Entity::Iface;
use base "Entity";

use Kanopya::Exceptions;
use Entity::Poolip;
use Ip;

use Log::Log4perl "get_logger";
use Data::Dumper;
use TryCatch;

my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    iface_name => {
        label        => 'Interface name',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1,
        description  => 'The name of the interface in your Linux system (eg. "eth0")',
    },
    iface_mac_addr => {
        label        => 'MAC address',
        type         => 'string',
        pattern      => '^[0-9a-fA-F]{2}:[0-9a-fA-F]{2}:[0-9a-fA-F]{2}:' .
                        '[0-9a-fA-F]{2}:[0-9a-fA-F]{2}:[0-9a-fA-F]{2}$',
        is_mandatory => 0,
        is_editable  => 1,
        description  => 'The MAC address of your network interface. It is essential for the PXE'.
                        ' interface, as it will be included in GRUB and DHCP configurations',
    },
    iface_pxe => {
        label        => 'PXE enabled',
        type         => 'boolean',
        pattern      => '^[01]$',
        is_mandatory => 1,
        is_editable  => 1,
        description  => 'Will this interface be used to boot through PXE?',
    },
    host_id => {
        type         => 'relation',
        relation     => 'single',
        pattern      => '^\d+$',
        is_mandatory => 1,
        description  => 'The host identifier of the server with this network interface',
    },
    master => {
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 0,
        is_editable  => 1,
        description  => 'You can specify which interface is the master in a bonding configuration.'.
                        ' It is also used for routing.',
    },
    netconf_ifaces => {
        label        => 'Network configurations',
        type         => 'relation',
        relation     => 'multi',
        link_to      => 'netconf',
        is_mandatory => 0,
        is_editable  => 1,
        description => 'Choose the network topology plugged on this interface.',
    }
};

sub getAttrDef { return ATTR_DEF; }


sub assignIp {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, optonal => { 'ip_addr' => undef });

    my $ip;
    if (! defined $args{ip_addr}) {
        my @netconfs = $self->netconfs;
        $log->debug("Browse " . scalar(@netconfs) . " netconfs to search poolips");

        # Loop over all network configurations, and assign ip to ifaces
        # for each network.
        NETCONFS:
        for my $netconf (@netconfs) {
            my @poolips = $netconf->poolips;
            $log->debug("Netconf " . $netconf->label . ", try to pop an ip from " .
                        scalar(@poolips) . " poolip");

            if (scalar(@poolips)) {
                POOLIPS:
                for my $poolip (@poolips) {
                    # Try to pop an ip from the current pool
                    try {
                        $ip = $poolip->popIp();
                    }
                    catch ($err) {
                        $log->error("Cannot pop IP from pool <" . $poolip->poolip_name . ">\n$err");
                        next POOLIPS;
                    }

                    # Assign the ip to the iface
                    $ip->iface_id($self->id);

                    $log->info("Ip " . $ip->ip_addr . " assigned to iface ". $self->iface_name);

                    # TODO: handle multiple ip on one iface.
                    last NETCONFS;
                }
                # No free ip found
                throw Kanopya::Exception::Internal::NotFound(
                          error => "Unable to assign ip to iface <" . $self->iface_name . ">"
                      );
            }
            else {
                $log->warn("No poolip found, skipping netconf <" . $netconf->label . ">");
            }
        }
    }
    else {
        $log->info("Creating ip from fixed address <$args{ip_addr}>");
        $ip = Ip->new(ip_addr => $args{ip_addr}, iface_id => $self->id);
    }

    return $ip;
}

sub hasIp {
    my $self = shift;
    my %args = @_;

    return scalar($self->ips);
}

sub getIPAddr {
    my ($self, %args) = @_;

    my $ip;
    try {
        # TODO: handle multiple IP by Iface.
        $ip = Ip->find(hash => { iface_id => $self->id });
    }
    catch {
        throw Kanopya::Exception::Internal::NotFound(
                  error => "Iface " . $self->iface_name . " not associated to any IP."
              );
    }
    return $ip->ip_addr;
}

sub getPoolip {
    my ($self, %args) = @_;

    my $ip;
    try {
        # TODO: handle multiple IP by Iface.
        $ip = Ip->find(hash => { iface_id => $self->id });
    }
    catch {
        throw Kanopya::Exception::Internal::NotFound(
                  error => "Iface " . $self->iface_name . " not associated to any IP."
              );
    }
    return $ip->poolip;
}


sub hasRole {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'role' ]);

    my @roles = map { $_->netconf_role ? $_->netconf_role->netconf_role_name : '' } $self->netconfs;

    return scalar grep { $_ eq $args{role} } @roles;
}

sub getVlans {
    my ($self, %args) = @_;

    my @vlans = ();
    for my $netconf ($self->netconfs) {
        @vlans = (@vlans, $netconf->vlans);
    }
    return @vlans;
}

sub networks {
    my $self = shift;

    my @networks;
    for my $netconf ($self->netconfs) {
        for my $poolip ($netconf->poolips) {
            push @networks, $poolip->network;
        }
    }
    return @networks;
}

sub slaves {
    my ($self, %args) = @_;

    my @slaves = grep { $_->master eq $self->iface_name } $self->host->ifaces;

    return wantarray ? @slaves : \@slaves;
}

1;
