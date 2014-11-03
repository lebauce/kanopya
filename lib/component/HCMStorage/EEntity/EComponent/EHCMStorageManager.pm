# Copyright © 2012-2013 Hedera Technology SAS
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

HCM native storage manager. Create system images for nodes from disk and export managers.

=end classdoc
=cut

package EEntity::EComponent::EHCMStorageManager;
use base "EEntity::EComponent";
use base "EManager";

use strict;
use warnings;

use Kanopya::Exceptions;
use Entity::Systemimage;
use Entity::Component;
use EEntity;

use TryCatch;
use Log::Log4perl "get_logger";

my $log = get_logger("");


=pod
=begin classdoc

Create a system image for a node.
Create a disk from the disk manager given in parameter, fill it with the masterimage contents,
and and export the disk from the export manager given in parameter.

Should fill the systemimage with the masterimage contents if defined.

@see <package>Manager::StorageManager</package>

=end classdoc
=cut

sub createSystemImage {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ "systemimage_name", "disk_manager_id", "export_manager_id",
                                       "systemimage_size" ],
                         optional => { "systemimage_desc" => "", "masterimage" => undef,
                                       "erollback" => undef, "econtext"=> $self->getEContext });

    my $systemimage = EEntity->new(data => Entity::Systemimage->new(
                          systemimage_name   => $args{systemimage_name},
                          systemimage_desc   => $args{systemimage_desc},
                          storage_manager_id => $self->id
                      ));

    # Creation of the device based on distribution device
    my $disk_manager = Entity::Component->get(id => $args{disk_manager_id});
    my $container = EEntity->new(entity => $disk_manager)->createDisk(
                        name       => $systemimage->systemimage_name,
                        size       => $args{systemimage_size},
                        # TODO: get this value from masterimage attrs.
                        filesystem => 'ext3',
                        %args
                    );

    if (defined $args{masterimage}) {
        $log->debug('Container creation for new systemimage');

        # TODO (kpouget): Check for unsupported masterimage type

        # Create a temporary local container to access to the masterimage file.
        my $master_container = EEntity->new(entity => Entity::Container::LocalContainer->new(
                                   container_name       => $args{masterimage}->masterimage_name,
                                   container_size       => $args{masterimage}->masterimage_size,
                                   # TODO: get this value from masterimage attrs.
                                   container_filesystem => 'ext3',
                                   container_device     => $args{masterimage}->masterimage_file,
                               ));

        # Copy the masterimage container contents to the new container
        $master_container->copy(dest      => $container,
                                econtext  => $args{econtext},
                                erollback => $args{erollback});

        # Remove the temporary container
        $master_container->remove();

        foreach my $comp ($args{masterimage}->component_types) {
            $systemimage->installedComponentLinkCreation(component_type_id => $comp->id);
        }
        $log->info('System image <' . $systemimage->label . '> creation complete');
    }

    # Export system image for node if required.
    if (not $systemimage->active) {
        my $export_manager = Entity::Component->get(id => $args{export_manager_id});

        # Creation of the export to access to the system image container
        my @accesses;
        my $portals = defined $args{iscsi_portals} ? delete $args{iscsi_portals} : [ 0 ];
        for my $portal_id (@{ $portals }) {
            try {
                push @accesses, EEntity->new(entity => $export_manager)->createExport(
                                    export_name  => $systemimage->systemimage_name,
                                    container    => $container,
                                    iscsi_portal => $portal_id,
                                    %args
                                );
            }
            catch ($err) {
                if (scalar(@accesses)) {
                    $log->error("Exporting systemimage with portal <$portal_id> failed, but at least one " .
                                "export for systemimage " . $systemimage->label . " succeeded, " .
                                "continuing...");
                }
                else {
                    $err->rethrow();
                }
            }

        }

        # Link the systemimage with its accesses
        $systemimage->update(systemimage_container_accesses => \@accesses);
        # Set system image active
        $systemimage->active(1);

        $log->info("System image <" . $systemimage->label . "> is now active");
    }
    return $systemimage;
}


=pod
=begin classdoc

Remove the system image, also deactivate it if active.

@optional erollback the erollback object

=end classdoc
=cut

sub removeSystemImage {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "systemimage" ],
                         optional => { "erollback" => undef });

    # Get the container before removing the container_access
    my $container;
    try {
       $container = EEntity->new(data => $args{systemimage}->getContainer);
    }
    catch (Kanopya::Exception::Internal::NotFound $err) {
        # No export found for this system image
        # TODO: is a container for this system image still exists ?
    }
    catch ($err) {
        $err->rethrow();
    }

    if ($args{systemimage}->active) {
        # Get instances of container accesses from systemimages root container
        $log->info("Remove all container accesses");
        try {
            my @accesses = map { EEntity->new(data => $_) } $args{systemimage}->container_accesses;
            for my $container_access (@accesses) {
                my $export_manager = EEntity->new(data => $container_access->export_manager);

                $export_manager->removeExport(container_access => $container_access,
                                              erollback        => $args{erollback});
            }
        }
        catch ($err) {
            throw Kanopya::Exception::Internal::WrongValue(error => $err);
        }
    }

    if (defined $container) {
        try {
            # Remove system image container.
            $log->info("Systemimage container deletion");

            # Get the disk manager of the current container
            my $disk_manager = EEntity->new(data => $container->getDiskManager);
            $disk_manager->removeDisk(container => $container);
        }
        catch ($err) {
            $log->warn("Unable to remove container while removing system image:\n$err");
        }
    }

    $args{systemimage}->delete();
}


=pod
=begin classdoc

Mount the systemimage filesystem on the given mount point.

@return the mount point where is mounted the systemimage

@see <package>Manager::StorageManager</package>

=end classdoc
=cut

sub mountSystemImage {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ "systemimage" ],
                         optional => { "econtext" => $self->getEContext });

    my $container_access = $self->_findContainerAccess(systemimage => $args{systemimage});

    # Mount the containers on the executor.
    $log->info("Mounting the container access <" . $container_access->label . ">");
    return $container_access->mount(econtext => $args{econtext}, erollback => $args{erollback});
}


=pod
=begin classdoc

Unount the systemimage filesystem by umounting the container access previously mounted.

@return the mount point where is mounted the systemimage

@see <package>Manager::StorageManager</package>

=end classdoc
=cut

sub umountSystemImage {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ "systemimage" ],
                         optional => { "econtext" => $self->getEContext });

    my $container_access = $self->_findContainerAccess(systemimage => $args{systemimage});

    $log->info("Unmounting the container access <" . $container_access->label . ">");
    return $container_access->umount(econtext => $args{econtext}, erollback => $args{erollback});
}


=pod
=begin classdoc

Find a container access to mount the system image filesystem

@return the container access

=end classdoc
=cut

sub _findContainerAccess {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ "systemimage" ]);

    # Use the first systemimage container access found, as all should access to the same container.
    my @accesses = $args{systemimage}->container_accesses;

    # Sort by id to ensure poping the same container access each time
    @accesses = sort { $a->id <=> $b->id } @accesses;
    return EEntity->new(entity => pop(@accesses));
}

1;
