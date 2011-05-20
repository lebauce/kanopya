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
package EEntity::EComponent::EExport::ENfsd3;
use base "EEntity::EComponent::EExport";

use strict;
use Log::Log4perl "get_logger";
use General;
use String::Random;
use Template;

my $log = get_logger("executor");
my $errmsg;

# contructor

sub new {
    my $class = shift;
    my %args = @_;
    my $self = $class->SUPER::new( %args );
    return $self;
}

sub reload {
    my $self = shift;
    $self->generateConf();
}

sub MountDevice {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['econtext','device']);

    # create directory if necessary
    my $dir = $self->_getEntity()->getMountDir(device => $args{device});
    my $command = "mkdir -p $dir; chmod 777 $dir";
    $args{econtext}->execute(command => $command);

    # check if nothing is mounted on directory
    $command = "mount | grep $dir";
    my $result = $args{econtext}->execute(command => $command);
    if($result->{stdout}) {
        $errmsg = "EComponent::EExport::ENfsd3->MountDevice : $dir already used as mount point by \n($result->{stdout})";
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
    
    my $export_id = $self->_getEntity()->addExport(device => $args{device});
    $self->MountDevice(device => $args{device}, econtext => $args{econtext});
    return $export_id;
}

sub addExportClient {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['export_id','client_name','client_options']);
    
    $self->_getEntity()->addExportClient(
        export_id => $args{export_id},
        client_name => $args{client_name},
        client_options => $args{client_options}
    );
}

sub update_exports {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['econtext']);

    $self->generate_exports(econtext => $args{econtext});
    my $command = "/usr/sbin/exportfs -r";
    $args{econtext}->execute(command => $command);
}

# generate /etc/default/nfs-common file
sub generate_nfs_common {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['econtext']);
        
    my $config = {
        INCLUDE_PATH => '/templates/components/nfsd3',
        INTERPOLATE  => 1,               # expand "$var" in plain text
        POST_CHOMP   => 0,               # cleanup whitespace 
        EVAL_PERL    => 1,               # evaluate Perl code blocks
        RELATIVE => 1,                   # desactive par defaut
    };
    
    my $rand = new String::Random;
    my $tmpfile = $rand->randpattern("cccccccc");
    # create Template object
    my $template = Template->new($config);
    my $input = "nfs-common.tt";
    my $data = $self->_getEntity()->getTemplateDataNfsCommon();
    
    $template->process($input, $data, "/tmp/".$tmpfile) || do {
        $errmsg = "EComponent::EExport::ENfsd3->generate_nfs_common : error during template generation : $template->error;";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);    
    };
    $args{econtext}->send(src => "/tmp/$tmpfile", dest => "/etc/default/nfs-common");    
    unlink "/tmp/$tmpfile";        
}

# generate /etc/default/nfs-kernel-server file
sub generate_nfs_kernel_server {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['econtext']);
        
    my $config = {
        INCLUDE_PATH => '/templates/components/nfsd3',
        INTERPOLATE  => 1,               # expand "$var" in plain text
        POST_CHOMP   => 0,               # cleanup whitespace 
        EVAL_PERL    => 1,               # evaluate Perl code blocks
        RELATIVE => 1,                   # desactive par defaut
    };
    
    my $rand = new String::Random;
    my $tmpfile = $rand->randpattern("cccccccc");
    # create Template object
    my $template = Template->new($config);
    my $input = "nfs-kernel-server.tt";
    my $data = $self->_getEntity()->getTemplateDataNfsKernelServer();
    
    $template->process($input, $data, "/tmp/".$tmpfile) || do {
        $errmsg = "EComponent::EExport::ENfsd3->generate_nfs_kernel_server : error during template generation : $template->error;";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);    
    };
    $args{econtext}->send(src => "/tmp/$tmpfile", dest => "/etc/default/nfs-kernel-server");    
    unlink "/tmp/$tmpfile";    
}

# generate /etc/exports file
sub generate_exports {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['econtext']);
        
    my $config = {
        INCLUDE_PATH => '/templates/components/nfsd3',
        INTERPOLATE  => 1,               # expand "$var" in plain text
        POST_CHOMP   => 0,               # cleanup whitespace 
        EVAL_PERL    => 1,               # evaluate Perl code blocks
        RELATIVE => 1,                   # desactive par defaut
    };
    
    my $rand = new String::Random;
    my $tmpfile = $rand->randpattern("cccccccc");
    # create Template object
    my $template = Template->new($config);
    my $input = "exports.tt";
    my $data = $self->_getEntity()->getTemplateDataExports();
    
    $template->process($input, $data, "/tmp/".$tmpfile) || do {
        $errmsg = "EComponent::EExport::ENfsd3->generate_exports : error during template generation : $template->error;";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);    
    };
    $args{econtext}->send(src => "/tmp/$tmpfile", dest => "/etc/exports");    
    unlink "/tmp/$tmpfile";
}

1;
