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

Base class for containers. A container represent a disk provided by a disk manager,
it is identified by a name, a device path, and could contains a filesystem and data. 

@since    2012-Feb-23
@instance hash
@self     $self

=end classdoc

=cut

package Entity::Container;
use base "Entity";

use Entity;
use Kanopya::Exceptions;

use Data::Dumper;
use Log::Log4perl "get_logger";

my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    disk_manager_id => {
        pattern      => '^[0-9\.]*$',
        is_mandatory => 0,
        is_extended  => 0
    },
    container_name => {
        pattern      => '^.*$',
        is_mandatory => 1,
        is_extended  => 0
    },
    container_size => {
        pattern      => '^.*$',
        is_mandatory => 1,
        is_extended  => 0
    },
    container_device => {
        pattern      => '^.*$',
        is_mandatory => 1,
        is_extended  => 0
    },
    container_filesystem => {
        pattern      => '^.*$',
        is_mandatory => 1,
        is_extended  => 0
    },
    container_freespace => {
        pattern      => '^.*$',
        is_mandatory => 1,
        is_extended  => 0
    },
};

sub getAttrDef { return ATTR_DEF; }


=pod

=begin classdoc

@return the existing container accesses of the container 

=end classdoc

=cut

sub getAccesses {
    my $self = shift;

    my @container_accesses = $self->container_accesses;
    return \@container_accesses;
}


=pod

=begin classdoc

Get a possible local container access to the container. Throwing an internal exception
if no local access exists.

@return the local container access to the container

=end classdoc

=cut

sub getLocalAccess {
    my $self = shift;

    for my $access ($self->container_accesses) {
        if ($access->isa('Entity::ContainerAccess::LocalContainerAccess')) {
            return $access;
        }
    }

    throw Kanopya::Exception::Internal(
              error => "No local access exists for this container <$self>"
          );
}


=pod

=begin classdoc

Accessor to get the component that provides the container.

@return the component that provides the container.

=end classdoc

=cut

sub getDiskManager {
    my $self = shift;

    return $self->disk_manager;
}


=pod

=begin classdoc

@return a generic string representation of the container

=end classdoc

=cut

sub toString {
    my $self = shift;

    my $container_id = $self->getAttr(name => 'container_id');
    my $mananger_id  = $self->getAttr(name => 'disk_manager_id');

    my $string = "Container, id = $container_id, " .
                 "disk_manager_id = $mananger_id";

    return $string;
}

1;
