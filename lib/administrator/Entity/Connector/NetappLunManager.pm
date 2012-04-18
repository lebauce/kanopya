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

package Entity::Connector::NetappLunManager;
use base 'Entity::Connector::NetappManager';

use warnings;
use strict;

use Entity::HostManager;
use Entity::Container::NetappLun;
use Entity::Container::NetappVolume;
use Entity::ContainerAccess::IscsiContainerAccess;

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

    if ($args{boot_policy} eq Entity::HostManager->BOOT_POLICIES->{pxe_iscsi}) {
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
    
    my $value;
    if ($args{readonly}) { $value = 'ro'; }
    else                 { $value = 'wb'; }
    return { 
        name  => 'iomode',
        value => $value,
    }
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
                         required => [ "volume_id", "disk_name", "size", "filesystem" ]);

    $log->debug("New Operation CreateDisk with attrs : " . %args);
    Operation->enqueue(
        priority => 200,
        type     => 'CreateDisk',
        params   => {
            disk_manager_id     => $self->getAttr(name => 'connector_id'),
            disk_name           => $args{disk_name},
            size                => $args{size},
            noformat            => defined $args{noformat} ? $args{noformat} : 0,
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

=head2 createExport

    Desc : Implement createExport from ExportManager interface.
           This function enqueue a ECreateExport operation.
    args : export_name, device, typeio, iomode

=cut

sub createExport {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "container", "export_name", "typeio", "iomode" ]);

    $log->debug("New Operation CreateExport with attrs : " . %args);
    Operation->enqueue(
        priority => 200,
        type     => 'CreateExport',
        params   => {
            export_manager_id   => $self->getAttr(name => 'connector_id'),
            container_id => $args{container}->getAttr(name => 'container_id'),
            export_name  => $args{export_name},
            typeio       => $args{typeio},
            iomode       => $args{iomode}
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

=head2 synchronize 

    Desc: synchronize netapp lun information with kanopya database

=cut

sub synchronize {
    my $self = shift;
    my %args = @_;

    # Get list of luns exists on NetApp
    foreach my $lun ($self->luns) {
        my @array_lun_volume_name = split(/\//, $lun->path);
        my $lun_volume_name = $array_lun_volume_name[2];
        my $lun_name = $array_lun_volume_name[3];

        # Search in database if the volume is stored
        my $lun_volume_obj = Entity::Container->find( hash => { container_name => $lun_volume_name });
        my $lun_volume_id = $lun_volume_obj->getAttr(name => "volume_id");

        # Is the LUN already in database
        eval {
            Entity::Container->search(hash => { container_name => $lun_name });
        };
        if ($@) {
            Entity::Container::NetappLun->new(
                disk_manager_id      => $self->getAttr(name => 'entity_id'),
                container_name       => $lun_name,
                container_size       => $lun->size_used,
                container_filesystem => "ext3",
                container_freespace  => 0,
                container_device     => $lun_name,
                volume_id            => $lun_volume_id,
            );
        }
    }
}

sub getConf {
    my $self = shift;

    my $conf = {};
    my @tab_volumes = ();

    my @volumes = Entity::Container::NetappVolume->search(hash => {});

    for my $volume (@volumes) {
        my $netapp_volume = {
            volume_id   => $volume->getAttr(name => 'volume_id'),
            volume_name => $volume->getAttr(name => 'container_name'),
        };
        $netapp_volume->{luns} = ();
        my $luns = Entity::Container::NetappLun->search(
                       hash => {
                           volume_id => $netapp_volume->{volume_id}
                        }
                   );

        for my $lun (@{$luns}) {
            my $lun_hash = {
                lun_id     => $lun->getAttr(name => 'lun_id'),
                name       => $lun->getAttr(name => 'container_name'),
                size       => $lun->getAttr(name => 'container_size'),
                filesystem => $lun->getAttr(name => 'container_filesystem'),
            };
            push @{$netapp_volume->{luns}}, $lun_hash;
        }
        push @tab_volumes, $netapp_volume;
    }
    $conf->{netapp_volumes} = \@tab_volumes;
    return $conf;
}


=head2 getConf 

    Desc: return hash structure containing luns  

=cut

sub getConf2 {
    my ($self) = @_;
    my $config = {};
    $config->{aggregates} = [];
    $config->{volumes} = [];
    my @aggregates = $self->aggregates;
    my @volumes = $self->volumes;
    my @luns = $self->luns;
    
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
                foreach my $lun (@luns) {
                    my $name = $volume->name;
                    if($lun->path =~ /$name/) {
                        my $tmp3 = {
                            lun_path      => $lun->path,
                            lun_state     => $lun->state,
                            lun_totalsize => $lun->size,
                            lun_sizeused => $lun->size_used,
                        };
                        push @{$tmp2->{volume_luns}}, $tmp3;
                    }
                }    
                push @{$tmp->{aggregates_volumes}}, $tmp2;
            }    
        }
        
        push @{$config->{aggregates}}, $tmp;
    }
     
    return $config;
}

1;
