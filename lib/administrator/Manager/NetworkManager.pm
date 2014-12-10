# Copyright © 2014 Hedera Technology SAS
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

The network manager is an insterface that components must to implement
to provides network configuration for nodes of a service provider.

@since    2014-Aug-13
@instance hash
@self     $self

=end classdoc
=cut

package Manager::NetworkManager;
use parent Manager;

use strict;
use warnings;

use Entity::Netconf;
use Entity::Component;
use Kanopya::Exceptions;

use TryCatch;
use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");


sub methods {
    return {
        configureNetworkInterfaces => {
            description => 'configure the network connectivity for the node',
        },
        applyVLAN => {
            description => 'apply the vlan configuration for the node',
        },
    };
}


=pod
=begin classdoc

@return the manager params definition.

=end classdoc
=cut

sub getManagerParamsDef {
    my ($self, %args) = @_;

    return {
        # TODO: call super on all Manager supers
        %{ $self->SUPER::getManagerParamsDef },
        interfaces => {
            label        => 'Interfaces',
            type         => 'relation',
            relation     => 'single_multi',
            is_editable  => 1,
            is_mandatory => 1,
            description  => 'They are the different network interfaces',
            attributes   => {
                attributes => {
                    policy_id => {
                        type        => 'relation',
                        relation    => 'single',
                        description => 'It is the original network policy used to '.
                                       'generate the network configuration',
                    },
                    netconfs => {
                        label       => 'Network configurations',
                        type        => 'relation',
                        relation    => 'multi',
                        link_to     => 'netconf',
                        pattern     => '^\d*$',
                        is_editable => 1,
                        description => 'They are the differents network topologies plug'.
                                       ' on this network interface',
                    },
                    bonds_number => {
                        label       => 'Bonding slave count',
                        type        => 'integer',
                        pattern     => '^\d*$',
                        is_editable => 1,
                        description	=> 'It is the bond id',
                    },
                    interface_name => {
                        label        => 'Name',
                        type         => 'string',
                        pattern      => '^.*$',
                        is_editable  => 1,
                        is_mandatory => 1,
                        description  => 'It is the name of the net interface on operating side',
                    },
                },
            },
        }
    };
}


=pod
=begin classdoc

Do the required configuration/actions to provides the proper network connectivity
to the node from the network manager params.

=end classdoc
=cut

sub configureNetworkInterfaces {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ "node", "interfaces" ]);

    # If the node linked to a host, configure the network connectivity
    # TODO: Manage network connectivity on node instead of host.
    if (defined $args{node}->host) {
        # Set the ifaces netconf according to the cluster interfaces
        # We consider that the available ifaces match the cluster
        # interfaces since getFreeHost selection done.
        foreach my $interface (values %{ $args{interfaces} }) {
            # Validate the interface param pattern
            try {
                General::checkParams(args     => $interface,
                                     required => [ "interface_name" ],
                                     optional => { netconfs => {} });
            }
            catch ($err) {
                throw Kanopya::Exception::Internal::Inconsistency(
                          error => "Malformed manager param <interface>: $err"
                      );
            }

            # Firstly find the corresponding iface from name
            my $iface = $args{node}->host->find(related => 'ifaces',
                                                hash    => { iface_name => $interface->{interface_name} });

            # Set the related netconfs
            my @netconfs = map { Entity::Netconf->get(id => $_) } values %{ $interface->{netconfs} };

            $log->info("Configure iface " . $iface->iface_name . " with netconfs " . join(', ', @netconfs));
            $iface->update(netconf_ifaces => \@netconfs, override_relations => 1);
        }
    }

    $log->info("Assign ips to the node network interfaces");

    # Search for any load balanced component on the node
    my $is_loadbalanced = $args{node}->isLoadBalanced;
    # Search for any component master node
    my $is_masternode = (scalar(grep { $_->master_node } $args{node}->component_nodes) > 0);

    IFACE:
    foreach my $iface (@{ $args{node}->host->getIfaces }) {
        # Handle associated ifaces only
        if ($iface->netconfs) {
            # Public network on loadbalanced component node must be configured only
            # on the master node
            if ($iface->hasRole(role => 'public') and $is_loadbalanced and not $is_masternode) {
                $log->info("Skipping interface " . $iface->iface_name);
                next IFACE;
            }

            # Assign ip from the associated interface poolip
            $iface->assignIp();

            # Apply VLAN's
            for my $netconf ($iface->netconfs) {
                for my $vlan ($netconf->vlans) {
                    $log->info("Apply VLAN on " . $iface->iface_name);
                    $self->applyVLAN(iface => $iface, vlan => $vlan);
                }
            }
        }
        else {
            $log->info("Skipping interface " . $iface->iface_name . ", no associated netconfs");
        }
    }
}


=pod
=begin classdoc

Do the required configuration/actions to configure the vlan connectivity
for a network interface of a node

=end classdoc
=cut

sub applyVLAN {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'iface', 'vlan' ]);

    throw Kanopya::Exception::NotImplemented();
}


=pod
=begin classdoc

Check params required for managing network connectivity.

=end classdoc
=cut

sub checkNetworkManagerParams {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ "interfaces" ]);
}


=pod
=begin classdoc

Remove the network manager params entry from a hash ref.

=end classdoc
=cut

sub releaseNetworkManagerParams {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ "params" ]);

    delete $args{params}->{interfaces};
}


sub unconfigureNetworkInterface {
    my ($self, %args) = @_;
}

=pod
=begin classdoc

@return the network manager parameters as an attribute definition.

=end classdoc
=cut

sub getNetworkManagerParams {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, optional => { "params" => {} });

    my $paramdef = $self->getManagerParamsDef();

    my @netconfs;
    for my $netconf (Entity::Netconf->search(hash => {})) {
        push @netconfs, $netconf->toJSON();
    }

    $paramdef->{interfaces}->{attributes}->{attributes}->{netconfs}->{options}
        = \@netconfs;

    return $paramdef;
}

1;
