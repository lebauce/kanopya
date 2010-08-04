package Entity::Component::Storage::Lvm2;

use strict;

use base "Entity::Component::Storage";


# contructor

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new( %args );
    return $self;
}

sub getMainVg{
	my $self = shift;
	#TODO getMainVg, return id or name ?
	return "1";
}

sub lvCreate{
	my $self = shift;
	my %args = @_;
	
	if ((! exists $args{lvm2_lv_name} or ! defined $args{lvm2_lv_name}) ||
		(! exists $args{lvm2_lv_size} or ! defined $args{lvm2_lv_size}) ||
		(! exists $args{lvm2_lv_filesystem} or ! defined $args{lvm2_lv_filesystem}) ||
		(! exists $args{lvm2_vg_id} or ! defined $args{lvm2_vg_id})) { 
		throw Mcs::Exception::Internal::IncorrectParam(error => "ELvm2->createLV need a lvm2_lv_name, lvm2_lv_size, lvm2_vg_id and lvm2_lv_filesystem named argument!"); }
#TODO Insert in linked table lvm2_lv_id ?
}
1;
