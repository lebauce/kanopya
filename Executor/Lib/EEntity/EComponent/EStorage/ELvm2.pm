package EEntity::EComponent::EStorage::ELvm2;

use strict;
use Data::Dumper;
use base "EEntity::EComponent::EStorage";


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
		(! exists $args{filesystem} or ! defined $args{filesystem})) { 
		throw Mcs::Exception::Internal::IncorrectParam(error => "ELvm2->createDisk need a name, size and filesystem named argument!"); }
	#TODO Get main vg could be in entity object or EEntity
	my $vg = $self->_getEntity()->getMainVg();
	$self->lvCreate(lvm2_vg_id =>$vg, lvm2_lv_name => $args{name},
					lvm2_lv_filesystem =>$args{filesystem}, lvm2_lv_size => $args{size});
}

sub lvCreate{
	my $self = shift;
	my %args = @_;
	
	if ((! exists $args{lvm2_lv_name} or ! defined $args{lvm2_lv_name}) ||
		(! exists $args{lvm2_lv_size} or ! defined $args{lvm2_lv_size}) ||
		(! exists $args{lvm2_lv_filesystem} or ! defined $args{lvm2_lv_filesystem}) ||
		(! exists $args{lvm2_vg_id} or ! defined $args{lvm2_vg_id})) { 
		throw Mcs::Exception::Internal::IncorrectParam(error => "ELvm2->createLV need a lvm2_lv_name, lvm2_lv_size, lvm2_vg_id and lvm2_lv_filesystem named argument!"); }

	#TODO Real creation of LV
	$self->_getEntity()->lvCreate(%args);
	
}
1;
