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
use EFactory;
use Entity::ContainerAccess::NfsContainerAccess;
use EEntity::EContainerAccess::ELocalContainerAccess;

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
                         required => [ 'container', 'export_name' ],
                         optional => { 'client_name'    => '*',
                                       'client_options' => 'rw,sync,no_root_squash' });

    # Check if the given container is provided by the same
    # storage provider than the nfsd storage provider.
    if ($args{container}->getServiceProvider->getAttr(name => "service_provider_id") !=
        $self->_getEntity()->getAttr(name => "service_provider_id")) {
        throw Kanopya::Exception::Execution(
                  error => "Only local containers can be exported through NFS"
              );
    }

    # Check if the disk is not already exported
    $self->SUPER::createExport(%args);

    # Keep the old conf to be able to regenerate the conf file if the export fail.
    my $old_data = $self->getTemplateDataExports();

    my $mountpoint = $self->getMountDir(
                         device => $args{container}->getAttr(name => 'container_device')
                     );

    my $elocal_access = EEntity::EContainerAccess::ELocalContainerAccess->new(
                            econtainer => $args{container}
                        );

    $elocal_access->mount(mountpoint => $mountpoint, econtext => $self->getEContext, erollback => $args{erollback});

    my $manager_ip = $self->getServiceProvider->getMasterNodeIp;
    my $mount_dir  = $self->getMountDir(device => $args{container}->getAttr(name => 'container_device'));

    my $entity = Entity::ContainerAccess::NfsContainerAccess->new(
                     container_id            => $args{container}->getAttr(name => 'container_id'),
                     export_manager_id       => $self->_getEntity->getAttr(name => 'entity_id'),
                     container_access_export => $manager_ip . ':' . $mount_dir,
                     container_access_ip     => $manager_ip,
                     container_access_port   => 2049,
                     options                 =>  $args{client_options},
                 );


    my $container_access = EFactory::newEEntity(data => $entity);
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

    $self->updateExports();

    # Update the configuration of the component Mounttable of the cluster,
    # to automatically mount the images repositories.
    my $cluster = Entity::ServiceProvider->get(id => $self->getAttr(name => 'service_provider_id'));
    my $mounttable = $cluster->getComponent(name => "Linux", version => "0");

    my $oldconf = $mounttable->getConf();
    my @mountentries = @{$oldconf->{linux0s_mount}};
    push @mountentries, {
        linux0_mount_dumpfreq   => 0,
        linux0_mount_filesystem => 'nfs',
        linux0_mount_point      => $mountpoint,
        linux0_mount_device     => $args{container}->getAttr(name => 'container_device'),
        linux0_mount_options    => 'rw',
        linux0_mount_passnum    => 0,
    };

    $mounttable->setConf(conf => { linux0s_mount => \@mountentries });

    my $emounttable = EFactory::newEEntity(data => $mounttable);
    $emounttable->_generateFstab(cluster => $cluster, host => $cluster->getMasterNode);

    $log->info("Added NFS Export of device <$args{export_name}>");

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

    my $device   = $args{container_access}->getContainer->getAttr(name => 'container_device');
    my $mountdir = $self->getMountDir(device => $device);

    my $elocal_access = EEntity::EContainerAccess::ELocalContainerAccess->new(
                            econtainer => EFactory::newEEntity(
                                             data => $args{container_access}->getContainer
                                          )
                        );

    $args{container_access}->delete();

    $self->generateExports(data => $self->getTemplateDataExports());

    my $retry = 5;
    while ($retry > 0) {
        eval {
            $self->updateExports();
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
}

sub reload {
    my $self = shift;
    $self->generateConf();
}

sub addExportClient {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args     => \%args,
                         required => [ 'export', 'host', 'options' ]);

    return $self->_getEntity()->addExportClient(
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

sub generateConfFile {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'template', 'dest', 'data' ]);

    my $config = {
        INCLUDE_PATH => '/templates/components/nfsd3',
        INTERPOLATE  => 1,               # expand "$var" in plain text
        POST_CHOMP   => 0,               # cleanup whitespace 
        EVAL_PERL    => 1,               # evaluate Perl code blocks
        RELATIVE     => 1,               # disabled by default
    };

    my $rand = new String::Random;
    my $tmpfile = "/tmp/" . $rand->randpattern("cccccccc");

    # create Template object
    my $template = Template->new($config);

    $template->process($args{template}, $args{data}, $tmpfile) || do {
        $errmsg = "Error while generating NFS configuration file $template" . $template->error;
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);    
    };
    $self->getEContext->send(src  => $tmpfile,
                             dest => $args{dest});
    unlink $tmpfile;
}

# generate /etc/default/nfs-common file
sub generateNfsCommon {
    my $self = shift;
    my %args = @_;

    $self->generateConfFile(
        template => "nfs-common.tt",
        dest     => "/etc/default/nfs-common",
        data     => $self->getTemplateDataNfsCommon(),
    );
}

# generate /etc/default/nfs-kernel-server file
sub generateNfsKernelServer {
    my $self = shift;
    my %args = @_;

    $self->generateConfFile(
        template => "nfs-kernel-server.tt",
        dest     => "/etc/default/nfs-kernel-server",
        data     => $self->getTemplateDataNfsKernelServer(),
    );
}

# generate /etc/exports file
sub generateExports {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'data' ]);

    $self->generateConfFile(
        template => "exports.tt",
        dest     => "/etc/exports",
        data     => $args{data},
    );
}

1;
