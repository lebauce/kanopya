#    Copyright © 2011 Hedera Technology SAS
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

=head1 NAME

Entity::Container

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

package Entity::Container;
use base "Entity";

use Kanopya::Exceptions;

use Entity;
use Entity::ContainerAccess;

use constant ATTR_DEF => {
    disk_manager_id => {
        pattern      => '^[0-9\.]*$',
        is_mandatory => 1,
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


=head2 toString

    desc: return a string representation of the entity

=cut

sub toString {
    my $self = shift;

    my $container_id = $self->getAttr(name => 'container_id');
    my $mananger_id  = $self->getAttr(name => 'disk_manager_id');

    my $string = "Container, id = $container_id, " .
                 "disk_manager_id = $mananger_id";

    return $string;
}

=head2 getAccesses

    desc: Return all accesses linked to this container.

=cut

sub getAccesses {
    my $self = shift;

    @container_accesses = Entity::ContainerAccess->search(
                              hash => { container_id => $self->getAttr(name => 'container_id') }
                          );

    return \@container_accesses;
}

=head2 getServiceProvider

    desc: Return the service provider that provides the component/conector
          that manage the exported container.

=cut

sub getServiceProvider {
    my $self = shift;

    my $service_provider_id = $self->getDiskManager->getAttr(name => 'service_provider_id');

    return Entity::ServiceProvider->get(id => $service_provider_id);
}

=head2 getDiskManager

    desc: Return the component/conector that manage this container.

=cut

sub getDiskManager {
    my $self = shift;

    return Entity->get(id => $self->getAttr(name => 'disk_manager_id'));
}

sub getMountPoint {
    my $self = shift;

    return "/mnt/" . $self->getAttr(name => 'container_id');
}

1;
