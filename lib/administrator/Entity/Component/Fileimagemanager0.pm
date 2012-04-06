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
use Entity::ContainerAccess::FileContainerAccess;
use Entity::ContainerAccess;
use Entity::ServiceProvider;
use Entity::HostManager;
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
    my @access_hashes = ();

    my $cluster = Entity::ServiceProvider->get(id => $self->getAttr(name => 'service_provider_id'));
    my $opennebula = $cluster->getComponent(name => "Opennebula", version => "3");
    
    my $repo_rs = $opennebula->{_dbix}->opennebula3_repositories;
    while (my $repo_row = $repo_rs->next) {
        my $container_access = Entity::ContainerAccess->get(
                                   id => $repo_row->get_column('container_access_id')
                               );
        push @access_hashes, {
            container_access_id   => $container_access->getAttr(name => 'container_access_id'),
            container_access_name => $container_access->getAttr(name => 'container_access_export'),
        }
    }

    $conf->{container_accesses} = \@access_hashes;
    return $conf;
}

sub setConf {
    my $self = shift;
    my ($conf) = @_;
}

sub getExportManagerFromBootPolicy {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "boot_policy" ]);

    if ($args{boot_policy} eq Entity::HostManager->BOOT_POLICIES->{virtual_disk}) {
        return $self;
    }

    throw Kanopya::Exception::Internal::UnknownCategory(
              error => "Unsupported boot policy: $args{boot_policy}"
          );
}

sub getReadOnlyParameter {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'readonly' ]);
    
    return undef;
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
                         required => [ "container_access", "name", "size", "filesystem" ]);

    $log->debug("New Operation CreateDisk with attrs : " . %args);
    Operation->enqueue(
        priority => 200,
        type     => 'CreateDisk',
        params   => {
            disk_manager_id     => $self->getAttr(name => 'component_id'),
            container_access_id => $args{container_access}->getAttr(
                                       name => 'container_access_id'
                                   ),
            name                => $args{name},
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

    General::checkParams(args     => \%args,
                         required => [ "container_access_id" ]);

    my $container_access = Entity::ContainerAccess->get(id => $args{container_access_id});

    return $container_access->getContainer->getAttr(name => 'container_freespace');
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
                        disk_manager_id     => $self->getAttr(name => 'fileimagemanager0_id'),
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

=head2 createExport

    Desc : Implement createExport from ExportManager interface.
           This function enqueue a ECreateExport operation.
    args : export_name, device, typeio, iomode

=cut

sub createExport {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "container", "export_name" ]);

    $log->debug("New Operation CreateExport with attrs : " . %args);
    Operation->enqueue(
        priority => 200,
        type     => 'CreateExport',
        params   => {
            export_manager_id   => $self->getAttr(name => 'component_id'),
            container_id => $args{container}->getAttr(name => 'container_id'),
            export_name  => $args{export_name},
        },
    );
}

=head2 removeExport

    Desc : Implement createExport from ExportManager interface.
           This function enqueue a ERemoveExport operation.
    args : export_name

=cut

sub removeExport {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "container_access" ]);

    $log->debug("New Operation RemoveExport with attrs : " . %args);
    Operation->enqueue(
        priority => 200,
        type     => 'RemoveExport',
        params   => {
            container_access_id => $args{container_access}->getAttr(name => 'container_access_id'),
        },
    );
}

sub addContainerAccess {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "container" ]);

    my $access = Entity::ContainerAccess::FileContainerAccess->new(
                     container_id      => $args{container}->getAttr(name => 'container_id'),
                     export_manager_id => $self->getAttr(name => 'fileimagemanager0_id'),
                 );

    my $access_id = $access->getAttr(name => 'container_access_id');
    $log->info("File container access <$access_id> saved to database");

    return $access;
}

sub delContainerAccess {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "container_access" ]);

    $args{container_access}->delete();
}

1;
