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

use Log::Log4perl "get_logger";

my $log = get_logger("executor");
my $errmsg;

sub createExport {
    my $self = shift;
    my %args  = @_;

    General::checkParams(args     => \%args,
                         required => [ 'container', 'export_name' ]);

    # Check if the given container is provided by the same
    # storage provider than the nfsd storage provider.
    if ($args{container}->getServiceProvider->getAttr(name => "service_provider_id") !=
        $self->_getEntity()->getAttr(name => "service_provider_id")) {
        throw Kanopya::Exception::Execution(
                  error => "Only local containers can be exported through NFS"
              );
    }

    my $default_client = '*';

    my $client_name = General::checkParam(args    => \%args,
                                          name    => 'client_name',
                                          default => $default_client);

    my $client_options = General::checkParam(args    => \%args,
                                             name    => 'client_options',
                                             default => 'rw,sync,no_root_squash');

    my $mountpoint = $self->_getEntity()->getMountDir(
                         device => $args{container}->getAttr(name => 'container_device')
                     );

    my $elocal_access = EEntity::EContainerAccess::ELocalContainerAccess->new(
                            econtainer => EFactory::newEEntity(data => $args{container})
                        );

    $elocal_access->mount(mountpoint => $mountpoint, econtext => $self->getEContext);

    my $manager_ip = $self->_getEntity->getServiceProvider->getMasterNodeIp;
    my $mount_dir  = $self->_getEntity->getMountDir(device => $args{container}->getAttr(name => 'container_device'));

    my $entity = Entity::ContainerAccess::NfsContainerAccess->new(
                     container_id            => $args{container}->getAttr(name => 'container_id'),
                     export_manager_id       => $self->_getEntity->getAttr(name => 'entity_id'),
                     container_access_export => $manager_ip . ':' . $mount_dir,
                     container_access_ip     => $manager_ip,
                     container_access_port   => 2049,
                     options                 =>  $client_options,
                 );
    my $container_access = EFactory::newEEntity(data => $entity);

    my $client = $self->addExportClient(export         => $container_access,
                                        client_name    => $client_name,
                                        client_options => $client_options);

    $self->updateExports();

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

    $args{container_access}->delete();
}

sub reload {
    my $self = shift;
    $self->generateConf();
}

sub addExportClient {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args     => \%args,
                         required => [ 'export', 'client_name', 'client_options' ]);

    return $self->_getEntity()->addExportClient(
               export_id      => $args{export}->getAttr(name => "container_access_id"),
               client_name    => $args{client_name},
               client_options => $args{client_options}
           );
}

sub updateExports {
    my $self = shift;
    my %args = @_;

    $self->generateExports();
    $self->getEContext->execute(command => "/usr/sbin/exportfs -rf");
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
        data     => $self->_getEntity()->getTemplateDataNfsCommon(),
    );
}

# generate /etc/default/nfs-kernel-server file
sub generateNfsKernelServer {
    my $self = shift;
    my %args = @_;

    $self->generateConfFile(
        template => "nfs-kernel-server.tt",
        dest     => "/etc/default/nfs-kernel-server",
        data     => $self->_getEntity()->getTemplateDataNfsKernelServer(),
    );
}

# generate /etc/exports file
sub generateExports {
    my $self = shift;
    my %args = @_;

    $self->generateConfFile(
        template => "exports.tt",
        dest     => "/etc/exports",
        data     => $self->_getEntity()->getTemplateDataExports()
    );
}

1;
