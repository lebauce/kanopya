#    NetappManager.pm - NetApp connector
#    Copyright © 2012 Hedera Technology SAS
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

package Entity::Connector::NetappVolumeManager;
use base "Entity::Connector::NetappManager";

use warnings;

use Entity::HostManager;
use Entity::Container::NetappVolume;
use Entity::ContainerAccess::NfsContainerAccess;

use Data::Dumper;

use Log::Log4perl "get_logger";
my $log = get_logger("administrator");

use constant ATTR_DEF => {
};

sub getAttrDef { return ATTR_DEF; }

sub getExportManagerFromBootPolicy {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "boot_policy" ]);

    if ($args{boot_policy} eq Entity::HostManager->BOOT_POLICIES->{pxe_nfs}) {
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
                         required => [ "name", "size", "filesystem" ]);

    $log->debug("New Operation CreateDisk with attrs : " . %args);
    Operation->enqueue(
        priority => 200,
        type     => 'CreateDisk',
        params   => {
            disk_manager_id     => $self->getAttr(name => 'connector_id'),
            name                => $args{name},
            size                => $args{size},
            filesystem          => $args{filesystem},
            volume_id           => $args{volume_id}
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

=head2 getContainer

    Desc : Implement getContainer from DiskManager interface.
           This function return the container hash that match
           identifiers given in paramters.
    args : lv_id

=cut

sub getContainer {
    my $self = shift;
    my %args = @_;

    my $vol = Entity::Container::NetappVolume->find(hash => \%args);

    my $container = {
        container_id         => $vol->{_dbix}->get_column('volume_id'),
        container_name       => $vol->{_dbix}->get_column('name'),
        container_size       => $vol->{_dbix}->get_column('size'),
        container_freespace  => $self->getFreeSpace()
    };

    return $container;
}

=head2 addContainer

    Desc : Implement addContainer from DiskManager interface.
           This function create a new NetAppContainer into database.
    args : lv_id

=cut

sub addContainer {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "name", "size" ]);

    my $container = Entity::Container::NetappVolume->new(
                        disk_manager_id     => $self->getAttr(name => 'connector_id'),
                        name                => $args{name},
                        size                => $args{size}
                    );

    my $container_id = $container->getAttr(name => 'container_id');
    $log->info("Volume container <$container_id> saved to database");

    return $container;
}

=head2 delContainer

    Desc : Implement delContainer from DiskManager interface.
           This function delete a LvmContainer from database.
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
            export_manager_id   => $self->getAttr(name => 'connector_id'),
            container_id        => $args{container}->getAttr(name => 'container_id'),
            export_name         => $args{export_name},
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

=head2 getContainerAccess

    Desc : Implement getContainerAccess from ExportManager interface.
           This function return the container access hash that match
           identifiers given in paramters.
    args : lun_id, target_id

=cut

sub getContainerAccess {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "container_access" ]);

    my $netapp = Entity::ServiceProvider->get(id => $self->getAttr(name => "service_provider_id"));

    my $container = {
        container_access_export  => $netapp->getMasterNodeIp() . ':/vol/' .
                                   $args{container_access}->getAttr(name => "export_path"),
        container_access_ip      => $netapp->getMasterNodeIp(),
        container_access_port    => 3260,
        container_access_options => 'rw,no_root_squash,sync'
    };

    return $container;
}

=head2 addContainerAccess

    Desc : Implement addContainerAccess from ExportManager interface.
           This function create a new NfsContainerAccess into database.
    args : container, target_id, lun_id

=cut

sub addContainerAccess {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "container", "export_name" ]);

    my $access = Entity::ContainerAccess::NfsContainerAccess->new(
                     container_id      => $args{container}->getAttr(name => 'container_id'),
                     export_manager_id => $self->getAttr(name => "connector_id"),
                     export_path       => $args{export_name}
                 );

    my $access_id = $access->getAttr(name => 'container_access_id');
    $log->info("NetApp iSCSI container access <$access_id> saved to database");

    return $access;
}

=head2 delContainerAccess

    Desc : Implement delContainerAccess from ExportManager interface.
           This function delete a IscsiContainerAccess from database.
    args : container_access

=cut

sub delContainerAccess {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "container_access" ]);

    $args{container_access}->delete();
}

=head2 synchronize 

    Desc: synchronize netapp volumes information with kanopya database

=cut 

sub synchronize {
    my $self = shift;
    my %args = @_;
    # Get list of volumes exists on NetApp :
    my @volumesList = $self->volumes;
    foreach my $vol (@volumesList) {
        # Get list of volumes exists on Kanopya :
        my $existing_volumes = Entity::Container::NetappVolume->search(hash => { name => $vol->name });
        my $existing_volume = scalar($existing_volumes);
        if ($existing_volume eq "0") {
            my $volume = $self->addContainer(
                             name    => $vol->name,
                             size    => $vol->size_used,
                         );

            $self->addContainerAccess(
                container   => $volume,
                export_name => $vol->name
            );
        }
    }
}

=head2 getConf 

    Desc: return hash structure containing aggregates and volumes  

=cut

sub getConf {
    my ($self) = @_;
    my $config = {};
    $config->{aggregates} = [];
    $config->{volumes} = [];
    my @aggregates = $self->aggregates;
    my @volumes = $self->volumes;
    
    foreach my $aggr (@aggregates) {
        my $tmp = {
            aggregate_name      => $aggr->name,
            aggregate_state     => $aggr->state,
            aggregate_totalsize => $aggr->size_total,
            aggregate_sizeused  => $aggr->size_used,
            aggregate_volumes   => []
        };
        foreach my $volume (@volumes) {
            if($volume->containing_aggregate eq $aggr->name) {
                my $tmp2 = {
                    volume_name      => $volume->name,
                    volume_state     => $volume->state,
                    volume_totalsize => $volume->size_total,
                    volume_sizeused  => $volume->size_used,
                    volume_luns      => []
                };
            
                push @{$tmp->{aggregates_volumes}}, $tmp2;
            }    
        }
        
        push @{$config->{aggregates}}, $tmp;
    }
     
    return $config;
}

1;
