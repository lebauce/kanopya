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

package EEntity::EConnector::ENetappLunManager;
use base "EEntity::EConnector";

use warnings;
use strict;

use General;
use EContext::Local;
use Kanopya::Exceptions;
use Entity::Container::NetappLun;

use Data::Dumper;
use Log::Log4perl "get_logger";

my $log = get_logger("executor");
my $errmsg;

=head2 createDisk

createDisk ( name, size, filesystem, econtext )
    desc: This function creates a new volume on NetApp.
    args:
        name : string : new volume name
        size : String : disk size finishing by unit (M : Mega, K : kilo, G : Giga)
        filesystem : String : filesystem type
        econtext : Econtext : execution context on the storage server
    return:
        1 if an error occurred, 0 otherwise
    
=cut

sub createDisk {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "volume_id", "name", "size", "filesystem", "econtext" ]);

    my $volume = Entity::Container::NetappVolume->get(id => $args{volume_id});
    my $volume_name = "/vol/" . $volume->getAttr(name => "container_name") . "/" . $args{name};

    # Make the XML RPC call
    my $api = $self->_getEntity();
    $api->lun_create_by_size(path => $volume_name,
                             size => $args{size},
                             type => "linux");

    my $noformat = $args{"noformat"};
    my $econtext = $args{econtext};
    delete $args{noformat};
    delete $args{econtext};

    # Insert the container into the database
    my $container = Entity::Container::NetappLun->new(
                        disk_manager_id      => $self->_getEntity->getAttr(name => 'entity_id'),
                        container_name       => $args{name},
                        container_size       => $args{size},
                        container_filesystem => $args{filesystem},
                        container_freespace  => 0,
                        container_device     => $args{name},
                        volume_id            => $args{volume_id}
                    );

    if (! defined $noformat) {
        # Connect to the iSCSI target and format it locally

        my $export = $self->createExport(container   => $container,
                                         export_name => $args{name},
                                         econtext    => $econtext,
                                         erollback   => $args{erollback});

        my $container_access = EFactory::newEEntity(data => $export);
        my $local_context    = EContext::Local->new(local => '127.0.0.1');

        my $newdevice = $container_access->connect(econtext => $local_context);

        $self->mkfs(device   => $newdevice,
                    fstype   => $args{filesystem},
                    econtext => $local_context);

        $container_access->disconnect(econtext => $local_context);

        $self->removeExport(container_access => $export,
                            econtext         => $local_context);
    }

    if (exists $args{erollback} and defined $args{erollback}){
        $args{erollback}->add(
            function   => $self->can('removeDisk'),
            parameters => [ $self, "container", $container, "econtext", $args{econtext} ]
        );
    }

    return $container;
}

=head2 removeDisk

=cut

sub removeDisk {
    my $self = shift;
    my %args = @_;

    General::checkParams(args=>\%args, required=>[ "container", "econtext" ]);

    if (! $args{container}->isa("Entity::Container::NetappLun")) {
        throw Kanopya::Exception::Execution(
                  error => "Container must be a Entity::Container::NetappLun"
              );
    }

    $self->_getEntity()->lun_destroy(path => $args{container}->getPath());

    $args{container}->delete();

    #TODO: insert erollback ?
}

=head2 mkfs

_mkfs ( device, fstype, fsoptions, econtext)
    desc: This function create a filesystem on a device.
    args:
        device : string: device full path (like /dev/sda2 or /dev/vg/lv)
        fstype : string: name of filesystem (ext2, ext3, ext4)
        fsoptions : string: filesystem options to use during creation (optional) 
        econtext : Econtext : execution context on the storage server
=cut

sub mkfs {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "device", "fstype", "econtext" ]);
    
    my $command = "mkfs -F -t $args{fstype} ";
    if($args{fsoptions}) {
        $command .= "$args{fsoptions} ";
    }

    $command .= " $args{device}";
    my $ret = $args{econtext}->execute(command => $command);
    if($ret->{exitcode} != 0) {
        my $errmsg = "Error during execution of $command ; stderr is : $ret->{stderr}";
        $log->error($errmsg);
        throw Kanopya::Exception::Execution(error => $errmsg);
    }
}

=head2 createExport

    Desc : This method allow to create a new export in 1 call

=cut

sub createExport {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ 'container', 'export_name', 'econtext' ]);

    my $typeio = General::checkParam(args => \%args, name => 'typeio', default => 'fileio');
    my $iomode = General::checkParam(args => \%args, name => 'iomode', default => 'wb');

    my $api = $self->_getEntity();
    my $volume = $args{container}->getVolume();
    my $lun_path = $args{container}->getPath();

    my $kanopya_cluster = Entity::ServiceProvider::Inside::Cluster->find(
                             hash => {
                                 cluster_name => 'Kanopya'
                             }
                         );

    my $master = $kanopya_cluster->getMasterNode();

    eval {
        $self->_getEntity()->igroup_create(initiator_group_name => "igroup_kanopya_master",
                                           initiator_group_type => "iscsi");
    };

    eval {
        $self->_getEntity()->igroup_add(initiator            => $master->getAttr(name => "host_initiatorname"),
                                        initiator_group_name => "igroup_kanopya_master");
    };

    my $lun_id;
    eval {
        $lun_id = $api->lun_map(path            => $lun_path,
                                initiator_group => 'igroup_kanopya_master')->child_get_string("lun-id-assigned");
    };
    if ($@) {
        # The LUN is already mapped, get its lun ID
        my @mappings = $api->lun_initiator_list_map_info(
                           initiator => $master->getAttr(name => "host_initiatorname")
                       )->child_get("lun-maps")->children_get;

        for my $mapping (@mappings) {
            bless $mapping, "NaObject";
            if ($mapping->path eq $lun_path) {
                $lun_id = $mapping->lun_id;
            }
        }
    }

    my $container_access = Entity::ContainerAccess::IscsiContainerAccess->new(
                               container_id            => $args{container}->getAttr(name => 'container_id'),
                               export_manager_id       => $self->_getEntity->getAttr(name => 'entity_id'),
                               container_access_export => $self->_getEntity->iscsi_node_get_name->node_name,
                               container_access_ip     => $self->_getEntity->getServiceProvider->getMasterNodeIp,
                               container_access_port   => 3260,
                               typeio                  => $typeio,
                               iomode                  => $iomode,
                               lun_name                => "lun-" . $lun_id
                           );

    $log->info("Added iSCSI export for lun " .
               $args{container}->getAttr(name => "container_name"));

    if (defined $args{erollback}) {
        my $eroll_add_export = $args{erollback}->getLastInserted();
        $args{erollback}->insertNextErollBefore(erollback => $eroll_add_export);

        $args{erollback}->add(
            function   => $self->can('removeExport'),
            parameters => [ $self,
                            "container_access", $container_access,
                            "econtext", $args{econtext} ]
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

    General::checkParams(args     => \%args,
                         required => [ 'container_access', 'econtext' ]);

    if (! $args{container_access}->isa("Entity::ContainerAccess::IscsiContainerAccess")) {
        throw Kanopya::Exception::Execution::WrongType(
                  error => "ContainerAccess must be a Entity::ContainerAccess::IscsiContainerAccess"
              );
    }

    my $log_content      = "";
    my $container_access = $args{container_access};
    my $container        = $container_access->getContainer();
    my $export_name      = $container_access->getAttr(name => "container_access_id");

    $args{container_access}->delete();

    $log_content = "Remove export with export name <" . $export_name . ">";
    if(exists $args{erollback} and defined $args{erollback}) {
        $args{erollback}->add(
            function   => $self->can('createExport'),
            parameters => [ $self,
                            "container", $container,
                            "export_name", $export_name,
                            "econtext", $args{econtext} ]);

       $log_content .= " and will be rollbacked with add export of disk <" .
                       $container->getAttr(name => 'container_device') . ">";
    }

    $log->debug($log_content);
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
        $self->_getEntity()->igroup_create(initiator_group_name => $initiator_group,
                                           initiator_group_type => "iscsi");
    };

    eval {
        $log->info("Adding node " . $host->getAttr(name => "host_initiatorname") .
                   " to initiator group " . $initiator_group);
        $self->_getEntity()->igroup_add(initiator            => $host->getAttr(name => "host_initiatorname"),
                                        initiator_group_name => $initiator_group);
    };

    $log->info("Mapping LUN $path to $initiator_group");
    eval {
        my $lun_id = $self->_getEntity()->lun_map(path            => $path,
                                                  initiator_group => $initiator_group);

        $args{export}->setAttr(name  => "number",
                               value => $lun_id->child_get_string("lun-id-assigned"));
        $args{export}->save();
    };
}

sub removeExportClient {
    # TODO: implement removeExportClient
}

1;
