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

package Entity::ContainerAccess;
use base "Entity";

use Kanopya::Exceptions;

use Entity;
use Entity::Container;
use Entity::ServiceProvider;

use Log::Log4perl "get_logger";
my $log = get_logger("executor");

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
        pattern      => '^.*$',
        is_mandatory => 1,
        is_extended  => 0
    },
    container_access_ip => {
        pattern      => '^.*$',
        is_mandatory => 1,
        is_extended  => 0
    },
    container_access_port => {
        pattern      => '^.*$',
        is_mandatory => 1,
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

=head2 toString

    desc: return a string representation of the entity

=cut

sub toString {
    my $self = shift;

    my $access_id    = $self->getAttr(name => 'container_access_id');
    my $container_id = $self->getAttr(name => 'container_id');
    my $manager_id   = $self->getAttr(name => 'export_manager_id');

    my $string = "ContainerAccess, id = $container_access_id, " .
                 "container_id = $container_id" .
                 "export_manager_id = $manager_id";

    return $string;
}

=head2 getServiceProvider

    desc: Return the service provider that provides the component/conector
          that manage the exported container.

=cut

sub getServiceProvider {
    my $self = shift;

    my $service_provider_id = $self->getExportManager->getAttr(name => 'service_provider_id');

    return Entity::ServiceProvider->get(id => $service_provider_id);
}

=head2 getContainer

=cut

sub getContainer {
    my $self = shift;

    return Entity::Container->get(id => $self->getAttr(name => 'container_id'));
}

=head2 getExportManager

    desc: Return the component/conector that
          manages this container access.

=cut

sub getExportManager {
    my $self = shift;

    return Entity->get(id => $self->getAttr(name => 'export_manager_id'));
}

1;
