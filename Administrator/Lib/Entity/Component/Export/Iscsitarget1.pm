package Entity::Component::Export::Iscsitarget1;
use lib qw (/workspace/mcs/Administrator/Lib /workspace/mcs/Common/Lib);
use Log::Log4perl "get_logger";
use Data::Dumper;
use strict;
use McsExceptions;

use base "Entity::Component::Export";

my $log = get_logger("administrator");
my $errmsg;

# contructor

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new( %args );
    return $self;
}

=head2 AddTarget
	
	Desc : This function a new target entry into iscsitarget configuration.
	args: 
		administrator : Administrator : Administrator object to instanciate all components
	return : a system image instance

=cut
sub addTarget {
	my $self = shift;
    my %args = @_;

	if ((! exists $args{iscsitarget1_target_name} or ! defined $args{iscsitarget1_target_name}) ||
		(! exists $args{mountpoint} or ! defined $args{mountpoint}) ||
		(! exists $args{mount_option} or ! defined $args{mount_option})) {
		$errmsg = "Component::Export::Iscsitarget1->addTarget needs a iscsitarget1_targetname and mountpoint named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	my $iscsitarget1_rs = $self->{_dbix}->iscsitarget1_targets;
	my $res = $iscsitarget1_rs->create(\%args);
	$log->info("New target <$args{iscsitarget1_target_name}> added with mount point <$args{mountpoint}> and options <$args{mount_option}> and return " .$res->get_column("iscsitarget1_target_id"));
	return $res->get_column("iscsitarget1_target_id");
}

=head2 AddLun
	
	Desc : This function a new lun to a target.
	args: 
		administrator : Administrator : Administrator object to instanciate all components
	return : a system image instance

=cut
sub addLun {
	my $self = shift;
    my %args = @_;

	if ((! exists $args{iscsitarget1_target_id} or ! defined $args{iscsitarget1_target_id}) ||
		(! exists $args{iscsitarget1_lun_number} or ! defined $args{iscsitarget1_lun_number}) ||
		(! exists $args{iscsitarget1_lun_device} or ! defined $args{iscsitarget1_lun_device}) ||
		(! exists $args{iscsitarget1_lun_typeio} or ! defined $args{iscsitarget1_lun_typeio}) ||
		(! exists $args{iscsitarget1_lun_iomode} or ! defined $args{iscsitarget1_lun_iomode})) {
		$errmsg = "Component::Export::Iscsitarget1->addLun needs a iscsitarget1_target_id, iscsitarget1_lun_number, iscsitarget1_lun_device, iscsitarget1_lun_typeio and iscsitarget1_lun_iomode named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	$log->debug("New Lun try to be added with iscsitarget1_target_id $args{iscsitarget1_target_id} iscsitarget1_lun_number $args{iscsitarget1_lun_number} iscsitarget1_lun_device $args{iscsitarget1_lun_device}" );
	my $iscsitarget1_lun_rs = $self->{_dbix}->iscsitarget1_targets->single( {iscsitarget1_target_id => $args{iscsitarget1_target_id}})->iscsitarget1_luns;

	my $res = $iscsitarget1_lun_rs->create(\%args);
	$log->info("New Lun <$args{iscsitarget1_lun_device}> added");
	return $res->get_column('iscsitarget1_lun_id');
}

sub getTargetIdLike {
	my $self = shift;
    my %args = @_;

	if (! exists $args{iscsitarget1_target_name} or ! defined $args{iscsitarget1_target_name}) {
		$errmsg = "Component::Export::Iscsitarget1->getTargetId needs a iscsitarget1_target_name named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	return $self->{_dbix}->iscsitarget1_targets->search({iscsitarget1_target_name => {-like => $args{iscsitarget1_target_name}}})->first()->get_column('iscsitarget1_target_id');
}

sub getLunId {
	my $self = shift;
    my %args = @_;

	if ((! exists $args{iscsitarget1_target_id} or ! defined $args{iscsitarget1_target_id})||
		(! exists $args{iscsitarget1_lun_device} or ! defined $args{iscsitarget1_lun_device})) {
		$errmsg = "Component::Export::Iscsitarget1->getLun needs an iscsitarget1_target_id and an iscsitarget1_lun_device named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	return $self->{_dbix}->iscsitarget1_targets->find($args{iscsitarget1_target_id})->iscsitarget1_luns->first({ iscsitarget1_lun_device=> $args{iscsitarget1_lun_device}})->get_column('iscsitarget1_lun_id');
	
}

sub removeLun {
	my $self = shift;
	my %args  = @_;
	if ((! exists $args{iscsitarget1_target_id} or ! defined $args{iscsitarget1_target_id})||
		(! exists $args{iscsitarget1_lun_id} or ! defined $args{iscsitarget1_lun_id})) {
		$errmsg = "Component::Export::Iscsitarget1->removeLun needs an iscsitarget1_lun_id and an iscsitarget1_target_id named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	return $self->{_dbix}->iscsitarget1_targets->find($args{iscsitarget1_target_id})->iscsitarget1_luns->find($args{iscsitarget1_lun_id})->delete();
}

sub removeTarget{
	my $self = shift;
	my %args  = @_;	
	if (! exists $args{iscsitarget1_target_id} or ! defined $args{iscsitarget1_target_id}) {
		$errmsg = "Component::Export::Iscsitarget1->removeTarget needs an iscsitarget1_target_id named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	return $self->{_dbix}->iscsitarget1_targets->find($args{iscsitarget1_target_id})->delete();	
}

sub getTarget {
	my $self = shift;
	my %args  = @_;	
	if (! exists $args{iscsitarget1_target_id} or ! defined $args{iscsitarget1_target_id}) {
		$errmsg = "Component::Export::Iscsitarget1->getTarget needs an iscsitarget1_target_id named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	
	my $target_raw = $self->{_dbix}->iscsitarget1_targets->find($args{iscsitarget1_target_id});
	my $export ={};
	$export->{target} = $target_raw->get_column('iscsitarget1_target_name');
	$export->{mountpoint} = $target_raw->get_column('mountpoint');
	$export->{mount_option} = $target_raw->get_column('mount_option');

	return $export;
}

# return a data structure to pass to the template processor 
sub getTemplateData {
	my $self = shift;
	my $data = {};
	my $targets = $self->{_dbix}->iscsitarget1_targets;
	$data->{targets} = [];
	while (my $onetarget = $targets->next) {
		my $record = {};
		$record->{target_name} = $onetarget->get_column('iscsitarget1_target_name');
		$record->{luns} = [];
		my $luns = $onetarget->iscsitarget1_luns->search();
		while(my $onelun = $luns->next) {
			push @{$record->{luns}}, { 
				number => $onelun->get_column('iscsitarget1_lun_number'),
				device => $onelun->get_column('iscsitarget1_lun_device'),
				type => $onelun->get_column('iscsitarget1_lun_typeio'),
				iomode => $onelun->get_column('iscsitarget1_lun_iomode'),
			}; 
		}
		push @{$data->{targets}}, $record;
	}
	 
	return $data;	  
}
1;
