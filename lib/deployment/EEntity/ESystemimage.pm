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
use EEntity;
use Entity::Container::LocalContainer;

use TryCatch;
use Data::Dumper;
use Log::Log4perl "get_logger";

my $log = get_logger("");


=pod
=begin classdoc

Delegate the mount of the system image to the storage manager.

@return the mount point where is mounted the file system.

=end classdoc
=cut

sub mount {
    my ($self, %args) = @_;

    my $storage_manager = EEntity->new(entity => $self->storage_manager);
    return $storage_manager->mountSystemImage(systemimage => $self, %args);
}


=pod
=begin classdoc

Delegate the unmount of the system image to the storage manager.

=end classdoc
=cut

sub umount {
    my ($self, %args) = @_;

    my $storage_manager = EEntity->new(entity => $self->storage_manager);
    return $storage_manager->umountSystemImage(systemimage => $self, %args);
}


=pod
=begin classdoc

Delegate the deletion of the system image to the storage manager.

@optional erollback the erollback object

=end classdoc
=cut

sub remove {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, optional => { "erollback" => undef });

    my $storage_manager = EEntity->new(entity => $self->storage_manager);
    return $storage_manager->removeSystemImage(systemimage => $self, %args);
}

1;
