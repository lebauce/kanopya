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
		throw Kanopya::Exception::Internal(error => $errmsg);
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
		throw Kanopya::Exception::Internal(error => "EEntity::EStorage::EIscsitarget1->generateTargetname need a name and a type named argument to generate initiatorname!"); }
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
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
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
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	$log->debug("target name is $args{target_name}");
	my $result = $args{econtext}->execute(command =>"grep \"$args{target_name}\" /proc/net/iet/volume");
	if ($result->{stdout} eq "") {
		$errmsg = "EComponent::EExport::EIscsitarget1->gettid : no target name found for $args{target_name}!";#
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
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
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
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

sub removeTarget {
	my $self = shift;
	my %args  = @_;	
	if ((! exists $args{iscsitarget1_target_id} or ! defined $args{iscsitarget1_target_id}) ||
		(! exists $args{iscsitarget1_target_name} or ! defined $args{iscsitarget1_target_name})||
		(! exists $args{econtext} or ! defined $args{econtext})) {
		$errmsg = "EComponent::EExport::EIscsitarget1->removeTarget needs an iscsitarget1_target_id and iscsitarget1_target_name named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	
	$log->debug('iscsitargetname : '.$args{iscsitarget1_target_name});
	
	# first we clean sessions for this target
	my $tid = $self->cleanTargetSession(targetname => $args{iscsitarget1_target_name}, econtext => $args{econtext});
		
	my $result = $args{econtext}->execute(command =>"ietadm --op delete --tid=$tid");
	delete $args{econtext};
	return $self->_getEntity()->removeTarget(%args);	
}

=head _getIetdSessions
	argument : econtext
	return an arrayref contening /proc/net/iet/session content

=cut

sub _getIetdSessions {
	my $self = shift;
	my %args = @_;
	if(! exists $args{econtext} or ! defined $args{econtext}) {
		$errmsg = "EComponent::EExport::EIscsitarget1->_getIetdSessions needs an econtext named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	my $target_regexp = qr/^tid:([0-9]+)\sname:(.+)/;
	my $session_regexp = qr/^\tsid:([0-9]+)\sinitiator:(.+)/;
	my $connection_regexp = qr/^\t\tcid:([0-9]+)\sip:(.+)state:(.+)\shd:(.+)\sdd:(.+)/;
	
	my $result = $args{econtext}->execute(command => 'cat /proc/net/iet/session');
	my @output = split(/\n/, $result->{stdout});
	
	my ($target, $session, $connection);
	my $ietdsessions = [];
	
	foreach my $line (@output) {
		if($line =~ $target_regexp) {
			$target = { tid => $1, targetname => $2, sessions => [] };
			push(@$ietdsessions, $target);
		} elsif($line =~ $session_regexp) {
			$session = { sid => $1, initiator => $2, connections => [] };
			push(@{$ietdsessions->[-1]->{sessions}}, $session);
		} elsif($line =~ $connection_regexp) {
			$connection = { cid => $1, ip => $2, state => $3, hd => $4, dd => $5};
			push(@{$ietdsessions->[-1]->{sessions}->[-1]->{connections}}, $connection); 
		}
	}
	return $ietdsessions;
} 

=head cleanTargetSession

	argument : targetname, econtext
	try to remove any sessions on a target 

=cut 

sub cleanTargetSession {
	my $self = shift;
	my %args  = @_;	
	if ((! exists $args{targetname} or ! defined $args{targetname}) ||
		(! exists $args{econtext} or ! defined $args{econtext})) {
		$errmsg = "EComponent::EExport::EIscsitarget1->cleanTargetSession needs targetname and econtext named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	# first, we get actual sessions 
	my $ietdsessions = $self->_getIetdSessions(econtext => $args{econtext}); 
	
	# next we clean existing sessions on this target
	foreach my $target (@$ietdsessions) {
		if($target->{targetname} eq $args{targetname}) {
			foreach my $session(@{$target->{sessions}}) {
				for my $connection (@{$session->{connections}}) {
					my $command = "ietadm --op delete --tid=$target->{tid} --sid=$session->{sid} --cid=$connection->{cid}";
					my $result = $args{econtext}->execute(command => $command);
					#TODO tester le retour de la commande
				}
			}
			return $target->{tid};
		}
		else { next; } 
	}
	return;
}	

=head cleanInitiatorSession

	argument : initiator, econtext
	try to remove all sessions for an initiator 

=cut 
	
sub cleanInitiatorSession {
	my $self = shift;
	my %args  = @_;	
	if ((! exists $args{initiator} or ! defined $args{initiator}) ||
		(! exists $args{econtext} or ! defined $args{econtext})) {
		$errmsg = "EComponent::EExport::EIscsitarget1->cleanInitiatorSession needs an initiatorname and econtext named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	# first, we get actual sessions 
	my $ietdsessions = $self->_getIetdSessions(econtext => $args{econtext}); 
	
	# next we clean existing sessions for the given initiatorname
	foreach my $target (@$ietdsessions) {
		foreach my $session(@{$target->{sessions}}) {
			if($session->{initiator} eq $args{initiator}) {
				for my $connection (@{$session->{connections}}) {
					my $command = "ietadm --op delete --tid=$target->{tid} --sid=$session->{sid} --cid=$connection->{cid}";
					my $result = $args{econtext}->execute(command => $command);
					#TODO tester le retour de la commande
				}
			} else { next; }
		}
	}
}


# generate /etc/ietd.conf configuration file
sub generate {
	my $self = shift;
	my %args = @_;
	if(! exists $args{econtext} or ! defined $args{econtext}) {
		$errmsg = "EComponent::EExport::EIscsitarget1->generate needs a econtext named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
		
	my $data = $self->_getEntity()->getTemplateData();
	
	$self->generateFile( econtext => $args{econtext},
						 mount_point => "/etc",
						 template_dir => "/templates/components/ietd",
						 input_file => "ietd.conf.tt",
						 output => "/iet/ietd.conf",
						 data => $data);
	 	 
}




1;
