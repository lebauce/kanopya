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

=head2 createDisk

createDisk ( name, size, filesystem, econtext )
	desc: This function create a new lv on storage server.
	args:
		name : string : new lv name
		size : String : disk size finishing by unit (M : Mega, K : kilo, G : Giga)
		filesystem : String : The filesystem is defined by mkfs filesystem option
		econtext : Econtext : execution context on the storage server
	return:
		code returned by EEntity::EComponent::ELvm2->lvCreate
    
=cut
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
	my $vg = $self->_getEntity()->getMainVg();
	return $self->lvCreate(lvm2_vg_id =>$vg->{vgid}, lvm2_lv_name => $args{name},
					lvm2_lv_filesystem =>$args{filesystem}, lvm2_lv_size => $args{size},
					econtext => $args{econtext}, lvm2_vg_name => $vg->{vgname});
}
=head2 removeDisk

removeDisk ( name, econtext )
	desc: This function remove a lv using it lvname.
	args:
		name : string: lv name
		econtext : Econtext : execution context on the storage server
	return:
		code returned by EEntity::EComponent::ELvm2->lvRemove

=cut
sub removeDisk{
	my $self = shift;
	my %args = @_;
	
	if ((! exists $args{name} or ! defined $args{name}) ||
		(! exists $args{econtext} or ! defined $args{econtext})) { 
		$errmsg = "ELvm2->removeDisk need a name and econtext named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	my $vg = $self->_getEntity()->getMainVg();

	return $self->lvRemove(lvm2_vg_id =>$vg->{vgid}, lvm2_lv_name => $args{name},
					econtext => $args{econtext}, lvm2_vg_name => $vg->{vgname});
}
=head2 lvCreate

createDisk ( lvm2_lv_name, lvm2_lv_size, lvm2_lv_filesystem, lvm2_vg_id, econtext, lvm2_vg_name)
	desc: This function create a new lv on storage server and add it in db through entity part
	args:
		lvm2_lv_name : string : new lv name
		lvm2_lv_size : String : disk size finishing by unit (M : Mega, K : kilo, G : Giga)
		lvm2_lv_filesystem : String : The filesystem is defined by mkfs filesystem option
		econtext : Econtext : execution context on the storage server
		lvm2_vg_id : Int : VG id on which lv will be created
		lvm2_vg_name : String : vg name
	return:
		code returned by Entity::Component::Lvm2->lvCreate
    
=cut
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
	$self->vgSpaceUpdate(econtext => $args{econtext}, lvm2_vg_id => $args{lvm2_vg_id}, 
						lvm2_vg_name => $args{lvm2_vg_name});
	delete $args{econtext};
	delete $args{lvm2_vg_name};
	
	return $self->_getEntity()->lvCreate(%args);
	
}
=head2 vgSizeUpdate

vgSizeUpdate ( lvm2_vg_id, econtext, lvm2_vg_name)
	desc: This function update vg free space on storage server
	args:
		econtext : Econtext : execution context on the storage server
		lvm2_vg_id : Int : identifier of vg update
		lvm2_vg_name : String : vg name
	return:
		code returned by Entity::Component::Lvm2->vgSpaceUpdate
    
=cut
sub vgSpaceUpdate {
	my $self = shift;
	my %args = @_;
	
	if ((! exists $args{lvm2_vg_id} or ! defined $args{lvm2_vg_id}) ||
		(! exists $args{econtext} or ! defined $args{econtext}) ||
		(! exists $args{lvm2_vg_name} or ! defined $args{lvm2_vg_name})) { 
		$errmsg = "ELvm2->vgSizeUpdate need a econtext, lvm2_vg_id and lvm2_lv_filesystem named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	my $command = "vgs $args{lvm2_vg_name} --noheadings -o vg_free --nosuffix --units M --rows";
	my $ret = $args{econtext}->execute(command => $command);
	if($ret->{exitcode} != 0) {
		my $errmsg = "Error during execution of $command ; stderr is : $ret->{stderr}";
		$log->error($errmsg);
		throw Mcs::Exception::Execution(error => $errmsg);
	}
	my $freespace = $ret->{stdout};
	$freespace =~ 's/\s*//';
	return $self->_getEntity()->vgSizeUpdate(lvm2_vg_freespace => $freespace, lvm2_vg_id => $args{lvm2_vg_id});
}

=head2 lvRemove

lvRemove ( lvm2_lv_name, lvm2_vg_id, econtext, lvm2_vg_name)
	desc: This function remove a lv.
	args:
		name : string: lv name
		econtext : Econtext : execution context on the storage server


=cut
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
	$self->vgSpaceUpdate(econtext => $args{econtext}, lvm2_vg_id => $args{lvm2_vg_id}, 
						lvm2_vg_name => $args{lvm2_vg_name});
}


1;
