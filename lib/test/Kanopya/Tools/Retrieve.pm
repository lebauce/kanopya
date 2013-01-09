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

Kanopya module to Retrieve complex entities 

@since 13/12/12
@instance hash
@self $self

=end classdoc

=cut

package Kanopya::Tools::Retrieve;

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Kanopya::Exceptions;
use General;
use Entity::Host;
use Entity::ServiceProvider::Inside::Cluster;
use Entity::Netconf;

=pod

=begin classdoc

Use the BaseDB `find` method to retrieve a cluster from Kanopya
Retrieve kanopya cluster if no criteria are provided

@return entity

=end classdoc

=cut

sub retrieveCluster {
    my ($self, %args) = @_;

    my $kanopya_cluster;

    if (defined $args{criteria}) {
        my $criteria = $args{criteria};

        $kanopya_cluster = Entity::ServiceProvider::Inside::Cluster->find(hash => $criteria);
    }
    else {
        $kanopya_cluster = Entity::ServiceProvider::Inside::Cluster->find(
                               hash => { cluster_name =>  'Kanopya' }
                           );
    }

    return $kanopya_cluster;
}

=pod

=begin classdoc

retrieve a container access from a container name

@return entity

=end classdoc

=cut

sub retrieveContainerAccess {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => ['name', 'type']);

    my $container = Entity::Container->find(hash => {container_name => $args{name}});
    my $container_access;

    if ($args{type} eq 'nfs') {
        my @nfs_accesses = Entity::ContainerAccess::NfsContainerAccess->search(hash => {
                               container_id => $container->id
                           });
        my @nfss = grep {$_->export_manager_id != 0} @nfs_accesses;
        $container_access = $nfss[0];
    }

    return $container_access;
}

=pod

=begin classdoc

Use the BaseDB `find` method to retrieve a netconf from Kanopya

@param criteria the criteria hash for `find` research

@return netconf the network configuration

=end classdoc

=cut

sub retrieveNetconf {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'criteria' ]);
    my $criteria = $args{criteria};

    my $netconf = Entity::Netconf->find(hash => $criteria);

    return $netconf;
}

1;
