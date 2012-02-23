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

use Entity::Container::LvmContainer;
use Entity::ServiceProvider::Inside::Cluster;

use Log::Log4perl "get_logger";
my $log = get_logger("executor");

use constant ATTR_DEF => {
    container_id => {
        pattern => '^[0-9\.]*$',
        is_mandatory => 1,
        is_extended => 0
    },
    export_manager_id => {
        pattern => '^[0-9\.]*$',
        is_mandatory => 1,
        is_extended => 0
    },
    container_access_export => {
        pattern => '^.*$',
        is_mandatory => 0,
        is_extended => 0
    },
    container_access_ip => {
        pattern => '^.*$',
        is_mandatory => 0,
        is_extended => 0
    },
    container_access_port => {
        pattern => '^.*$',
        is_mandatory => 0,
        is_extended => 0
    },
};

sub getAttrDef { return ATTR_DEF; }

=head2 getAttr

    desc: Overide basedb mathod to have virtuals attributes,
          Mandatory attributes can be found in the current table,
          others are provided by sub classes by matching virtual
          attributes names to specifics ones.

=cut

sub getAttr {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'name' ]);

    # Firstly, try to get value from generic attrs.
    my $value = $self->getContainerAccess->{$args{name}};
    if (! defined $value) {
        # Else get the value from usual way.
        $value = $self->SUPER::getAttr(name => $args{name});
    }
    return $value;
}

=head2 toString

    desc: return a string representation of the entity

=cut

sub toString {
    my $self = shift;

    my $access_id    = $self->getAttr(name => 'container_access_id');
    my $container_id = $self->getAttr(name => 'container_id');
    my $mananger_id  = $self->getAttr(name => 'export_manager_id');

    my $string = "ContainerAccess, id = $container_access_id, " .
                 "container_id = $container_id" .
                 "export_manager_id = $mananger_id";

    return $string;
}

=head2 getServiceProvider

    desc: Return the service provider that provides the component/conector
          that manage the exported container.

=cut

sub getServiceProvider {
    my $self = shift;

    my $service_provider_id = $self->getExportManager->getAttr(name => 'inside_id');

    return Entity::ServiceProvider::Inside::Cluster->get(id => $service_provider_id);
}

=head2 getContainer

=cut

sub getContainer {
    my $self = shift;

    return Entity::Container::LvmContainer->get(
               id => $self->getAttr(name => 'container_id')
           );
}

=head2 getExportManager

    desc: Abstract method. Return the component/conector that
          manages this container access.

=cut

sub getExportManager {
    my $self = shift;

    throw Kanopya::Exception::NotImplemented();
}

sub getContainerAccess {
    my $self = shift;

    return {};
}

1;
