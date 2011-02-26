package EEntity::EComponent::EExport::EIscsitarget1;

use strict;
use Date::Simple (':all');
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

sub generateInitiatorname{
	my $self = shift;
	my %args  = @_;	

	if ((! exists $args{hostname} or ! defined $args{hostname})) { 
		$errmsg = "EEntity::EStorage::EIscsitarget1->generateInitiatorname need an hostname named argument to generate initiatorname!"; 
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);
	}
	my $today = today();
	my $res = "iqn." . $today->year . "-" . $today->format("%m") . ".com.hedera-technology." . $args{hostname};
	$log->info("InitiatorName generated is $res");
	return $res;
}
sub generateTargetname {
	my $self = shift;
	my %args  = @_;	
	
	if ((! exists $args{name} or ! defined $args{name})) { 
		throw Mcs::Exception::Internal(error => "EEntity::EStorage::EIscsitarget1->generateTargetname need a name and a type named argument to generate initiatorname!"); }
	my $today = today();
	my $res = "iqn." . $today->year . "-" . $today->format("%m") . ".com.hedera-technology.nas:$args{name}";
	$log->info("TargetName generated is $res");
	return $res;
}


sub addTarget {
	my $self = shift;
	my %args  = @_;	

	if ((! exists $args{iscsitarget1_target_name} or ! defined $args{iscsitarget1_target_name}) ||
		(! exists $args{mountpoint} or ! defined $args{mountpoint}) ||
		(! exists $args{mount_option} or ! defined $args{mount_option})||
		(! exists $args{econtext} or ! defined $args{econtext})) {
		$errmsg = "EComponent::EExport::EIscsitarget1->addTarget needs a iscsitarget1_targetname,econtext,mount_option and mountpoint named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	my $result = $args{econtext}->execute(command => "grep tid: /proc/net/iet/volume | sed 's/tid:\\(\[0-9\]\*\\) .*/\\1/'");
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

sub gettid {
	my $self = shift;
	my %args  = @_;	
	if ((! exists $args{target_name} or ! defined $args{target_name})||
		(! exists $args{econtext} or ! defined $args{econtext})) {
		$errmsg = "EComponent::EExport::EIscsitarget1->gettid needs a target_name and econtext named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	$log->debug("target name is $args{target_name}");
	my $result = $args{econtext}->execute(command =>"grep \"$args{target_name}\" /proc/net/iet/volume");
	if ($result->{stdout} eq "") {
		$errmsg = "EComponent::EExport::EIscsitarget1->gettid : no target name found for $args{target_name}!";#
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);
	}
	my @t1 = split(/\s/, $result->{stdout});
	my @t2 = split(/:/, $t1[0]);
	my $tid = $t2[1];
	return $tid;
	
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

sub removeLun {
	my $self = shift;
	my %args  = @_;
	
	#TODO In future if need we can just remove a lun.
	return $self->_getEntity()->removeLun(%args);	
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

=head 

	given a targetname, an initiatorname and an econtext 
	return a hash reference containing iscsi target id and session id for an initiator and a target
	return undef if no session found                                                                                 

=cut 

sub getIscsiSession {
	my $self = shift;
	my %args  = @_;	
	if ((! exists $args{initiatorname} or ! defined $args{initiatorname}) ||
		(! exists $args{targetname} or ! defined $args{targetname})||
		(! exists $args{econtext} or ! defined $args{econtext})) {
		$errmsg = "EComponent::EExport::EIscsitarget1->getIscsiSession needs a targetname,  initiatorname and econtext named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	
	my $command = 'cat /proc/net/iet/session';
	my $result = $args{econtext}->execute(command => $command);
	$result->{stdout} =~ m/tid:([0-9]+)\sname:$args{targetname}\n(\tsid:[0-9]+\sinitiator:.*\n\t\tcid:.*\n)*\tsid:([0-9]+)\sinitiator:$args{initiatorname}\n\t\tcid:.*\n/;
	if(defined $1 && defined $3) {
		$log->debug("tid found : $1\tsid found : $3");
		return { tid => $1, sid => $3 };
	}
	return undef;
}

sub cleanIscsiSession {
	my $self = shift;
	my %args  = @_;	
	if ((! exists $args{tid} or ! defined $args{tid}) ||
		(! exists $args{sid} or ! defined $args{sid})||
		(! exists $args{econtext} or ! defined $args{econtext})) {
		$errmsg = "EComponent::EExport::EIscsitarget1->cleanIscsiSession needs a tid, sid and econtext named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	my $command = "ietadm --op delete --tid=$args{tid} --sid=$args{sid} --cid=0";
	my $result = $args{econtext}->execute(command => $command);
	#TODO tester le retour de la commande
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
	    INCLUDE_PATH => '/templates/components/mcsietd',
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
	$args{econtext}->send(src => "/tmp/$tmpfile", dest => "/etc/iet/ietd.conf");	
	unlink "/tmp/$tmpfile";		 	 
}




1;
