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

package Entity::Component::Fileimagemanager0;
use base "Entity::Component";

use strict;
use warnings;

use Entity::Container::FileContainer;
use Entity::ContainerAccess;
use Kanopya::Exceptions;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("administrator");
my $errmsg;

use constant ATTR_DEF => {};

sub getAttrDef { return ATTR_DEF; }

sub getConf {
    my $self = shift;
    my $conf = {};

    return $conf;
}

sub setConf {
    my $self = shift;
    my ($conf) = @_;
}

sub getMainContainerAccess {
    my $self = shift;

    # For instance, like Lvm2 main vg, we get the first container_access found.
    # So we are able to use the Fileimagemanager in a specific kanopya configuration,
    # where only one container access exists for disk image storage.
    return Entity::ContainerAccess->find(hash => {});
}

=head2 createDisk

    Desc : Implement createDisk from DiskManager interface.
           This function enqueue a ECreateDisk operation.
    args :

=cut

sub createDisk {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "container_access", "disk_name", "size", "filesystem" ]);

    $log->debug("New Operation CreateDisk with attrs : " . %args);
    Operation->enqueue(
        priority => 200,
        type     => 'CreateDisk',
        params   => {
            storage_provider_id => $self->getAttr(name => 'service_provider_id'),
            disk_manager_id     => $self->getAttr(name => 'component_id'),
            container_access_id => $args{container_access}->getAttr(
                                       name => 'container_access_id'
                                   ),
            disk_name           => $args{disk_name},
            size                => $args{size},
            filesystem          => $args{filesystem},
        },
    );
}

=head2 removeDisk

    Desc : Implement removeDisk from DiskManager interface.
           This function enqueue a ERemoveDisk operation.
    args :

=cut

sub removeDisk {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "container" ]);

    $log->debug("New Operation RemoveDisk with attrs : " . %args);
    Operation->enqueue(
        priority => 200,
        type     => 'RemoveDisk',
        params   => {
            container_id => $args{container}->getAttr(name => 'container_id'),
        },
    );
}

=head2 getFreeSpace

    Desc : Implement getFreeSpace from DiskManager interface.
           This function return the free space on the volume group.
    args :

=cut

sub getFreeSpace {
    my $self = shift;
    my %args = @_;

    my $container_access = $self->getMainContainerAccess();
    return $container_access->getContainer->getFreeSpace;
}

=head2 addContainer

    Desc : Implement addContainer from DiskManager interface.
           This function create a new LvmContainer into database.
    args : lv_id

=cut

sub addContainer {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "container_access_id", "file_name",
                                       "file_size", "file_filesystem" ]);

    my $container = Entity::Container::FileContainer->new(
                        service_provider_id => $self->getAttr(name => 'service_provider_id'),
                        disk_manager_id     => $self->getAttr(name => 'lvm2_id'),
                        container_access_id => $args{container_access_id},
                        file_name           => $args{file_name},
                        file_size           => $args{file_size},
                        file_filesystem     => $args{file_filesystem},
                    );

    my $container_id = $container->getAttr(name => 'container_id');
    $log->info("File container <$container_id> saved to database");

    return $container;
}

=head2 delContainer

    Desc : Implement delContainer from DiskManager interface.
           This function delete a FileContainer from database.
    args : container

=cut

sub delContainer {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "container" ]);

    $args{container}->delete();
}

1;
