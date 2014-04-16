#    Copyright © 2011 Hedera Technology SAS
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

package EEntity::EComponent::ENfsd3;
use base "EManager::EExportManager";
use base "EEntity::EComponent";

use strict;
use warnings;

use General;
use Template;
use Entity::ContainerAccess::NfsContainerAccess;
use Entity::ContainerAccess::LocalContainerAccess;

use Kanopya::Exceptions;
use String::Random;

use Data::Dumper;
use Log::Log4perl "get_logger";

my $log = get_logger("");
my $errmsg;

sub createExport {
    my $self = shift;
    my %args  = @_;

    General::checkParams(args     => \%args,
                         required => [ 'container' ],
                         optional => { 'client_name'    => '*',
                                       'client_options' => 'rw,sync,no_root_squash' });

    # Check if the given container is provided by the same
    # storage provider than the nfsd storage provider.
    if ((! $args{container}->isa("EEntity::EContainer::ELocalContainer")) &&
        ($args{container}->disk_manager->getMasterNode->host->id != $self->getMasterNode->host->id)) {
        throw Kanopya::Exception::Execution(
                  error => "Only local containers can be exported through NFS"
              );
    }

    # Check if the disk is not already exported
    $self->SUPER::createExport(%args);

    # Keep the old conf to be able to regenerate the conf file if the export fail.
    my $old_data = $self->getTemplateDataExports();

    my $mountpoint = $self->getMountDir(container => $args{container}->_entity);

    if (! $args{container}->isa("EEntity::EContainer::ELocalContainer")) {
        # Create a local access to the container to be able to mount localy the device
        # and then export the mountpoint with NFS.
        my $elocal_access = EEntity->new(entity => Entity::ContainerAccess::LocalContainerAccess->new(
                                container_id => $args{container}->id,
                            ));

        # Update the configuration of the component Mounttable of the cluster,
        # to automatically mount the images repositories.
        my $system = $self->service_provider->getComponent(category => "System");
        my $esystem = EEntity->new(entity => $system);

        $esystem->addMount(
            dumpfreq   => 0,
            filesystem => $args{container}->container_filesystem,
            mountpoint => $mountpoint,
            device     => $args{container}->container_device,
            options    => 'rw',
            passnum    => 0,
        );

        $esystem->generateConfiguration(cluster => $self->service_provider,
                                        host => $self->getMasterNode->host);

        $self->applyConfiguration(tags => [ 'mount' ]);
    }

    my $manager_ip = $self->getMasterNode->adminIp;

    my $entity = Entity::ContainerAccess::NfsContainerAccess->new(
                     container               => $args{container}->_entity,
                     export_manager          => $self->_entity,
                     container_access_export => $manager_ip . ':' . $mountpoint,
                     container_access_ip     => $manager_ip,
                     container_access_port   => 2049,
                     options                 => $args{client_options},
                 );

    my $container_access = EEntity->new(data => $entity);
    my $client = $self->addExportClient(export  => $container_access,
                                        host    => $args{client_name},
                                        options => $args{client_options});

    $self->generateExports(data => $self->getTemplateDataExports());
    if (exists $args{erollback}) {
        $args{erollback}->add(
            function   => $self->can('generateExports'),
            parameters => [ $self, "data", $old_data ]
        );
    }

    $self->applyConfiguration(tags => [ 'kanopya::nfsd' ]);
    $self->updateExports();

    $log->info("Added NFS Export <" . $container_access->container_access_export . ">");

    if (exists $args{erollback}) {
        $args{erollback}->add(
            function   => $self->can('removeExport'),
            parameters => [ $self, "container_access", $container_access ]
        );
    }

    return $container_access;
}

sub removeExport {
    my $self = shift;
    my %args  = @_;

    General::checkParams(args => \%args, required => [ 'container_access' ]);

    if (! $args{container_access}->isa("EEntity::EContainerAccess::ENfsContainerAccess")) {
        throw Kanopya::Exception::Internal::WrongType(
                  error => "ContainerAccess must be a EEntity::EContainerAccess::ENfsContainerAccess, not " .
                           ref($args{container_access})
              );
    }

    if (! $args{container_access}->getContainer->isa("Entity::Container::LocalContainer")) {
        my $mountdir = $self->getMountDir(container => $args{container_access}->getContainer);
        my $elocal_access = EEntity->new(entity => $args{container_access}->getContainer->getLocalAccess);

        my $retry = 5;
        while ($retry > 0) {
            eval {
                $elocal_access->umount(mountpoint => $mountdir, econtext => $self->getEContext);
            };
            if ($@) {
                $log->info("Unable to umount <$mountdir>, retrying in 1s...");
                $retry--;
                if (!$retry){
                    throw Kanopya::Exception::Execution(
                              error => "Unable to umount nfs mountpoint $mountdir: $@"
                          );
                }
                sleep 1;
                next;
            }
            last;
        }

        $elocal_access->delete();

        # Update the configuration of the component Mounttable of the cluster,
        # to automatically mount the images repositories.
        my $system = $self->service_provider->getComponent(category => "System");
        $system->removeMount(mountpoint => $mountdir);
        $self->applyConfiguration(tags => [ 'mount' ]);
    }

    $args{container_access}->remove();
    $self->updateExports();
    $self->generateExports(data => $self->getTemplateDataExports());
}


sub addExportClient {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args     => \%args,
                         required => [ 'export', 'host', 'options' ]);

    return $self->_entity->addExportClient(
               export_id      => $args{export}->getAttr(name => "container_access_id"),
               client_name    => $args{host},
               client_options => $args{options}
           );
}

sub updateExports {
    my $self = shift;
    my %args = @_;
    
    my $result = $self->getEContext->execute(command => "/usr/sbin/exportfs -rf");
    
    ### NFS BUG :
    # expoortfs command return no null exitcode with message
    # exportfs: /proc/fs/nfs/exports:1: unknown keyword "test-client-(rw
    
    #if ($result->{exitcode} != 0) {
    #    $errmsg = "Error while updating nfs exports: " . $result->{stderr};
    #    throw Kanopya::Exception::Execution(error => $errmsg);
    #}
}

# generate /etc/default/nfs-common file
sub generateNfsCommon {
    my $self = shift;
    my %args = @_;

    $self->generateNodeFile(
        file          => "/etc/default/nfs-common",
        template_dir  => 'components/nfsd3',
        template_file => 'nfs-common.tt',
        data          => $self->getTemplateDataNfsCommon(),
        send          => 1
    );
}

# generate /etc/default/nfs-kernel-server file
sub generateNfsKernelServer {
    my $self = shift;
    my %args = @_;

    $self->generateNodeFile(
        file          => "/etc/default/nfs-kernel-server",
        template_dir  => 'components/nfsd3',
        template_file => 'nfs-kernel-server.tt',
        data          => $self->getTemplateDataNfsKernelServer(),
        send          => 1
    );
}

# generate /etc/exports file
sub generateExports {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'data' ]);

    $self->generateNodeFile(
        file          => "/etc/exports",
        template_dir  => 'components/nfsd3',
        template_file => 'exports.tt',
        data          => $args{data},
        send          => 1
    );
}

1;
