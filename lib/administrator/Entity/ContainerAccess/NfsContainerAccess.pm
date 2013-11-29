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

=pod

=begin classdoc

Concrete class for nfs container accesses. Nfs container accesses are disk exports provided
by components that use the Nfs protocol to give access to remote disks. It extends base 
container by specifying nfs export options.

@since    2012-Feb-23
@instance hash
@self     $self

=end classdoc

=cut

package Entity::ContainerAccess::NfsContainerAccess;
use base "Entity::ContainerAccess";

use strict;
use warnings;

use Entity::NfsContainerAccessClient;

use constant ATTR_DEF => {
    options => {
        pattern      => '^.*$',
        is_mandatory => 1,
    },
    nfs_container_access_client_options => {
        label        => 'Client options',
        type         => 'string',
        is_mandatory => 0,
        is_editable  => 1,
        is_virtual   => 1
    },
    nfs_container_access_client_name => {
        label        => 'Client name',
        type         => 'string',
        is_mandatory => 0,
        is_editable  => 1,
        is_virtual   => 1
    }
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

    $class->SUPER::create(client_name    => delete $args{nfs_container_access_client_name},
                          client_options => delete $args{nfs_container_access_client_options},
                          %args);
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


sub nfsContainerAccessClientOptions {
    my ($self) = @_;

    return $self->find(related => 'nfs_container_access_clients')->options;
}


sub nfsContainerAccessClientName {
    my ($self) = @_;

    return $self->find(related => 'nfs_container_access_clients')->name;
}

1;
