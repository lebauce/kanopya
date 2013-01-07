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
use General;
use Entity::Host;
use Entity::ServiceProvider::Inside::Cluster;
use Entity::Masterimage;

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

    my $kanopya_cluster = Entity::ServiceProvider::Inside::Cluster->find(
                              hash => {
                                  cluster_name => 'Kanopya'
                              }
                          );

    my $physical_hoster = $kanopya_cluster->getHostManager();

    my $host = Entity::Host->new(
                   active             => 1,
                   host_manager_id    => $physical_hoster->id,
                   host_serial_number => '123',
                   host_ram           => $board->{ram} * 1024 * 1024,
                   host_core          => $board->{core},
               );

    if (defined $board->{ifaces}) {
        foreach my $iface (@{ $board->{ifaces} }) {
            my $if_id = $host->addIface(
                            iface_name     => $iface->{name},
                            iface_pxe      => $iface->{pxe},
                            iface_mac_addr => $iface->{mac},
                        );

            if (defined $iface->{master}) {
                my $if = Entity::Iface->get(id => $if_id);
                $if->setAttr(name => 'master', value => $iface->{master});
                $if->save();
            }
        }
    }

    return $host;
}

sub registerMasterImage {
    my $name = shift || $ENV{'MASTERIMAGE'} || "centos-6.3-opennebula3.tar.bz2";

    diag('Deploy master image');
    my $deploy = Entity::Operation->enqueue(
                  priority => 200,
                  type     => 'DeployMasterimage',
                  params   => { file_path => "/masterimages/" . $name,
                                keep_file => 1 },
    );

    Kanopya::Tools::Execution->executeOne(entity => $deploy);

    return Entity::Masterimage->find(hash     => { },
                                     order_by => 'masterimage_id');
}

1;
