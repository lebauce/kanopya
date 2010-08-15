package EEntity::EComponent::EStorage::ELvm2;

use strict;
use Data::Dumper;
use base "EEntity::EComponent::EStorage";
use Log::Log4perl "get_logger";
my $log = get_logger("executor");
# contructor

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new( %args );
    return $self;
}

sub createDisk{
	my $self = shift;
	my %args = @_;
	
	if ((! exists $args{name} or ! defined $args{name}) ||
		(! exists $args{size} or ! defined $args{size}) ||
		(! exists $args{filesystem} or ! defined $args{filesystem})||
		(! exists $args{econtext} or ! defined $args{econtext})) { 
		throw Mcs::Exception::Internal::IncorrectParam(error => "ELvm2->createDisk need a name, size and filesystem named argument!"); }
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
		throw Mcs::Exception::Internal::IncorrectParam(error => "ELvm2->removeDisk need a name and econtext named argument!"); }
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
		throw Mcs::Exception::Internal::IncorrectParam(error => "ELvm2->createLV need a lvm2_lv_name, lvm2_lv_size, lvm2_vg_id and lvm2_lv_filesystem named argument!"); }

	$log->debug("Command execute in the following context : <" . ref($args{econtext}) . ">");
	$log->debug("lvcreate $args{lvm2_vg_name} -n $args{lvm2_lv_name} -L $args{lvm2_lv_size}");
	my $ret = $args{econtext}->execute(command => "lvcreate $args{lvm2_vg_name} -n $args{lvm2_lv_name} -L $args{lvm2_lv_size}");
	delete $args{econtext};
	delete $args{lvm2_vg_name};
	#TODO Real creation of LV
	return $self->_getEntity()->lvCreate(%args);
	
}

sub lvRemove{
	my $self = shift;
	my %args = @_;
	
	if ((! exists $args{lvm2_lv_name} or ! defined $args{lvm2_lv_name}) ||
		(! exists $args{lvm2_vg_id} or ! defined $args{lvm2_vg_id}) ||
		(! exists $args{econtext} or ! defined $args{econtext}) ||
		(! exists $args{lvm2_vg_name} or ! defined $args{lvm2_vg_name})) { 
		throw Mcs::Exception::Internal::IncorrectParam(error => "ELvm2->removeLV need a lvm2_lv_name, lvm2_vg_id, econtext and lvm2_vg_name named argument!"); }

	$log->debug("Command execute in the following context : <" . ref($args{econtext}) . ">");
	$log->debug("lvremove -f /dev/$args{lvm2_vg_name}/$args{lvm2_lv_name}");
	my $ret = $args{econtext}->execute(command => "lvremove -f /dev/$args{lvm2_vg_name}/$args{lvm2_lv_name}");
	delete $args{econtext};
	delete $args{lvm2_vg_name};
	#TODO Real creation of LV
	$self->_getEntity()->lvRemove(%args);
	
}


1;
