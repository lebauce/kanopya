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
use base "EEntity::EComponent";

use strict;
use Log::Log4perl "get_logger";
use General;
use String::Random;
use Template;
use EFactory;
use EEntity::EContainerAccess::ELocalContainerAccess;

my $log = get_logger("executor");
my $errmsg;

sub createExport {
    my $self = shift;
    my %args  = @_;

    General::checkParams(args     => \%args,
                         required => [ 'container', 'export_name', 'econtext' ]);

    # Check if the given container is provided by the same
    # storage provider than the nfsd storage provider.
    if ($args{container}->getServiceProvider->getAttr(name => "service_provider_id") !=
        $self->_getEntity()->getAttr(name => "service_provider_id")) {
        throw Kanopya::Exception::Execution(
                  error => "Only local containers can be exported through NFS"
              );
    }

    my $default_client = '10.0.0.0/24'; #$args{container}->getServiceProvider->getMasterNodeIp();

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

    $elocal_access->mount(mountpoint => $mountpoint,
                          econtext   => $args{econtext});

    my $container_access = $self->_getEntity()->addContainerAccess(
                               container   => $args{container},
                               export_path => $mountpoint
                           );

    my $client = $self->addExportClient(export_id      => $container_access->getAttr(name => "container_access_id"),
                                        client_name    => $client_name,
                                        client_options => $client_options);

    $self->update_exports(econtext => $args{econtext});

    $log->info("Added NFS Export of device <$args{export_name}>");

    # Insert an erollback for removeExport here ?
    return $container_access;
}

sub removeExport {
    my $self = shift;
    my %args  = @_;

    General::checkParams(args     => \%args,
                         required => [ 'container_access', 'econtext' ]);

    if (! $args{container_access}->isa("Entity::ContainerAccess::NfsContainerAccess")) {
        throw Kanopya::Exception::Execution(
                  error => "ContainerAccess must be a Entity::ContainerAccess::NfsContainerAccess"
              );
    }

    my $device     = $args{container_access}->getContainer->getAttr(name => 'container_device');
    my $mountdir   = $self->_getEntity()->getMountDir(device => $device);

    my $elocal_access = EEntity::EContainerAccess::ELocalContainerAccess->new(
                            econtainer => EFactory::newEEntity(
                                             data => $args{container_access}->getContainer
                                         )
                        );

    my $retry = 5;
    while ($retry > 0) {
        eval {
            $self->update_exports(econtext => $args{econtext});
            $elocal_access->umount(mountpoint => $mountdir,
                                   econtext   => $args{econtext});
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

    $self->_getEntity->delContainerAccess(container_access => $args{container_access});
}

sub reload {
    my $self = shift;
    $self->generateConf();
}

sub addExportClient {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args     => \%args,
                         required => [ 'export_id', 'client_name', 'client_options' ]);

    return $self->_getEntity()->addExportClient(
               export_id      => $args{export_id},
               client_name    => $args{client_name},
               client_options => $args{client_options}
           );
}

sub update_exports {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['econtext']);

    $self->generate_exports(econtext => $args{econtext});
    $args{econtext}->execute(command => "/usr/sbin/exportfs -rf");
}

sub generate_conf_file {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'template', 'dest', 'data', 'econtext' ]);

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
    $args{econtext}->send(src  => $tmpfile,
                          dest => $args{dest});
    unlink $tmpfile;
}

# generate /etc/default/nfs-common file
sub generate_nfs_common {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['econtext']);

    $self->generate_conf_file(
        template => "nfs-common.tt",
        dest     => "/etc/default/nfs-common",
        data     => $self->_getEntity()->getTemplateDataNfsCommon(),
        econtext => $args{econtext}
    );
}

# generate /etc/default/nfs-kernel-server file
sub generate_nfs_kernel_server {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['econtext']);

    $self->generate_conf_file(
        template => "nfs-kernel-server.tt",
        dest     => "/etc/default/nfs-kernel-server",
        data     => $self->_getEntity()->getTemplateDataNfsKernelServer(),
        econtext => $args{econtext}
    );
}

# generate /etc/exports file
sub generate_exports {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['econtext']);

    $self->generate_conf_file(
        template => "exports.tt",
        dest     => "/etc/exports",
        data     => $self->_getEntity()->getTemplateDataExports(),
        econtext => $args{econtext}
    );
}

1;
