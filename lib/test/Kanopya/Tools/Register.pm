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
#
# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

=pod

=begin classdoc

Kanopya module to handle register actions

@since 13/12/12
@instance hash
@self $self

=end classdoc

=cut

package Kanopya::Tools::Register;

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Kanopya::Exceptions;
use Kanopya::Tools::Retrieve;
use General;
use Entity::Host;
use Entity::ServiceProvider::Cluster;
use Entity::Masterimage;
use Entity::Vlan;
use Harddisk;
use NetconfVlan;

=pod

=begin classdoc

Register an host into kanopya

@param board the host parameters (core, ram, and ifaces detail)

@return boolean

=end classdoc

=cut

sub registerHost {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [ 'board' ]);

    my $board = $args{board};

    my $kanopya_cluster = Kanopya::Tools::Retrieve->retrieveCluster();
    my $physical_hoster = $kanopya_cluster->getHostManager();

    my $host = Entity::Host->new(
                   active             => 1,
                   host_manager_id    => $physical_hoster->id,
                   host_serial_number => $board->{serial_number},
                   host_ram           => $board->{ram},
                   host_core          => $board->{core},
               );

    if (defined $board->{ifaces}) {
        foreach my $iface (@{ $board->{ifaces} }) {
            my $if = $host->addIface(
                         iface_name     => $iface->{name},
                         iface_pxe      => $iface->{pxe},
                         iface_mac_addr => $iface->{mac},
                     );

            if (defined $iface->{master}) {
                $if->setAttr(name => 'master', value => $iface->{master});
                $if->save();
            }
        }
    }

    if (defined ($board->{harddisks})) {
        for my $harddisk (@{$board->{harddisks}}) {
            Harddisk->new(
                host_id         => $host->id,
                harddisk_device => $harddisk->{device},
                harddisk_size   => $harddisk->{size}
            );
        }
    }

    return $host;
}

=pod

=begin classdoc

Register a masterimage into kanopya

@param masterimage_name (unamed argument)

@return masterimage the created masterimage

=end classdoc

=cut

sub registerMasterImage {
    my $name = shift || $ENV{'MASTERIMAGE'} || "centos-6.3-opennebula3.tar.bz2";

    diag('Deploy master image');
    my $deploy = Entity::Masterimage->create(
                     file_path => "/masterimages/" . $name,
                     keep_file => 1
                 );

    Kanopya::Tools::Execution->executeOne(entity => $deploy);

    return Entity::Masterimage->find(hash     => { },
                                     order_by => 'masterimage_id');
}

=pod

=begin classdoc

Register a VLAN into Kanopya

@param netconf network configuration

@param vlan_name name of the VLAN to be registered

@param vlan_number ID of the VLAN to be registered

=end classdoc

=cut

sub registerVlan {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'netconf', 'vlan_name', 'vlan_number' ]);

    my $netconf = $args{netconf};
    my $vlan_name = $args{vlan_name};
    my $vlan_number = $args{vlan_number};

    my $vlan = Entity::Vlan->new(vlan_name => $vlan_name, vlan_number => $vlan_number);
    NetconfVlan->new(netconf_id => $netconf->id, vlan_id => $vlan->id);
}

1;
