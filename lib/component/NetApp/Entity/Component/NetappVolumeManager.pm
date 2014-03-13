#    Copyright © 2012-2013 Hedera Technology SAS
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

TODO

=end classdoc
=cut

package Entity::Component::NetappVolumeManager;
use base "Entity::Component::NetappManager";
use base "Manager::ExportManager";
use base "Manager::DiskManager";

use warnings;
use strict;

use Manager::HostManager;

use Entity::Container::NetappVolume;
use Entity::ContainerAccess::NfsContainerAccess;
use Entity::NetappAggregate;

use Data::Dumper;

use Log::Log4perl "get_logger";
my $log = get_logger("");

use constant ATTR_DEF => {
    disk_type => {
        is_virtual => 1
    },
    export_type => {
        is_virtual => 1
    }
};

sub getAttrDef { return ATTR_DEF; }

sub exportType {
    return "NFS export";
}

sub diskType {
    return "NetApp volume";
}

=pod
=begin classdoc

@return the manager params definition.

=end classdoc
=cut

sub getManagerParamsDef {
    my ($self, %args) = @_;

    return {
        # TODO: call super on all Manager supers
        %{ $self->SUPER::getManagerParamsDef },
        aggregate_id => {
            label        => 'Aggregate to use',
            type         => 'enum',
            is_mandatory => 1,
        },
    };
}

sub checkDiskManagerParams {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "aggregate_id", "systemimage_size" ]);
}


=pod
=begin classdoc

@return the managers parameters as an attribute definition. 

=end classdoc
=cut

sub getDiskManagerParams {
    my ($self, %args) = @_;

    my $aggparam = $self->getManagerParamsDef->{aggregate_id};
    $aggparam->{options} = {};

    for my $aggr (@{ $self->getConf->{aggregates} }) {
        $aggparam->{options}->{$aggr->{aggregate_id}} = $aggr->{aggregate_name};
    }
    return { aggregate_id => $aggparam };
}

sub getExportManagerFromBootPolicy {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "boot_policy" ]);

    if ($args{boot_policy} eq Manager::HostManager->BOOT_POLICIES->{pxe_nfs}) {
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

    if ($args{export_manager}->id == $self->id) {
        return Manager::HostManager->BOOT_POLICIES->{pxe_nfs};
    }

    throw Kanopya::Exception::Internal::UnknownCategory(
              error => "Unsupported export manager:" . $args{export_manager}
          );
}

sub getExportManagers {
    my $self = shift;
    my %args = @_;

    return [ $self ];
}

sub getReadOnlyParameter {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'readonly' ]);
    
    return undef;
}

sub createDisk {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "name", "size", "filesystem", "aggregate_id" ]);

    $log->debug("New Operation CreateDisk with attrs : " . %args);
    $self->service_provider->getManager(manager_type => 'ExecutionManager')->enqueue(
        type     => 'CreateDisk',
        params   => {
            name         => $args{name},
            size         => $args{size},
            filesystem   => $args{filesystem},
            aggregate_id => $args{aggregate_id},
            context      => {
                disk_manager => $self,
            }
        },
    );
}


sub createExport {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "container", "export_name" ]);

    $log->debug("New Operation CreateExport with attrs : " . %args);
    $self->service_provider->getManager(manager_type => 'ExecutionManager')->enqueue(
        type     => 'CreateExport',
        params   => {
            context => {
                export_manager => $self,
                container      => $args{container},
            },
            manager_params => {
                export_name => $args{export_name},
            },
        },
    );
}


sub synchronize {
    my $self = shift;
    my %args = @_;
    my $aggregates = {};
    my $manager_ip = $self->getMasterNode->adminIp;
    my $netapp_id = $self->service_provider->id;

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

sub getConf {
    my $self = shift;

    my $aggregates = [];
    my $volumes = [];
    my $netapp_volumes = {};

    for my $vol ($self->volumes) {
        $netapp_volumes->{$vol->name} = $vol;
    }

    # Only display the aggregates that are both on NetApp and in our DB
    foreach my $netapp_aggr ($self->aggregates) {
        my $aggr;
        eval {
            $aggr = Entity::NetappAggregate->find(hash => { name => $netapp_aggr->name });
        };

        if ($@) {
            $log->debug("Aggregate " . $netapp_aggr->name . " has been removed on NetApp " .
                        "but still exists in our DB, skipping it ...");
            next;
        }

        my $aggregate = {
            aggregate_name      => $netapp_aggr->name,
            aggregate_id        => $aggr->id,
            aggregate_state     => $netapp_aggr->state,
            aggregate_totalsize => General::bytesToHuman(value => $netapp_aggr->size_total, precision => 5),
            aggregate_sizeused  => General::bytesToHuman(value => $netapp_aggr->size_used, precision => 5),
            entity_comment      => $aggr->comment,
        };

        my @contained_volumes = $netapp_aggr->child_get("volumes")->children_get;
        foreach my $vol (@contained_volumes) {
            $vol = $netapp_volumes->{$vol->child_get("name")->{content}};
            bless $vol, "NaObject";
            my $volume =  Entity::Container->find(hash => { container_name => $vol->name });

            push @$volumes, {
                container_id            => $volume->id,
                container_name          => $vol->name,
                container_state         => $vol->state,
                container_size          => General::bytesToHuman(value => $volume->container_size, precision => 5),
                container_device        => $volume->container_device,
                container_filesystem    => $volume->container_filesystem,
                container_freespace     => General::bytesToHuman(value => $volume->container_freespace, precision => 5),
                disk_manager_id         => $volume->disk_manager_id,
                entity_comment          => $volume->comment,
            };
        }

        $aggregate->{netapp_volumes} = $volumes;
        push @$aggregates, $aggregate;
    }
    
    return {
        "aggregates" => $aggregates,
    };
}

1;
