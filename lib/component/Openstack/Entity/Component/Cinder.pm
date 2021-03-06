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

=pod
=begin classdoc

TODO

=end classdoc
=cut

package  Entity::Component::Cinder;
use base Entity::Component;
use base Manager::DiskManager;

use strict;
use warnings;

use Entity::Container::LvmContainer;
use Lvm2Lv;
use Lvm2Vg;

use Hash::Merge qw(merge);
use Log::Log4perl "get_logger";
my $log = get_logger("");

use constant ATTR_DEF => {
    executor_component_id => {
        label        => 'Workflow manager',
        type         => 'relation',
        relation     => 'single',
        pattern      => '^[0-9\.]*$',
        is_mandatory => 1,
        is_editable  => 0,
    },
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

sub getNetConf {
    return {
        volume_api => {
            port => 8776,
            protocols => ['tcp']
        }
    };
}

sub diskType {
    return "Cinder";
}

sub exportType {
    return "Cinder";
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
        export_type => {
            label        => 'Backend',
            type         => 'enum',
            is_mandatory => 1,
            options      => [ 'NFS', 'iSCSI', 'RADOS' ]
        },
        repository   => {
            is_mandatory => 1,
            label        => 'Repository',
            type         => 'enum',
        },
    };
}

sub getDiskManagerParams {
    my ($self, %args) = @_;

    return { export_type => $self->getManagerParamsDef->{export_type} };
}

sub getExportManagerParams {
    my ($self, %args) = @_;

    if (defined($args{params}->{export_type}) && $args{params}->{export_type} eq 'NFS') {
        my $repoparam = $self->getManagerParamsDef->{repository};
        $repoparam->{options} = {};

        my @repositories = $self->nova_controller->repositories;
        for my $repository (@repositories) {
            $repoparam->{options}->{$repository->id} = $repository->repository_name;
        }
        return { repository => $repoparam };
    }
    else {
        return {};
    }
}

sub checkExportManagerParams {}

sub getBootPolicyFromExportManager {
    return Manager::HostManager->BOOT_POLICIES->{local_disk};
}

sub getExportManagers {
    my $self = shift;

    return [ $self ];
}

sub getReadOnlyParameter {}

=pod
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
                         required => [ "lvm2_lv_name", "lvm2_lv_size",
			               "volume_id", "lvm2_lv_filesystem" ],
                         optional => { container_device => undef });

    my $cinder_vg = Lvm2Vg->find(hash => { lvm2_vg_name => 'cinder-volumes' });

    my $lv = Lvm2Lv->new(
        lvm2_lv_name       => $args{lvm2_lv_name},
        lvm2_vg_id         => $cinder_vg->id,
        lvm2_lv_freespace  => 0,
        lvm2_lv_size       => $args{lvm2_lv_size},
	lvm2_lv_filesystem => $args{lvm2_lv_filesystem},
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

sub getPuppetDefinition {
    my ($self, %args) = @_;

    my $controller = $self->nova_controller;
    my $name = "cinder-" . $self->id;

    my @repositories = map {
        $_->container_access->container_access_export
    } $controller->repositories;

    return merge($self->SUPER::getPuppetDefinition(%args), {
        cinder => {
            classes => {
                'kanopya::openstack::cinder::server' => {
                    email => $self->getMasterNode->owner->user_email,
                    database_user => $name,
                    database_name => $name,
                    rabbit_user => $name,
                    rabbit_virtualhost => 'openstack-' . $controller->id
                },
                'kanopya::openstack::cinder::iscsi' => {},
                'kanopya::openstack::cinder::nfs' => {
                    nfs_servers => \@repositories
                },
                'kanopya::openstack::cinder::ceph' => {}
            },
            dependencies => $self->getDependentComponents()
        }
    } );
}


=pod
=begin classdoc

Cinder depend on the keystone and amqp of the novacontroller
and its mysql.

=end classdoc
=cut

sub getDependentComponents {
    my ($self, %args) = @_;

    return [ $self->nova_controller->keystone,
             $self->nova_controller->amqp,
             $self->mysql5 ];
}


sub checkConfiguration {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, optional => { 'ignore' => [] });

    for my $attr ("mysql5", "nova_controller") {
        $self->checkAttribute(attribute => $attr);
    }

    for my $attr ("keystone", "amqp") {
        $self->nova_controller->checkAttribute(attribute => $attr);
    }

    $self->SUPER::checkConfiguration(ignore => $args{ignore});
}


=pod
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


=pod
=begin classdoc

Return volume_id for a given container

=end classdoc
=cut

sub getVolumeId {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => ['container']);

    my $volume_id = undef;

    if ($args{container}->isa('Entity::Container::FileContainer')) {
        $volume_id = (split '-', $args{container}->container_device, 2)[1];
    }
    else {
        $volume_id = join('-', (split('--', $args{container}->container_device))[-5..-1]);
    }

    return $volume_id;
}

1;
