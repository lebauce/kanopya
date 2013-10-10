# Copyright 2012 Hedera Technology SAS
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

Execution class for Container. Provides methods for copy of containers.

@since    2012-Feb-29
@instance hash
@self     $self

=end classdoc

=cut

package EEntity::EContainer;
use base "EEntity";

use strict;
use warnings;

use General;
use EEntity;
use Kanopya::Exceptions;
use Entity::Container::LocalContainer;

use Log::Log4perl "get_logger";

my $log = get_logger("");
my $errmsg;


=pod

=begin classdoc

Copy the source container contents to the destination copntainer. To copy a container to another, 
both must be exported, then connected/mounted on the executor and contents copyied.
This method create a container access for both containers with default export manager of each,
then call copy on the container acesses.

@param dest the destination container
@param econtext the econtext object to execute commands

@optional erollback the rollback object to register errors callback

=end classdoc

=cut

sub copy {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'dest', 'econtext' ]);

    my $source_size = $self->container_size;
    my $dest_size   = $args{dest}->container_size;

    # Check if the destination container is not to small.
    if ($dest_size < $source_size) {
        throw Kanopya::Exception::Execution(
                  error => "Source container <$source_size> is larger than the dest container <$dest_size>."
              );
    }

    # When we copy to a loopback of a file on a NFS mountpoint
    # where the server and the client are the same machine
    # we encounter a kernel crash.
    if ($args{dest}->isa("EEntity::EContainer::EFileContainer")) {
        my $eexport_manager = EEntity->new(
                                  entity => $args{dest}->container_access->getExportManager
                              );

        if ($eexport_manager->getEContext->isa("EContext::Local") and
            $eexport_manager->isa("EEntity::EComponent::ENfsd3")) {

            my $mountpoint = $eexport_manager->getMountDir(
                                 device => $args{dest}->container_access->container->container_device
                             );

            my $container = EEntity->new(entity => Entity::Container::LocalContainer->new(
                                container_name       => $args{dest}->container_name,
                                container_size       => $args{dest}->container_size,
                                container_filesystem => $args{dest}->container_filesystem,
                                container_device     => $mountpoint . '/' . $args{dest}->container_device,
                            ));

            my $result = $self->copy(dest => $container, econtext => $args{econtext}, erollback => $args{erollback});

            $container->remove();

            return $result;
        }
    }

    # TODO: copy locally without exporting caontiners if they are
    #       provided by the same disk manager.

    # TODO: use an existing export if exist, and is shared.

    # Get a container access for this container via default method.
    my $source_access = $self->createDefaultExport(erollback => $args{erollback});
    my $dest_access = $args{dest}->createDefaultExport(erollback => $args{erollback});

    # Copy contents with container accesses specific protocols
    $source_access->copy(dest      => $dest_access,
                         econtext  => $args{econtext},
                         erollback => $args{erollback});

    # Remove temporary default exports
    $self->removeDefaultExport(container_access => $source_access,
                               erollback        => $args{erollback});

    $args{dest}->removeDefaultExport(container_access => $dest_access,
                                     erollback        => $args{erollback});
}


=pod

=begin classdoc

Generic method for creating an export of a container usable to copy it.

@optional erollback the rollback object to register errors callback

=end classdoc

=cut

sub createDefaultExport {
    my ($self, %args) = @_;

    my $export_manager = EEntity->new(data => $self->getDefaultExportManager());

    # Temporary export the containers to copy contents
    my $container_access = $export_manager->createExport(
                               container   => $self,
                               export_name => $self->getAttr(name => 'container_name'),
                               erollback   => $args{erollback}
                           );

    return $container_access;
}


=pod

=begin classdoc

Generic method for removing the default export created for the copy

@param container_access the container access to remove
@optional erollback the rollback object to register errors callback

=end classdoc

=cut

sub removeDefaultExport {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'container_access' ]);

    my $export_manager = EEntity->new(data => $self->getDefaultExportManager());

    $export_manager->removeExport(container_access => $args{container_access},
                                  erollback        => $args{erollback});

}


=pod

=begin classdoc

Abstract method to get a default manager to export the container for copy.

=end classdoc

=cut

sub getDefaultExportManager {
    my ($self, %args) = @_;

    throw Kanopya::Exception::NotImplemented();
}

1;
