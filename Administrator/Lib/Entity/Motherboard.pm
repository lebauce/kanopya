package Entity::Motherboard;

use strict;

use base "Entity";

my $struct = {motherboardtemplate_id	=> {pattern			=> 'm//s',
											is_mandatory	=> 1,
											is_extended		=> 0},
			  processortemplate_id		=> {pattern			=> 'm//m',
											is_mandatory	=> 0,
											is_extended 	=> 0},
			  kernel_id					=> {pattern			=> 'm//s',
											is_mandatory	=> 1,
											is_extended		=> 0},
			  motherboard_SN			=> {pattern 		=> 'm//s',
											is_mandatory	=> 1,
											is_extended 	=> 0},
			  motherboard_slot_position	=> {pattern 		=> 'm//s',
											is_mandatory	=> 0,
											is_extended 	=> 0},
			  motherboard_desc			=> {pattern 		=> 'm//s',
											is_mandatory	=> 0,
											is_extended 	=> 0},
			  motherboard_active		=> {pattern 		=> 'm//s',
											is_mandatory	=> 0,
											is_extended 	=> 0},
			  mac_address				=> {pattern 		=> 'm//s',
											is_mandatory	=> 1,
											is_extended 	=> 1}
			};



=head2 checkAttr
	
	Desc : This function check if new object data are correct and sort attrs between extended and global
	args: 
		class : String : Real class to check
		data : hashref : Entity data to be checked
	return : hashref of hashref : a hashref containing 2 hashref, global attrs and extended ones

=cut

sub checkAttrs {
	# Remove class
	shift;
	my %args = @_;
	my (%global_attrs, %ext_attrs, $attr);

	if (! exists $args{data} or ! defined $args{data}){ 
		throw Mcs::Exception::Internal(error => "Entity->checkAttrs need an data hash and class named argument!"); }	

	my $attrs = $args{data};
	foreach $attr (keys(%$attrs)) {
		if (exists $struct->{$attr}){
			#TODO Check param with regexp in pattern field of struct
			if ($struct->{$attr}->{is_extended}){
				$ext_attrs{$attr} = $attrs->{$attr};
			}
			else {
				$global_attrs{$attr} = $attrs->{$attr};
			}
		}
		else {
			throw Mcs::Exception::Internal(error => "Entity->checkAttrs detect a wrong attr $attr !");
		}
	}
	foreach $attr (keys(%$struct)) {
		if (($struct->{$attr}->{is_mandatory}) &&
			(! exists $attrs->{$attr})) {
				throw Mcs::Exception::Internal(error => "Entity->checkAttrs detect a missing attribute $attr !");
			}
	}
	#TODO Check if id (systemimage, kernel, ...) exist and are correct.
	return {global => \%global_attrs, extended => \%ext_attrs};
}

sub extension {
	return "motherboarddetails";
}

sub new {
    my $class = shift;
    my %args = @_;

    if ((! exists $args{data} or ! defined $args{data}) ||
		(! exists $args{rightschecker} or ! defined $args{rightschecker}) ||
		(! exists $args{ext_attrs} or ! defined $args{ext_attrs})) { 
		throw Mcs::Exception::Internal(error => "Entity->new need a data and rightschecker named argument!"); }

	my $ext_attrs = $args{ext_attrs};
	delete $args{ext_attrs};
    my $self = $class->SUPER::new( %args );
	$self->{_ext_attrs} = $ext_attrs;
    return $self;
}


1;
