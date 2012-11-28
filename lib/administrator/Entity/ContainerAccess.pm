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
use base "Entity";

use Entity;
use Kanopya::Exceptions;

use Log::Log4perl "get_logger";
my $log = get_logger("");

use constant ATTR_DEF => {
    container_id => {
        pattern      => '^[0-9\.]*$',
        is_mandatory => 1,
        is_extended  => 0
    },
    export_manager_id => {
        pattern      => '^[0-9\.]*$',
        is_mandatory => 1,
        is_extended  => 0
    },
    container_access_export => {
        label        => 'Export name',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 0,
        is_editable  => 1
    },
    container_access_ip => {
        pattern      => '^.*$',
        is_mandatory => 0,
        is_extended  => 0
    },
    container_access_port => {
        pattern      => '^.*$',
        is_mandatory => 0,
        is_extended  => 0
    },
    device_connected => {
        pattern      => '^.*$',
        is_mandatory => 0,
        is_extended  => 0
    },
    partition_connected => {
        pattern      => '^.*$',
        is_mandatory => 0,
        is_extended  => 0
    },
};

sub getAttrDef { return ATTR_DEF; }


=pod

=begin classdoc

Get the service provider on wich is installed the component that provides the container access.

@return the service provider.

=end classdoc

=cut

sub getServiceProvider {
    my $self = shift;

    return $self->getExportManager->service_provider;
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

    return Entity->get(id => $self->export_manager_id);
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

1;
