package EEntity::EComponent::EExport::ENfsd3;

use strict;
use Log::Log4perl "get_logger";
use Template;
use String::Random;

use base "EEntity::EComponent::EExport";

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
	if((! exists $args{econtext} or ! defined $args{econtext}) ||
	  (! exists $args{device} or ! defined $args{device})) {
		$errmsg = "EComponent::EExport::ENfsd3->mkMountDirectory needs a econtext and device named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}

	# create directory if necessary
	my $dir = $self->_getEntity()->getMountDir(device => $args{device});
	my $command = "mkdir -p $dir";
	$args{econtext}->execute(command => $command);

	# check if nothing is mounted on directory
	$command = "mount | grep $dir";
	my $result = $args{econtext}->execute(command => $command);
	if($result->{stdout}) {
		$errmsg = "EComponent::EExport::ENfsd3->MountDevice : $dir already used as mount point by \n($result->{stdout})";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	$command = "mount $args{device} $dir";
	$args{econtext}->execute(command => $command);
}

sub addExport {
	my $self = shift;
	my %args = @_;
	if ((! exists $args{device} or ! defined $args{device}) ||
		(! exists $args{econtext} or ! defined $args{econtext})) {
		$errmsg = "EComponent::EExport::EIscsitarget1->addExport needs a device and econtext named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	my $export_id = $self->_getEntity()->addExport(device => $args{device});
	$self->MountDevice(device => $args{device}, econtext => $args{econtext});
	return $export_id;
}

sub addExportClient {
	my $self = shift;
	my %args = @_;
	if ((! exists $args{export_id} or ! defined $args{export_id}) ||
		(! exists $args{client_name} or ! defined $args{client_name}) ||
		(! exists $args{client_options} or ! defined $args{client_options})) {
		$errmsg = "EComponent::EExport::ENfsd3->addExportClient needs a export_id, client_name and client_options named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	$self->_getEntity()->addExportClient(
		export_id => $args{export_id},
		client_name => $args{client_name},
		client_options => $args{client_options}
	);
}

sub update_exports {
	my $self = shift;
	my %args = @_;
	if(! exists $args{econtext} or ! defined $args{econtext}) {
		$errmsg = "EComponent::EExport::ENfsd3->update_exports needs a econtext named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	$self->generate_exports(econtext => $args{econtext});
	my $command = "/usr/sbin/exportfs -r";
	$args{econtext}->execute(command => $command);
}

# generate /etc/default/nfs-common file
sub generate_nfs_common {
	my $self = shift;
	my %args = @_;
	if(! exists $args{econtext} or ! defined $args{econtext}) {
		$errmsg = "EComponent::EExport::ENfsd3->generate_nfs_common needs a econtext named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
		
	my $config = {
	    INCLUDE_PATH => '/templates/components/mcsnfsd3',
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
		throw Mcs::Exception::Internal(error => $errmsg);	
	};
	$args{econtext}->send(src => "/tmp/$tmpfile", dest => "/etc/default/nfs-common");	
	unlink "/tmp/$tmpfile";		
}

# generate /etc/default/nfs-kernel-server file
sub generate_nfs_kernel_server {
	my $self = shift;
	my %args = @_;
	if(! exists $args{econtext} or ! defined $args{econtext}) {
		$errmsg = "EComponent::EExport::ENfsd3->generate_nfs_kernel_server needs a econtext named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
		
	my $config = {
	    INCLUDE_PATH => '/templates/components/mcsnfsd3',
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
		throw Mcs::Exception::Internal(error => $errmsg);	
	};
	$args{econtext}->send(src => "/tmp/$tmpfile", dest => "/etc/default/nfs-kernel-server");	
	unlink "/tmp/$tmpfile";	
}

# generate /etc/exports file
sub generate_exports {
	my $self = shift;
	my %args = @_;
	if(! exists $args{econtext} or ! defined $args{econtext}) {
		$errmsg = "EComponent::EExport::ENfsd3->generate_exports needs a econtext named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
		
	my $config = {
	    INCLUDE_PATH => '/templates/components/mcsnfsd3',
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
		throw Mcs::Exception::Internal(error => $errmsg);	
	};
	$args{econtext}->send(src => "/tmp/$tmpfile", dest => "/etc/exports");	
	unlink "/tmp/$tmpfile";
}

1;
