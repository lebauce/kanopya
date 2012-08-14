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
        'getExportManagers' => {
            'description' => 'Return the availables export managers for this disk manager.',
            'perm_holder' => 'entity',
        },
    }
}

sub getExportType {
    return "NFS export";
}

sub getDiskType {
    return "NetApp volume";
}

=head2 checkDiskManagerParams

=cut

sub checkDiskManagerParams {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "aggregate_id", "systemimage_size" ]);
}

=head2 getPolicyParams

=cut

sub getPolicyParams {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'policy_type' ]);

    my $aggregates = {};
    if ($args{policy_type} eq 'storage') {
        for my $aggr (@{ $self->getConf->{aggregates} }) {
            $aggregates->{$aggr->{aggregate_id}} = $aggr->{aggregate_name};
        }
        return [ { name => 'aggregate_id', label => 'Aggregate to use', values => $aggregates } ];
    }
    return [];
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

    if ($args{export_manager}->getId == $self->getId) {
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

=head2 createDisk

    Desc : Implement createDisk from DiskManager interface.
           This function enqueue a ECreateDisk operation.
    args :

=cut

sub createDisk {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "name", "size", "filesystem", "aggregate_id" ]);

    $log->debug("New Operation CreateDisk with attrs : " . %args);
    Operation->enqueue(
        priority => 200,
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
                export_name         => $args{export_name},
            },
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
            aggregate_id        => $aggr->getId,
            aggregate_state     => $netapp_aggr->state,
            aggregate_totalsize => General::bytesToHuman(value => $netapp_aggr->size_total, precision => 5),
            aggregate_sizeused  => General::bytesToHuman(value => $netapp_aggr->size_used, precision => 5),
            entity_comment      => $aggr->getComment,
        };

        my @contained_volumes = $netapp_aggr->child_get("volumes")->children_get;
        foreach my $vol (@contained_volumes) {
            $vol = $netapp_volumes->{$vol->child_get("name")->{content}};
            bless $vol, "NaObject";
            my $volume =  Entity::Container->find(hash => { container_name => $vol->name });

            push @$volumes, {
                container_id            => $volume->getId,
                container_name          => $vol->name,
                container_state         => $vol->state,
                container_size          => General::bytesToHuman(value => $volume->container_size, precision => 5),
                container_device        => $volume->container_device,
                container_filesystem    => $volume->container_filesystem,
                container_freespace     => General::bytesToHuman(value => $volume->container_freespace, precision => 5),
                disk_manager_id         => $volume->disk_manager_id,
                entity_comment          => $volume->getComment,
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
