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

my $log = get_logger("executor");
my $errmsg;

sub createExport {
    my $self = shift;
    my %args  = @_;

    General::checkParams(args     => \%args,
                         required => [ 'container', 'export_name', 'econtext' ]);

    # TODO: Check if the given container is provided by the same
    #       storage provider than the nfsd storage provider.

    my $default_client = $args{container}->getServiceProvider->getMasterNodeIp();

    my $client_name = General::checkParam(args => \%args, name => 'client_name', default => $default_client);
    my $client_options = General::checkParam(args => \%args, name => 'client_options', default => 'rw,sync');

    my $export_id = $self->addExport(container => $args{container},
                                     device    => $args{export_name},
                                     econtext  => $args{econtext});

    my $client_id = $self->addExportClient(export_id      => $export_id,
                                           client_name    => $client_name,
                                           client_options => $client_options);

    $self->update_exports(econtext => $args{econtext});

    my $container_access = $self->_getEntity()->addContainerAccess(
                               container => $args{container},
                               export_id => $export_id,
                               client_id => $client_id,
                           );

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

    # TODO: Really remove the export from nfsd3 internal tables,
    #       and from nfsd configuration files.
    my $device = $args{container_access}->getContainer->getAttr(name => 'container_device');
    my $mountdir = $self->_getEntity()->getMountDir(device => $device);

    my $command = "umount $mountdir";
    $args{econtext}->execute(command => $command);

    $self->_getEntity()->delContainerAccess(container_access => $args{container_access});
}

sub reload {
    my $self = shift;
    $self->generateConf();
}

sub mountDevice {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['econtext', 'device']);

    # create directory if necessary
    my $dir = $self->_getEntity()->getMountDir(device => $args{device});

    my $command = "mkdir -p $dir; chmod 777 $dir";
    $args{econtext}->execute(command => $command);

    # check if nothing is mounted on directory
    $command = "mount | grep $dir";
    my $result = $args{econtext}->execute(command => $command);
    if($result->{stdout}) {
        $errmsg = "EComponent::ENfsd3->mountDevice : $dir already used as mount point by \n($result->{stdout})";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
    }
    $command = "mount $args{device} $dir";
    $args{econtext}->execute(command => $command);
}

sub addExport {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['econtext', 'device']);
    
    my $export_id = $self->_getEntity()->addExport(device => $args{device},
                                                   container => $args{container});
    $self->mountDevice(device => $args{device},
                       econtext => $args{econtext});
    return $export_id;
}

sub addExportClient {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args     => \%args,
                         required => ['export_id', 'client_name', 'client_options']);

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
    $args{econtext}->execute(command => "/usr/sbin/exportfs -r");
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
        RELATIVE => 1,                   # desactive par defaut
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

sub createDisk {
    
}

sub removeDisk {
    
}

1;
