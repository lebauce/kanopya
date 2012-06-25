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
use base "Manager::ExportManager";
use base "Manager::DiskManager";

use strict;
use warnings;

use Entity::Container::FileContainer;
use Entity::ContainerAccess::FileContainerAccess;
use Entity::ContainerAccess;
use Entity::ServiceProvider;

use Manager::HostManager;
use Kanopya::Exceptions;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("administrator");
my $errmsg;

use constant ATTR_DEF => {};

sub getAttrDef { return ATTR_DEF; }

sub methods {
    return {
        'getExportType' => {
            'description' => 'Return the type of managed exports.',
            'perm_holder' => 'entity',
        },
        'getDiskType' => {
            'description' => 'Return the type of managed disks.',
            'perm_holder' => 'entity',
        },
    }
}

sub getExportType {
    return "NFS export";
}

sub getDiskType {
    return "Virtual machine disk";
}

=head2 checkDiskManagerParams

=cut

sub checkDiskManagerParams {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => [ "container_access_id", "systemimage_size" ]);
}

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

    if ($args{boot_policy} eq Manager::HostManager->BOOT_POLICIES->{virtual_disk}) {
        return $self;
    }

    throw Kanopya::Exception::Internal::UnknownCategory(
              error => "Unsupported boot policy: $args{boot_policy}"
          );
}

sub getBootPolicyFromExportManager {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "export_manager" ]);

    my $cluster = Entity::ServiceProvider->get(id => $self->getAttr(name => 'service_provider_id'));

    if ($args{export_manager}->getId == $self->getId) {
        return Manager::HostManager->BOOT_POLICIES->{virtual_disk};
    }

    throw Kanopya::Exception::Internal::UnknownCategory(
              error => "Unsupported export manager:" . $args{export_manager}
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
            name                => $args{name},
            size                => $args{size},
            filesystem          => $args{filesystem},
            vg_id               => $args{vg_id},
            container_access_id => $args{container_access}->getAttr(
                                       name => 'container_access_id'
                                   ),
            context             => {
                disk_manager => $self,
            }
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
            context => {
                export_manager => $self,
                container      => $args{container},
            },
            manager_params => {
                export_name    => $args{export_name},
            },
        },
    );
}

1;
