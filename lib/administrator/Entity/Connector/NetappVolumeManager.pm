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
use strict;

use Entity::HostManager;
use Entity::Container::NetappVolume;
use Entity::ContainerAccess::NfsContainerAccess;
use Entity::NetappAggregate;

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

=head2 synchronize 

    Desc: synchronize netapp volumes information with kanopya database

=cut 

sub synchronize {
    my $self = shift;
    my %args = @_;
    my $aggregates = {};
    my $manager_ip = $self->getServiceProvider->getMasterNodeIp;
    my $netapp_id = $self->getAttr(name => "service_provider_id");

    foreach my $aggregate ($self->aggregates) {
        my $aggr;
        eval {
            $aggr = Entity::NetappAggregate->find(
                        hash => {
                            name      => $aggregate->name,
                            netapp_id => $netapp_id
                        }
                    );
        };
        if ($@) {
            $aggr = Entity::NetappAggregate->new(
                        name      => $aggregate->name,
                        netapp_id => $netapp_id
                    );
            $aggr->setComment(comment => "Default comment for " . $aggregate->name);
        }
        $aggregates->{$aggregate->name} = $aggr;
    }

    foreach my $volume ($self->volumes) {
        eval {
            Entity::Container->find(hash => { container_name => $volume->name });
        };
        if ($@) {
            my $aggregate = $aggregates->{$volume->containing_aggregate};
            my $container = Entity::Container::NetappVolume->new(
                                disk_manager_id      => $self->getAttr(name => 'entity_id'),
                                container_name       => $volume->name,
                                container_size       => $volume->size_used,
                                container_filesystem => "wafl",
                                container_freespace  => 0,
                                container_device     => $volume->name,
                                aggregate_id         => $aggregate->getAttr(name => "aggregate_id"),
                            );
            $container->setComment(comment => "Default comment for " . $volume->name);

            my $container_access = Entity::ContainerAccess::NfsContainerAccess->new(
                                       container_id            => $container->getAttr(name => 'container_id'),
                                       export_manager_id       => $self->getAttr(name => 'entity_id'),
                                       container_access_export => $manager_ip . ':/vol/' . $volume->name,
                                       container_access_ip     => $manager_ip,
                                       container_access_port   => 2049,
                                       options                 => 'rw,sync,no_root_squash',
                                   );
        }
    }
}

=head2 getConf 

    Desc: return hash structure containing aggregates and volumes  

=cut

=head2
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
                    volume_luns      => [],
                    entity_comment   => $volume->getComment(),
                };
            
                push @{$tmp->{aggregates_volumes}}, $tmp2;
            }    
        }
        
        push @{$config->{aggregates}}, $tmp;
    }
     
    return $config;
}
=cut

sub getConf {
    my ($self) = @_;
    my @aggregates = Entity::NetappAggregate->search( hash => {} );
    my $aggregate = [];
    my $volume = [];
    
    foreach my $aggr (@aggregates) {
        my $aggr_list = {
            aggregate_name      => $aggr->getAttr(name => 'name'),
            aggregate_id        => $aggr->getAttr(name => 'aggregate_id'),
            #aggregate_totalsize => $aggr->size_total,
            #aggregate_sizeused  => $aggr->size_used,
            entity_comment      => $aggr->getComment(),
        };
        my @netappvolumes = Entity::Container::NetappVolume->search( hash => { aggregate_id => $aggr->getAttr(name => 'aggregate_id') } );
        foreach my $vol (@netappvolumes) {
            my $vol_list = {
                container_id            => $vol->getAttr(name => 'container_id'),
                container_name          => $vol->getAttr(name => 'container_name'),
                container_size          => $vol->getAttr(name => 'container_size'),
                container_device        => $vol->getAttr(name => 'container_device'),
                container_filesystem    => $vol->getAttr(name => 'container_filesystem'),
                container_freespace     => $vol->getAttr(name => 'container_freespace'),
                disk_manager_id         => $vol->getAttr(name => 'disk_manager_id'),
                entity_comment          => $vol->getComment(),
            };
            push(@$volume, $vol_list);
        }
        push(@$aggregate, $aggr_list);
    }
    return { 
            "aggregates"=>$aggregate,
            "volumes"=>$volume
    };
}

1;
