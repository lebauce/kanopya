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

package EEntity::EContainer::ELocalContainer;
use base "EEntity::EContainer";

use strict;
use warnings;

use EEntity::EContainerAccess::ELocalContainerAccess;
use File::Basename;

use Log::Log4perl "get_logger";

use Data::Dumper;
my $log = get_logger("");

sub new {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'path', 'size', 'filesystem' ]);

    $args{data} = {
        container_device     => $args{path},
        container_size       => $args{size},
        container_filesystem => $args{filesystem},
        container_name       => basename($args{path}),
    };

    # Here bless $args{data} with this EEntity, to be able to call
    # getAttr on the object returned by EEntity->_getEntity.
    bless $args{data}, $class;

    my $self = $class->SUPER::new(%args);

    bless $self, $class;
    return $self;
}

sub save {}

sub getAttr {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'name' ]);

    if ($self->_getEntity and $self->_getEntity->isa('EEntity::EContainer::ELocalContainer')) {
        return $self->_getEntity->{$args{name}};
    }
    return $self->{$args{name}};
}

sub createDefaultExport {
    my $self = shift;
    my %args = @_;

    return EEntity::EContainerAccess::ELocalContainerAccess->new(econtainer => $self);
}

sub removeDefaultExport {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'container_access' ]);
}

sub getMountPoint {
    my $self = shift;

    return "/mnt/local_" . $self->getAttr(name => 'container_name');
}

sub copy {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'dest', 'econtext' ]);

    # When we copy to a loopback of a file on a NFS mountpoint
    # where the server and the client are the same machine
    # we encounter a kernel crash.
    if ($args{dest}->isa("EEntity::EContainer::EFileContainer")) {
        my $eexport_manager = EFactory::newEEntity(
                              data => $args{dest}->container_access->getExportManager
                          );

        if ($eexport_manager->getEContext->isa("EContext::Local") and
            $eexport_manager->isa("EEntity::EComponent::ENfsd3")) {

            my $mountpoint = $eexport_manager->getMountDir(
                                 device => $args{dest}->container_access->container->container_device
                             );

            my $container = EEntity::EContainer::ELocalContainer->new(
                                path       => $mountpoint . '/' . $args{dest}->container_device,
                                size       => $args{dest}->container_size,
                                filesystem => $args{dest}->container_filesystem,
                            );

            return $self->copy(dest => $container, econtext => $args{econtext}, erollback => $args{erollback});
        }
    }

    return $self->SUPER::copy(%args);
}

1;
