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

package Entity::Component::Fileimagemanager0;
use base "Entity::Component";
use base "Manager::ExportManager";
use base "Manager::DiskManager";

use strict;
use warnings;

use Entity::Container::FileContainer;
use Entity::ContainerAccess::FileContainerAccess;
use Entity::ContainerAccess;
use Entity::ServiceProvider;

use Manager::HostManager;
use Kanopya::Exceptions;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    image_type => {
        pattern      => '^img|vmdk|qcow2$',
        is_mandatory => 0,
        is_extended  => 0
    },
    disk_type => {
        is_virtual => 1
    },
    export_type => {
        is_virtual => 1
    }
};

sub getAttrDef { return ATTR_DEF; }

sub exportType {
    return "NFS repository";
}

sub diskType {
    return "Virtual machine disk";
}

=head2 checkDiskManagerParams

=cut

sub checkDiskManagerParams {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => [ "container_access_id", "systemimage_size" ]);
}


=pod

=begin classdoc

@return the managers parameters as an attribute definition. 

=end classdoc

=cut

sub getDiskManagerParams {
    my $self = shift;
    my %args  = @_;

    my $accesses = {};
    for my $access (@{ $self->getConf->{container_accesses} }) {
        $accesses->{$access->{container_access_id}} = $access->{container_access_name};
    }

    return {
        container_access_id => {
            label        => 'NFS repository to use',
            type         => 'enum',
            is_mandatory => 1,
            options      => $accesses
        },
        image_type => {
            label        => 'Disk image format',
            type         => 'enum',
            is_mandatory => 1,
            options      => [ "raw", "qcow2", "VMDK" ]
        },
    };
}

sub getConf {
    my $self = shift;
    my $conf = {};
    my @access_hashes = ();

    eval {
        my $iaas = $self->service_provider->getComponent(category => 'HostManager');
        for my $repository ($iaas->repositories) {
            my $container_access = $repository->container_access;
            push @access_hashes, {
                container_access_id   => $container_access->id,
                container_access_name => $container_access->container_access_export,
            }
        }
    };

    $conf->{container_accesses} = \@access_hashes;
    return $conf;
}

sub setConf {}

sub getExportManagerFromBootPolicy {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "boot_policy" ]);

    if ($args{boot_policy} eq Manager::HostManager->BOOT_POLICIES->{virtual_disk}) {
        return $self;
    }

    throw Kanopya::Exception::Internal::UnknownCategory(
              error => "Unsupported boot policy: $args{boot_policy}"
          );
}

sub getBootPolicyFromExportManager {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "export_manager" ]);

    my $cluster = Entity::ServiceProvider->get(id => $self->getAttr(name => 'service_provider_id'));

    if ($args{export_manager}->getId == $self->getId) {
        return Manager::HostManager->BOOT_POLICIES->{virtual_disk};
    }

    throw Kanopya::Exception::Internal::UnknownCategory(
              error => "Unsupported export manager:" . $args{export_manager}
          );
}

sub getExportManagers {
    my $self = shift;
    my %args = @_;

    return [ $self ];
}

sub getReadOnlyParameter {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'readonly' ]);
    
    return undef;
}

=head2 createDisk

    Desc : Implement createDisk from DiskManager interface.
           This function enqueue a ECreateDisk operation.
    args :

=cut

sub createDisk {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "container_access", "name", "size", "filesystem" ]);

    $log->debug("New Operation CreateDisk with attrs : " . %args);
    $self->service_provider->getManager(manager_type => 'ExecutionManager')->enqueue(
        type     => 'CreateDisk',
        params   => {
            name                => $args{name},
            size                => $args{size},
            filesystem          => $args{filesystem},
            vg_id               => $args{vg_id},
            container_access_id => $args{container_access}->id,
            context             => {
                disk_manager => $self,
            }
        },
    );
}

=head2 getFreeSpace

    Desc : Implement getFreeSpace from DiskManager interface.
           This function return the free space on the volume group.
    args :

=cut

sub getFreeSpace {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "container_access_id" ]);

    my $container_access = Entity::ContainerAccess->get(id => $args{container_access_id});

    return $container_access->getContainer->getAttr(name => 'container_freespace');
}


=head2 createExport

    Desc : Implement createExport from ExportManager interface.
           This function enqueue a ECreateExport operation.
    args : export_name, device, typeio, iomode

=cut

sub createExport {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "container", "export_name" ]);

    $log->debug("New Operation CreateExport with attrs : " . %args);
    $self->service_provider->getManager(manager_type => 'ExecutionManager')->enqueue(
        type     => 'CreateExport',
        params   => {
            context => {
                export_manager => $self,
                container      => $args{container},
            },
            manager_params => {
                export_name    => $args{export_name},
            },
        },
    );
}

sub getPuppetDefinition {
    my ($self, %args) = @_;

    return {
        manifest     => "class { 'kanopya::fileimagemanager': }\n",
        dependencies => []
    };
}

1;
