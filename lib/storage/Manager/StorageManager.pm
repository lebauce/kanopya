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

Storage management interface. Storage managers must implement this interface
to provides system images to the nodes.
Storage managers build system images from masterimages, link them to the nodes
to allow them to boot from the system images, could also mount and umount them
to allow the deployment manager to configure the components on the filesystem.

@since    2014-Jul-25
@instance hash
@self     $self

=end classdoc
=cut

package Manager::StorageManager;
use parent Manager;

use strict;
use warnings;

use Kanopya::Exceptions;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");


sub methods {
    return {
        createSystemImage => {
            description => 'create a system image disk',
        },
        removeSystemImage => {
            description => 'remove a system image disk',
        },
        attachSystemImage => {
            description => 'attach the systemimage to a node',
        },
        mountSystemImage => {
            description => 'mount the system image',
        },
        umountSystemImage => {
            description => 'unmount the system image',
        },
    };
}


=pod
=begin classdoc

Create a system image for a node.
Should fill the systemimage with the masterimage contents if defined.

=end classdoc
=cut

sub createSystemImage {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ "systemimage_name" ],
                         optional => { "systemimage_desc" => "",
                                       "masterimage"      => undef });

    throw Kanopya::Exception::NotImplemented();
}


=pod
=begin classdoc

Remove a system image from the storage system.

=end classdoc
=cut

sub removeSystemImage {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ "systemimage" ]);

    throw Kanopya::Exception::NotImplemented();
}


=pod
=begin classdoc

Do required struff for giving access for the node to the systemimage.

=end classdoc
=cut

sub attachSystemImage {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ "node", "systemimage" ]);

    throw Kanopya::Exception::NotImplemented();
}


=pod
=begin classdoc

Mount the systemimage filesystem on the given mount point.

@return the mount point where is mounted the systemimage
=end classdoc
=cut

sub mountSystemImage {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ "systemimage" ]);

    throw Kanopya::Exception::NotImplemented();
}


=pod
=begin classdoc

Unmount the systemimage filesystem.

=end classdoc
=cut

sub umountSystemImage {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ "systemimage" ]);

    throw Kanopya::Exception::NotImplemented();
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
        systemimage_size => {
            label        => 'System image size',
            type         => 'integer',
            unit         => 'byte',
            pattern      => '^\d*$',
            is_mandatory => 0,
	    description  => 'The size of the system image (seen by the Storage manager)',
        },
        masterimage_id => {
            label        => 'Master image',
            type         => 'relation',
            relation     => 'single',
            pattern      => '^\d*$',
            is_mandatory => 1,
	    description  => 'The original master image used to generate the system images',
            option       => [],
        },
    };
}


=pod
=begin classdoc

Check params required for managing system images.

=end classdoc
=cut

sub checkStorageManagerParams {
    my ($self, %args) = @_;

    throw Kanopya::Exception::NotImplemented();
}


=pod
=begin classdoc

@return the storage manager parameters as an attribute definition.

=end classdoc
=cut

sub getStorageManagerParams {
    my ($self, %args) = @_;

    throw Kanopya::Exception::NotImplemented();
}

1;
