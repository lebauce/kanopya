#    Copyright © 2013 Hedera Technology SAS
#
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

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

package  Entity::Component::Openstack::Cinder;
use base "Entity::Component";
use base "Manager::DiskManager";

use strict;
use warnings;

use Entity::Container::LvmContainer;
use Entity::Component::Lvm2::Lvm2Lv;
use Entity::Component::Lvm2::Lvm2Vg;

use Hash::Merge qw(merge);
use Log::Log4perl "get_logger";
my $log = get_logger("");

use constant ATTR_DEF => {
    mysql5_id => {
        label        => 'Database server',
        type         => 'relation',
        relation     => 'single',
        pattern      => '^\d*$',
        is_mandatory => 0,
        is_editable  => 1,
    },
    nova_controller_id => {
        label        => 'Openstack controller',
        type         => 'relation',
        relation     => 'single',
        pattern      => '^\d*$',
        is_mandatory => 0,
        is_editable  => 1,
    },
    disk_type => {
        is_virtual => 1
    },
    export_type => {
       is_virtual => 1
    }
};

sub getAttrDef { return ATTR_DEF; }

sub diskType {
    return "LVM logical volume";
}

sub exportType {
    return "ISCSI target";
}

sub getExportManagerParams {
    return { };
}

sub getBootPolicyFromExportManager {
    return Manager::HostManager->BOOT_POLICIES->{pxe_iscsi};
}

sub getExportManagers {
    my $self = shift;

    return [ $self ];
}

sub getReadOnlyParameter {
}

sub checkExportManagerParams {
}

=head 2

=begin classdoc
Register a new logical volume into Kanopya (Lvm2Lv and LvmContainer)

@param lvm2_lv_name the name of the logical volume
@param lv2_lv_size the size of the logical volume
@param volume_id the cinder id of the newly created volume

@return the newly created lvmcontainer object

=end classdoc

=cut

sub lvcreate {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ "lvm2_lv_name", "lvm2_lv_size", "volume_id" ],
                         optional => { container_device => undef });

    my $cinder_vg = Entity::Component::Lvm2::Lvm2Vg->find(hash => { lvm2_vg_name => 'cinder-volumes' });

    my $lv = Entity::Component::Lvm2::Lvm2Lv->new(
        lvm2_lv_name       => $args{lvm2_lv_name},
        lvm2_vg_id         => $cinder_vg->id,
        lvm2_lv_freespace  => 0,
        lvm2_lv_size       => $args{lvm2_lv_size},
    );

    $args{volume_id} =~ s/\-/\-\-/g;
    my $container_device = '/dev/mapper/cinder--volumes-volume--' . $args{volume_id};

    my $container = Entity::Container::LvmContainer->new(
                        disk_manager_id      => $self->id,
                        container_name       => $lv->lvm2_lv_name, 
                        container_size       => $args{lvm2_lv_size}, 
                        container_freespace  => 0,
                        container_device     => $container_device,
                        lv_id                => $lv->id 
                    );

    return $container;

}

=head2

=begin classdoc
Generate component manifest

@return content of the Cinder puppet manifest

=end classdoc

=cut

sub getPuppetDefinition {
    my ($self, %args) = @_;

    my $amqp = $self->nova_controller->amqp->getMasterNode->fqdn;
    my $sql  = $self->mysql5;
    my $controller = $self->nova_controller;
    my $keystone = $controller->keystone;
    my $name = "cinder-" . $self->id;

    my @repositories = map {
        $_->container_access->container_access_export
    } $controller->repositories;

    my $manifest = $self->instanciatePuppetResource(
        name   => 'kanopya::openstack::cinder',
        params => {
            amqpserver => $amqp,
            rabbits => [ $amqp, $amqp ],
            dbserver => $sql->getMasterNode->fqdn,
            keystone => $keystone->getMasterNode->fqdn,
            email => $self->service_provider->user->user_email,
            database_user => $name,
            database_name => $name,
            rabbit_user => $name,
            rabbit_virtualhost => 'openstack-' . $self->nova_controller->id
        }
    );

    $manifest .= $self->instanciatePuppetResource(
        name => 'kanopya::openstack::cinder::iscsi'
    );

    $manifest .= $self->instanciatePuppetResource(
        name => 'kanopya::openstack::cinder::nfs',
        params => {
            nfs_servers => \@repositories
        }
    );

    return merge($self->SUPER::getPuppetDefinition(%args), {
        cinder => {
            manifest     => $manifest,
            dependencies => [ $self->nova_controller->amqp , $sql , $keystone ]
        }
    } );
}

sub getHostsEntries {
    my $self = shift;

    my @entries = ($self->nova_controller->keystone->service_provider->getHostEntries(),
                   $self->nova_controller->amqp->service_provider->getHostEntries(),
                   $self->mysql5->service_provider->getHostEntries());

    return \@entries;
}

=head

=begin classdoc
Implement createDisk from DiskManager interface.
This function enqueue a ECreateDisk operation.

@param vg_id id of the vg from which the disk must be created
@param name name of the disk to be created
@param size size of the disk to be created

=end classdoc

=cut

sub createDisk {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ "name", "size" ]);

    $self->SUPER::createDisk(%args);
}

1;
