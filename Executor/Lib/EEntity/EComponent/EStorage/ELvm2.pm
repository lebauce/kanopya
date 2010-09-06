package EEntity::EComponent::EStorage::ELvm2;

use strict;
use Data::Dumper;
use base "EEntity::EComponent::EStorage";
use Log::Log4perl "get_logger";
my $log = get_logger("executor");
my $errmsg;
# contructor

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new( %args );
    return $self;
}

sub createDisk {
	my $self = shift;
	my %args = @_;
	
	if ((! exists $args{name} or ! defined $args{name}) ||
		(! exists $args{size} or ! defined $args{size}) ||
		(! exists $args{filesystem} or ! defined $args{filesystem})||
		(! exists $args{econtext} or ! defined $args{econtext})) { 
		$errmsg = "ELvm2->createDisk need a name, size and filesystem named argument!"; 
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	#TODO Get main vg could be in entity object or EEntity
	my $vg = $self->_getEntity()->getMainVg();
	return $self->lvCreate(lvm2_vg_id =>$vg->{vgid}, lvm2_lv_name => $args{name},
					lvm2_lv_filesystem =>$args{filesystem}, lvm2_lv_size => $args{size},
					econtext => $args{econtext}, lvm2_vg_name => $vg->{vgname});
}

sub removeDisk{
	my $self = shift;
	my %args = @_;
	
	if ((! exists $args{name} or ! defined $args{name}) ||
		(! exists $args{econtext} or ! defined $args{econtext})) { 
		$errmsg = "ELvm2->removeDisk need a name and econtext named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	#TODO Get main vg could be in entity object or EEntity
	my $vg = $self->_getEntity()->getMainVg();

	$self->lvRemove(lvm2_vg_id =>$vg->{vgid}, lvm2_lv_name => $args{name},
					econtext => $args{econtext}, lvm2_vg_name => $vg->{vgname});
}

sub lvCreate{
	my $self = shift;
	my %args = @_;
	
	if ((! exists $args{lvm2_lv_name} or ! defined $args{lvm2_lv_name}) ||
		(! exists $args{lvm2_lv_size} or ! defined $args{lvm2_lv_size}) ||
		(! exists $args{lvm2_lv_filesystem} or ! defined $args{lvm2_lv_filesystem}) ||
		(! exists $args{lvm2_vg_id} or ! defined $args{lvm2_vg_id}) ||
		(! exists $args{econtext} or ! defined $args{econtext}) ||
		(! exists $args{lvm2_vg_name} or ! defined $args{lvm2_vg_name})) { 
		$errmsg = "ELvm2->createLV need a lvm2_lv_name, lvm2_lv_size, lvm2_vg_id and lvm2_lv_filesystem named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}

	$log->debug("Command execute in the following context : <" . ref($args{econtext}) . ">");
	$log->debug("lvcreate $args{lvm2_vg_name} -n $args{lvm2_lv_name} -L $args{lvm2_lv_size}");
	my $command = "lvcreate $args{lvm2_vg_name} -n $args{lvm2_lv_name} -L $args{lvm2_lv_size}";
	my $ret = $args{econtext}->execute(command => $command);
	if($ret->{exitcode} != 0) {
		my $errmsg = "Error during execution of $command ; stderr is : $ret->{stderr}";
		$log->error($errmsg);
		throw Mcs::Exception::Execution(error => $errmsg);
	}
	delete $args{econtext};
	delete $args{lvm2_vg_name};
	
	return $self->_getEntity()->lvCreate(%args);
	
}

sub lvRemove{
	my $self = shift;
	my %args = @_;
	
	if ((! exists $args{lvm2_lv_name} or ! defined $args{lvm2_lv_name}) ||
		(! exists $args{lvm2_vg_id} or ! defined $args{lvm2_vg_id}) ||
		(! exists $args{econtext} or ! defined $args{econtext}) ||
		(! exists $args{lvm2_vg_name} or ! defined $args{lvm2_vg_name})) { 
		$errmsg = "ELvm2->removeLV need a lvm2_lv_name, lvm2_vg_id, econtext and lvm2_vg_name named argument!"; 
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}

	$log->debug("Command execute in the following context : <" . ref($args{econtext}) . ">");
	$log->debug("lvremove -f /dev/$args{lvm2_vg_name}/$args{lvm2_lv_name}");
	my $ret = $args{econtext}->execute(command => "lvremove -f /dev/$args{lvm2_vg_name}/$args{lvm2_lv_name}");
	delete $args{econtext};
	delete $args{lvm2_vg_name};
	#TODO Real creation of LV
	$self->_getEntity()->lvRemove(%args);
	
}


1;
