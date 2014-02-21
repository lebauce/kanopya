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

=pod
=begin classdoc

TODO

=end classdoc
=cut

package EEntity::EComponent::EOpenstack::ECinder;
use base "EEntity::EComponent";
use base "EManager::EDiskManager";

use strict;
use warnings;

use EEntity;
use Entity::Container::FileContainer;
use Entity::ContainerAccess::IscsiContainerAccess;
use Entity::ContainerAccess::FileContainerAccess;
use Entity::Repository;

my $supported_volume_types = {
    "NFS"   => "Generic_NFS",
    "iSCSI" => "LVM_iSCSI",
    "RADOS" => "RBD"
};


=pod
=begin classdoc

Instruct a cinder instance to create a volume, then trigger the Cinder entity to register
it into Kanopya

@param name the volume name
@param size the volume size

@return a container object

=end classdoc
=cut

sub createDisk {
    my ($self,%args) = @_;

    General::checkParams(args     => \%args,
                         required => [ "name", "size", "cluster" ]);

    my $diskmanagerparams   = $args{cluster}->getManagerParameters(manager_type => 'DiskManager');
    my $exportmanagerparams = $args{cluster}->getManagerParameters(manager_type => 'ExportManager');

    $args{disk_type}           = $diskmanagerparams->{export_type} || 'iSCSI';
    $args{repository}          = $exportmanagerparams->{repository};

    if (defined $args{disk_type} && $args{disk_type} eq 'NFS') {
        General::checkParams(args     => \%args,
                             required => [ 'repository' ]
        );
    }

    my $e_controller = EEntity->new(entity => $self->nova_controller);
    my $api = $e_controller->api;

    my $req = $api->cinder->volumes->post(
                  content => {
                      "volume" => {
                          "name"         => $args{name},
                          "size"         => $args{size} / 1024 / 1024 / 1024,
                          "display_name" => $args{name},
                          'volume_type'  => $args{disk_type}
                      }
                  }
              );

    if (! $req->{volume}) {
        throw Kanopya::Exception::Execution(
                  error => "Failed to create volume of type $args{disk_type} on Cinder"
              );
    }

    my $timeout = 30;
    while (($req->{volume}->{status} eq "creating") && ($timeout > 0)) {
        sleep 5;
        $timeout -= 5;
        $req = $api->cinder->volumes(id => $req->{volume}->{id})->get();
    }

    if ($req->{volume}->{status} ne 'available') {
        my $error = 'Error during cinder volume creation, volume status '.$req->{volume}->{status}.': ';
        if ($req->{volume}->{status} eq 'error') {
            $error .= ' Please check if cinder has enough space to create volume';
        }
        elsif ($req->{volume}->{status} eq 'creating') {
            $error .= ' Time out creation exceeded';
        }
        throw Kanopya::Exception::Execution(error => $error);
    }

    my $container;
    if ($args{disk_type} eq 'iSCSI') {
        $container = $self->lvcreate(
                            volume_id    => $req->{volume}->{id},
                            lvm2_lv_name => $args{name},
                            lvm2_lv_size => $args{size},
			    lvm2_lv_filesystem => $args{filesystem}
                        );
    }
    elsif ($args{disk_type} eq 'NFS') {
        my $container_access_id = Entity::Repository->find(hash => {
            repository_id => $args{repository}
        })->container_access_id;
        $container = Entity::Container::FileContainer->new(
            disk_manager_id      => $self->id,
            container_access_id  => $container_access_id,
            container_name       => $args{name},
            container_size       => $args{size},
            container_filesystem => 'None',
            container_freespace  => 0,
            container_device     => 'volume-' . $req->{volume}->{id}
        );
    }

    return EEntity->new(entity => $container);
}


=pod
=begin classdoc

Register a new iscsi container access into Kanopya

=end classdoc
=cut

sub createExport {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ "container" ] );

    my $export;

    if ($args{container}->isa('EEntity::EContainer::EFileContainer')) {
        my $underlying  = Entity::ContainerAccess->get(
            id => $args{container}->container_access_id
        );
        my $export_name = $underlying->container_access_export . '/' . $args{container}->container_device;
        $export         = Entity::ContainerAccess::FileContainerAccess->new(
            container_id            => $args{container}->id,
            export_manager_id       => $self->id,
            container_access_export => $export_name,
            container_access_ip     => $underlying->container_access_ip,
            container_access_port   => $underlying->container_access_port
        );
    }
    else {
        my $id  = $self->getVolumeId(container => $args{container});
        $export = Entity::ContainerAccess::IscsiContainerAccess->new(
            container_id            => $args{container}->id,
            container_access_export => "iqn.2010-10.org.openstack:volume-" . $id,
            container_access_port   => 3260,
            container_access_ip     => $self->getMasterNode->adminIp,
            export_manager_id       => $self->id,
            typeio                  => "fileio",
            iomode                  => "wb",
            lun_name                => ""
        );
    }

    return EEntity->new(entity => $export);
}

sub removeExport {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ "container_access" ] );

    $args{container_access}->remove();
}

sub addExportClient {
}

sub getLunId {
    return 1;
}

sub postStartNode {
    my ($self , %args) = @_;

    General::checkParams(args => \%args, required => [ 'cluster', 'host' ]);

    my $e_controller = EEntity->new(entity => $self->nova_controller);
    my $api = $e_controller->api;

    for my $type (keys %{$supported_volume_types}) {
        my $req = $api->cinder->types->post(
                      content => {
                          "volume_type" => {
                              "name" => $type,
                          }
                      }
                  );

        my $id = $req->{volume_type}->{id};
        $req = $api->cinder->types(id => $id)->extra_specs->post(
            content => {
                "extra_specs" => {
                    "volume_backend_name" => $supported_volume_types->{$type}
                }
            }
        );
    }
}

1;
