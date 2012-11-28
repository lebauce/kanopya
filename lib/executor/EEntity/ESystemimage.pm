#    Copyright © 2010-2012 Hedera Technology SAS
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

Excecution class for Systemimage. Here are implemented methods related to
system image creation involving disks creation, disks copies and exports creation.

@since    2011-Oct-15
@instance hash
@self     $self

=end classdoc

=cut

package EEntity::ESystemimage;
use base "EEntity";

use strict;
use warnings;

use General;
use EFactory;
use Entity::Container::LocalContainer;

use Data::Dumper;
use Log::Log4perl "get_logger";

my $log = get_logger("");
my $errmsg;


=pod

=begin classdoc

Get the container corresponding to the masterimage given in parameter, then
call the system image creation method with this container as source container.
This also install component of the masterimage in the created systemimage.

@param masterimage the masterimage to use for system image contents
@param disk_manager the disk manager to use for system image container creation
@param manager_params the parameters to give to the disk manager for disk creation

@optional erollback the erollback object

=end classdoc

=cut

sub createFromMasterimage {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "masterimage", "disk_manager", "manager_params" ],
                         optional => { "erollback" => undef });

    # Create a temporary local container to access to the masterimage file.
    my $master_container = EEntity->new(entity => Entity::Container::LocalContainer->new(
                               container_name       => $args{masterimage}->masterimage_name,
                               container_size       => $args{masterimage}->masterimage_size,
                               # TODO: get this value from masterimage attrs.
                               container_filesystem => 'ext3',
                               container_device     => $args{masterimage}->masterimage_file,
                           ));

    $self->create(src_container => $master_container,
                  disk_manager  => $args{disk_manager},
                  erollback     => $args{erollback},
                  %{ $args{manager_params} });

    # Remove the temporary container
    $master_container->remove();

    foreach my $comp ($args{masterimage}->component_types) {
        $self->_getEntity->installedComponentLinkCreation(component_type_id => $comp->id);
    }
}


=pod

=begin classdoc

Create a systemimage object. Create the disk corresponding to the systemimage with
the given disk manager, could also fill the created disk with an optional source
container contents.

@param disk_manager the disk manager to use for system image container creation

@optional src_container the source container to use for filling created container
@optional systemimage_size the size of the new systemimage if source container not defined
@optional filesystem the filesystem of the new systemimage if source container not defined
@optional erollback the erollback object

=end classdoc

=cut

sub create {
    my $self = shift;
    my %args = @_;
    my $cmd_res;

    General::checkParams(args     => \%args,
                         required => [ 'disk_manager' ],
                         optional => { 'erollback'        => undef,
                                       'src_container'    => undef,
                                       'systemimage_size' => undef,
                                       'filesystem'       => undef, });

    # If the system image is created from a source container, use its
    # container infos to create the new container.
    if (defined $args{src_container}) {
        $args{systemimage_size} = $args{src_container}->container_size;
        $args{filesystem}       = $args{src_container}->container_filesystem;
    }

    $log->debug('Container creation for new systemimage');

    # Creation of the device based on distribution device
    my $container = $args{disk_manager}->createDisk(
                        name       => $self->systemimage_name,
                        size       => $args{systemimage_size},
                        filesystem => $args{filesystem},
                        erollback  => $args{erollback},
                        %args
                    );

    # Copy of distribution data to systemimage devices
    $log->debug('Fill the container with source data for new systemimage');
    if ($args{src_container}) {
        $args{src_container}->copy(dest      => $container,
                                   econtext  => $self->getExecutorEContext,
                                   erollback => $args{erollback});
    }

    $self->setAttr(name => "container_id", value => $container->id);
    $self->setAttr(name => "active", value => 0);
    $self->save();

    $log->info('System image <' . $self->systemimage_name . '> creation complete');

    return $self->id;
}


=pod

=begin classdoc

Export the system image with the export manager given in paramaters.

@param export_manager the export manager to use for exporting the system image container
@param manager_params the parameters to give to the export manager for disk export

@optional erollback the erollback object

=end classdoc

=cut

sub activate {
    my $self = shift;

    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "export_manager", "manager_params", "erollback" ]);

    my $container = EFactory::newEEntity(data => $self->getDevice());

    $args{export_manager}->createExport(container   => $container,
                                        export_name => self->systemimage_name,
                                        erollback   => $args{erollback},
                                        %{$args{manager_params}});

    # Set system image active in db
    $self->setAttr(name => 'active', value => 1);
    $self->save();

    $log->info("System image <" . $self->systemimage_name . "> is now active");
}


=pod

=begin classdoc

Remove all export of the system image container.

@optional erollback the erollback object

=end classdoc

=cut

sub deactivate {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "erollback" ]);

    # Get instances of container accesses from systemimages root container
    $log->info("Remove all container accesses");
    eval {
        for my $container_access (@{ $self->_getEntity->getDevice->getAccesses }) {
            my $export_manager = EFactory::newEEntity(data => $container_access->getExportManager);
            $container_access  = EFactory::newEEntity(data => $container_access);

            $export_manager->removeExport(container_access => $container_access,
                                          erollback        => $args{erollback});
        }
    };
    if($@) {
        throw Kanopya::Exception::Internal::WrongValue(error => $@);
    }

    # Set system image active in db
    $self->setAttr(name => 'active', value => 0);
    $self->save();

    $log->info("System image <" . $self->systemimage_name . "> is now unactive");
}


=pod

=begin classdoc

Remove the system image, also deactivate it if active.

@optional erollback the erollback object

=end classdoc

=cut

sub remove {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "erollback" ]);

    if ($self->active) {
        $self->deactivate(erollback => $args{erollback});
    }

    my $container;
    eval {
        $container = EFactory::newEEntity(data => $self->getDevice);

        # Remove system image container.
        $log->info("Systemimage container deletion");

        # Get the disk manager of the current container
        my $disk_manager = EFactory::newEEntity(data => $container->getDiskManager);
        $disk_manager->removeDisk(container => $container);
    };
    if($@) {
        $log->info("Unable to remove container while removing cluster:\n" . $@);
    }

    $self->delete();
}

1;
