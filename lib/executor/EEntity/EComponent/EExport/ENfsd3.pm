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

sub addTarget {
	my $self = shift;
	my %args  = @_;	

	if ((! exists $args{iscsitarget1_target_name} or ! defined $args{iscsitarget1_target_name}) ||
		(! exists $args{mountpoint} or ! defined $args{mountpoint}) ||
		(! exists $args{mount_option} or ! defined $args{mount_option})||
		(! exists $args{econtext} or ! defined $args{econtext})) {
		$errmsg = "Component::Export::Iscsitarget1->addTarget needs a iscsitarget1_targetname and mountpoint named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	my $result = $args{econtext}->execute(command => "grep tid: /proc/net/iet/volume | sed 's/tid:\\(\[0-9\]\*\\) .*/\\1/' | sort -rg ");
 	my $tid;
    if ($result->{stdout} eq "") {
    	$tid = 0;
    }
    else {
		my @tab = split(/\s/, $result->{stdout});
		$tid = $tab[0];
		$tid += 1;
    }
		# on cree le nouveau target
    $result = $args{econtext}->execute(command => "ietadm --op new --tid=$tid --params Name=$args{iscsitarget1_target_name}");
	delete $args{econtext};
	return $self->_getEntity()->addTarget(%args);
}

sub reload {
	my $self = shift;
	$self->generateConf();
}

sub addLun {
	my $self = shift;
	my %args  = @_;
	
		if ((! exists $args{iscsitarget1_target_id} or ! defined $args{iscsitarget1_target_id}) ||
		(! exists $args{iscsitarget1_lun_number} or ! defined $args{iscsitarget1_lun_number}) ||
		(! exists $args{iscsitarget1_lun_device} or ! defined $args{iscsitarget1_lun_device}) ||
		(! exists $args{iscsitarget1_lun_typeio} or ! defined $args{iscsitarget1_lun_typeio}) ||
		(! exists $args{iscsitarget1_lun_iomode} or ! defined $args{iscsitarget1_lun_iomode}) ||
		(! exists $args{iscsitarget1_target_name} or ! defined $args{iscsitarget1_target_name})||
		(! exists $args{econtext} or ! defined $args{econtext})) {
		$errmsg = "EComponent::EExport::EIscsitarget1->addLun needs a iscsitarget1_target_id, iscsitarget1_lun_number, iscsitarget1_lun_device, iscsitarget1_lun_typeio and iscsitarget1_lun_iomode named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	my $tid = $self->gettid(target_name => $args{iscsitarget1_target_name}, econtext => $args{econtext});
	delete $args{iscsitarget1_target_name};
	my $result =  $args{econtext}->execute(command => "ietadm --op new --tid=$tid --lun=$args{iscsitarget1_lun_number} --params Path=$args{iscsitarget1_lun_device},Type=$args{iscsitarget1_lun_typeio},IOMode=$args{iscsitarget1_lun_iomode}");
	delete $args{econtext};
	return $self->_getEntity()->addLun(%args);	
}


sub removeTarget{
	my $self = shift;
	my %args  = @_;	
	if ((! exists $args{iscsitarget1_target_id} or ! defined $args{iscsitarget1_target_id}) ||
		(! exists $args{iscsitarget1_target_name} or ! defined $args{iscsitarget1_target_name})||
		(! exists $args{econtext} or ! defined $args{econtext})) {
		$errmsg = "EComponent::EExport::EIscsitarget1->removeTarget needs an iscsitarget1_target_id and iscsitarget1_target_name named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	my $tid = $self->gettid(target_name => $args{iscsitarget1_target_name}, econtext => $args{econtext});
	my $result = $args{econtext}->execute(command =>"ietadm --op delete --tid=$tid");
	delete $args{econtext};
	return $self->_getEntity()->removeTarget(%args);	
}








# generate /etc/ietd.conf configuration file
sub generate {
	my $self = shift;
	my %args = @_;
	if(! exists $args{econtext} or ! defined $args{econtext}) {
		$errmsg = "EComponent::EExport::EIscsitarget1->generate needs a econtext named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
		
	my $config = {
	    INCLUDE_PATH => '/templates/mcsietd',
	    INTERPOLATE  => 1,               # expand "$var" in plain text
	    POST_CHOMP   => 0,               # cleanup whitespace 
	    EVAL_PERL    => 1,               # evaluate Perl code blocks
	    RELATIVE => 1,                   # desactive par defaut
	};
	
	my $rand = new String::Random;
	my $tmpfile = $rand->randpattern("cccccccc");
	# create Template object
	my $template = Template->new($config);
    my $input = "ietd.conf.tt";
    my $data = $self->_getEntity()->getTemplateData();
	
	$template->process($input, $data, "/tmp/".$tmpfile) || do {
		$errmsg = "EComponent::EExport::EIscsitarget1->generate : error during template generation : $template->error;";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);	
	};
	$args{econtext}->send(src => "/tmp/$tmpfile", dest => "/etc/ietd.conf");	
	unlink "/tmp/$tmpfile";		 	 
}




1;
