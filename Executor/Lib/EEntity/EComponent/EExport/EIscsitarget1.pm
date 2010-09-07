package EEntity::EComponent::EExport::EIscsitarget1;

use strict;
use Date::Simple (':all');
use Log::Log4perl "get_logger";

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

	
	$self->restart();
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

sub generateConf{
	
}
sub restart {
	
}

1;
