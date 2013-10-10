#    Copyright © 2011 Hedera Technology SAS
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

Base class for container accesses. A container access represent a disk export
provided by an export manager, it is identified by an export string that usualy
can be used for connecting and mounting the remote disk.

@since    2012-Feb-23
@instance hash
@self     $self

=end classdoc

=cut

package Entity::ContainerAccess;
use base Entity;

use Kanopya::Exceptions;
use Entity::Component;
use Entity::Container;

use Log::Log4perl "get_logger";
my $log = get_logger("");

use constant ATTR_DEF => {
    container_id => {
        label        => 'Device',
        type         => 'relation',
        relation     => 'single',
        pattern      => '^[0-9\.]*$',
        is_mandatory => 0,
        is_editable  => 1
    },
    export_manager_id => {
        pattern      => '^[0-9\.]*$',
        is_mandatory => 0,
    },
    container_access_export => {
        label        => 'Export name',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 0,
        is_editable  => 0
    },
    container_access_ip => {
        pattern      => '^.*$',
        is_mandatory => 0,
    },
    container_access_port => {
        pattern      => '^.*$',
        is_mandatory => 0,
    },
    device_connected => {
        pattern      => '^.*$',
        is_mandatory => 0,
    },
    partition_connected => {
        pattern      => '^.*$',
        is_mandatory => 0,
    },
};

sub getAttrDef { return ATTR_DEF; }


=pod
=begin classdoc

Delegate the creation of the export to the export manager.

@return the container

=end classdoc
=cut

sub create {
    my ($class, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ "export_manager_id", "container_id" ]);

    Entity::Component->get(id => $args{export_manager_id})->createExport(
        container => Entity::Container->get(id => delete $args{container_id}),
        %args
    );
}


=pod
=begin classdoc

Delegate the removal of the export to the export manager.

@return the container

=end classdoc
=cut

sub remove {
    my ($self, %args) = @_;

    $self->export_manager->removeExport(container_access => $self);
}


=pod
=begin classdoc

Accessor to get the exported container.

@return the container

=end classdoc
=cut

sub getContainer {
    my $self = shift;

    return $self->container;
}


=pod
=begin classdoc

Accessor to get the component that provides the container access.

@return the component instance.

=end classdoc
=cut

sub getExportManager {
    my $self = shift;

    return $self->export_manager;
}


=pod
=begin classdoc

Specific method to specify the attribute to use to display the container access.

@return the label attribute.

=end classdoc
=cut

sub getLabelAttr { return 'container_access_export'; }


=pod
=begin classdoc

@return a generic string representation of the container access

=end classdoc
=cut

sub toString {
    my $self = shift;

    my $container_id = $self->getAttr(name => 'container_id');
    my $manager_id   = $self->getAttr(name => 'export_manager_id');

    my $string = "ContainerAccess, id: " . $self->id .
                 ", container_id: $container_id" .
                 ", export_manager_id: $manager_id";

    return $string;
}

=pod
=begin classdoc

Build the mountpoint path on wich can be mounted the container access.

@return a mountpoint for the container device

=end classdoc
=cut

sub getMountPoint {
    my $self = shift;

    return "/mnt/" . $self->id;
}

1;
