#    Copyright © 2012 Hedera Technology SAS
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

package EEntity::EComponent::ENetappLunManager;
use base "EEntity::EComponent";

use warnings;
use strict;

use General;
use Kanopya::Exceptions;
use Entity::Container::NetappLun;

use Data::Dumper;
use Log::Log4perl "get_logger";

my $log = get_logger("");
my $errmsg;

=head2 createDisk

createDisk ( name, size, filesystem)
    desc: This function creates a new volume on NetApp.
    args:
        name : string : new volume name
        size : String : disk size finishing by unit (M : Mega, K : kilo, G : Giga)
        filesystem : String : filesystem type

    return:
        1 if an error occurred, 0 otherwise
    
=cut

sub createDisk {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "volume_id", "name", "size", "filesystem" ]);

    my $volume = Entity::Container::NetappVolume->get(id => $args{volume_id});
    my $volume_name = "/vol/" . $volume->getAttr(name => "container_name") . "/" . $args{name};

    # Make the XML RPC call
    my $api = $self->_getEntity();
    $api->lun_create_by_size(path => $volume_name,
                             size => $args{size},
                             type => "linux");

    my $noformat = $args{"noformat"};
    delete $args{noformat};

    # Insert the container into the database
    my $entity = Entity::Container::NetappLun->new(
                     disk_manager_id      => $self->_getEntity->getAttr(name => 'entity_id'),
                     container_name       => $args{name},
                     container_size       => $args{size},
                     container_filesystem => $args{filesystem},
                     container_freespace  => 0,
                     container_device     => $args{name},
                     volume_id            => $args{volume_id}
                 );
    my $container = EFactory::newEEntity(data => $entity);

    if (! defined $noformat) {
        # Connect to the iSCSI target and format it locally

        my $container_access = $self->createExport(container   => $container,
                                                   export_name => $args{name},
                                                   erollback   => $args{erollback});

        my $newdevice = $container_access->connect(econtext => $self->getExecutorEContext);

        $self->mkfs(device   => $newdevice,
                    fstype   => $args{filesystem},
                    econtext => $self->getExecutorEContext);

        $container_access->disconnect(econtext => $self->getExecutorEContext);

        $self->removeExport(container_access => $container_access);
    }

    if (exists $args{erollback} and defined $args{erollback}){
        $args{erollback}->add(
            function   => $self->can('removeDisk'),
            parameters => [ $self, "container", $container ]
        );
    }

    return $container;
}

=head2 removeDisk

=cut

sub removeDisk {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "container" ]);

    if (! $args{container}->isa("EEntity::EContainer::ENetappLun")) {
        throw Kanopya::Exception::Execution(
                  error => "Container must be a EEntity::EContainer::ENetappLun, not " . 
                           ref($args{container})
              );
    }

    # Check if the disk is removable
    $self->SUPER::removeDisk(%args);

    $self->lun_destroy(path => $args{container}->getPath());

    $args{container}->delete();

    #TODO: insert erollback ?
}

=head2 createExport

    Desc : This method allow to create a new export in 1 call

=cut

sub createExport {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ 'container', 'export_name' ],
                         optional => { 'typeio' => 'fileio',
                                       'iomode' => 'wb' });
    # Check if the disk is not already exported
    $self->SUPER::createExport(%args);

    my $api = $self->_getEntity();
    my $volume = $args{container}->getVolume();
    my $lun_path = $args{container}->getPath();

    my $kanopya_cluster = Entity::ServiceProvider::Cluster->find(
                             hash => {
                                 cluster_name => 'Kanopya'
                             }
                         );

    my $master = $kanopya_cluster->getMasterNode();

    eval {
        $self->_getEntity()->igroup_create('initiator-group-name' => "igroup_kanopya_master",
                                           'initiator-group-type' => "iscsi");
    };

    eval {
        $self->_getEntity()->igroup_add('initiator'            => $master->getAttr(name => "host_initiatorname"),
                                        'initiator-group-name' => "igroup_kanopya_master");
    };

    my $lun_id;
    eval {
        $lun_id = $api->lun_map('path'            => $lun_path,
                                'initiator-group' => 'igroup_kanopya_master')->child_get_string("lun-id-assigned");
    };
    if ($@) {
        # The LUN is already mapped, get its lun ID
        $lun_id = $self->getLunId(lun  => $args{container},
                                  host => $master);
    }

    my $entity = Entity::ContainerAccess::IscsiContainerAccess->new(
                     container_id            => $args{container}->getAttr(name => 'container_id'),
                     export_manager_id       => $self->getAttr(name => 'entity_id'),
                     container_access_export => $self->iscsi_node_get_name->node_name,
                     container_access_ip     => $self->service_provider->getMasterNodeIp,
                     container_access_port   => 3260,
                     typeio                  => $args{typeio},
                     iomode                  => $args{iomode},
                     lun_name                => "lun-" . $lun_id
                 );
    my $container_access = EFactory::newEEntity(data => $entity);

    $log->info("Added iSCSI export for lun " .
               $args{container}->getAttr(name => "container_name"));

    if (defined $args{erollback}) {
        $args{erollback}->add(
            function   => $self->can('removeExport'),
            parameters => [ $self, "container_access", $container_access, ]
        );
    }

    return $container_access;
}

=head2 removeExport

    Desc : This method allow to remove an export in 1 call

=cut

sub removeExport {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'container_access' ]);

    if (! $args{container_access}->isa("EEntity::EContainerAccess::EIscsiContainerAccess")) {
        throw Kanopya::Exception::Internal::WrongType(
                  error => "ContainerAccess must be a EEntity::EContainerAccess::EIscsiContainerAccess, not " .
                           ref($args{container_access})
              );
    }

    $args{container_access}->delete();
}

=head2 addExportClient

    Desc : Autorize client to access an export
    args:
        export : export to give access to
        host : host to autorize

=cut

sub addExportClient {
    my $self = shift;
    my %args = @_;

    my $host = $args{host};
    my $lun = $args{export}->getContainer;
    my $cluster = Entity->get(id => $host->getClusterId());
    my $path = $lun->getPath();
    my $initiator_group = 'igroup_kanopya_' . $cluster->getAttr(name => "cluster_name");

    eval {
        $self->_getEntity()->igroup_create('initiator-group-name' => $initiator_group,
                                           'initiator-group-type' => "iscsi");
    };

    eval {
        $log->info("Adding node " . $host->getAttr(name => "host_initiatorname") .
                   " to initiator group " . $initiator_group);
        $self->_getEntity()->igroup_add('initiator'            => $host->getAttr(name => "host_initiatorname"),
                                        'initiator-group-name' => $initiator_group);
    };

    $log->info("Mapping LUN $path to $initiator_group");
    eval {
        my $lun_id = $self->_getEntity()->lun_map('path'            => $path,
                                                  'initiator-group' => $initiator_group);

        $args{export}->setAttr(name  => "number",
                               value => $lun_id->child_get_string("lun-id-assigned"));
        $args{export}->save();
    };
}

sub removeExportClient {
    # TODO: implement removeExportClient
}

=head2

    Desc : Get the LUN id assigned for a client
    args:
        lun : the LUN to get the id from
        host : host to autorize

=cut

sub getLunId {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'lun', 'host' ]);

    $log->debug("Looking for the id of LUN " . $args{lun}->id . " for host " . $args{host}->id);

    # Accept both Container and ContainerAccess
    if ($args{lun}->isa("EEntity::EContainerAccess::EIscsiContainerAccess") ||
        $args{lun}->isa("Entity:ContainerAccess::IscsiContainerAccess")) {
        $args{lun} = $args{lun}->getContainer;
    }

    my $api = $self->_getEntity();
    my @mappings = $api->lun_initiator_list_map_info(
                       'initiator' => lc($args{host}->host_initiatorname)
                   )->child_get("lun-maps")->children_get;

    for my $mapping (@mappings) {
        bless $mapping, "NaObject";
        if ($mapping->path eq $args{lun}->getPath) {
            return $mapping->lun_id;
        }
    }
}

1;
