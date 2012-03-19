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
use base 'Entity::Connector', 'Entity::Connector::NetappManager';

use warnings;
use Entity::Container::NetappLun;
use Administrator;

use Log::Log4perl "get_logger";
my $log = get_logger("administrator");

use constant ATTR_DEF => {
};

sub getAttrDef { return ATTR_DEF; }

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
            storage_provider_id => $self->getAttr(name => 'service_provider_id'),
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

=head2 getContainer

    Desc : Implement getContainer from DiskManager interface.
           This function return the container hash that match
           identifiers given in paramters.
    args : lv_id

=cut

sub getContainer {
    my $self = shift;
    my %args = @_;

    my $lun = Entity::Container::NetappLun->find(hash => \%args);

    my $container = {
        container_name       => $lun->{_dbix}->get_column('name'),
        container_size       => $lun->{_dbix}->get_column('size'),
        container_filesystem => $lun->{_dbix}->get_column('filesystem'),
        container_device     => $lun->{_dbix}->get_column('name'),
        container_freespace  => $self->getFreeSpace(),
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

    General::checkParams(args => \%args, required => [ "volume_id", "name",
                                                       "size", "filesystem" ]);

    my $container = Entity::Container::NetappLun->new(
                        service_provider_id => $self->getAttr(name => 'service_provider_id'),
                        disk_manager_id     => $self->getAttr(name => 'connector_id'),
                        name                => $args{name},
                        size                => $args{size},
                        filesystem          => $args{filesystem},
                        volume_id           => $args{volume_id}
                    );

    my $container_id = $container->getAttr(name => 'container_id');
    $log->info("LUN container <$container_id> saved to database");

    print "DONE CREATEING NETAPPLUN\n";

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
                         required => [ "container", "export_name", "typeio", "iomode" ]);

    $log->debug("New Operation CreateExport with attrs : " . %args);
    Operation->enqueue(
        priority => 200,
        type     => 'CreateExport',
        params   => {
            storage_provider_id => $self->getAttr(name => 'service_provider_id'),
            export_manager_id   => $self->getAttr(name => 'component_id'),
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

=head2 getContainerAccess

    Desc : Implement getContainerAccess from ExportManager interface.
           This function return the container access hash that match
           identifiers given in paramters.
    args : lun_id, target_id

=cut

sub getContainerAccess {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "lun_id", "target_id" ]);

    my $target_rs = $self->{_dbix}->iscsitarget1_targets->find($args{target_id});

    my $container = {
        container_access_export => $target_rs->get_column('iscsitarget1_target_name'),
        container_access_ip     => $self->{netapp}->getMasterNodeIp(),
        container_access_port   => 3260,
    };

    return $container;
}

=head2 addContainerAccess

    Desc : Implement addContainerAccess from ExportManager interface.
           This function create a new IscsiContainerAccess into database.
    args : container, target_id, lun_id

=cut

sub addContainerAccess {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "container", "target_id", "lun_id" ]);

    my $access = Entity::ContainerAccess::IscsiContainerAccess->new(
                     container_id      => $args{container}->getAttr(name => 'container_id'),
                     export_manager_id => $self->getId(),
                     target_id         => $args{target_id},
                     lun_id            => $args{lun_id},
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

    Desc: synchronize netapp lun information with kanopya database

=cut 

sub synchronize {
    my ($self) = @_;
 
}

1;
