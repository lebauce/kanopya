package Entity::Systemimage;

use strict;
use lib qw (.. ../../../Common/Lib);
use McsExceptions;
use base "Entity";
use Log::Log4perl "get_logger";
my $log = get_logger("administrator");

my $struct = {systemimage_name			=> {pattern			=> 'm//s',
											is_mandatory	=> 1,
											is_extended		=> 0},
			  systemimage_desc			=> {pattern			=> 'm//m',
											is_mandatory	=> 1,
											is_extended 	=> 0},
			  distribution_id			=> {pattern			=> 'm//s',
											is_mandatory	=> 1,
											is_extended		=> 0},
			};



=head2 checkAttrs
	
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

	if (! exists $args{attrs} or ! defined $args{attrs}){ 
		throw Mcs::Exception::Internal::IncorrectParam(error => "Entity::Systemimage->checkAttrs need an data hash and class named argument!"); }	

	my $attrs = $args{attrs};
	foreach $attr (keys(%$attrs)) {
		if (exists $struct->{$attr}){
			$log->debug("Field <$attr> and value in attrs <$attrs->{$attr}>");
			#TODO Check param with regexp in pattern field of struct
			if ($struct->{$attr}->{is_extended}){
				$ext_attrs{$attr} = $attrs->{$attr};
			}
			else {
				$global_attrs{$attr} = $attrs->{$attr};
			}
		}
		else {
			throw Mcs::Exception::Internal::IncorrectParam(error => "Entity::Systemimage->checkAttrs detect a wrong attr $attr !");
		}
	}
	foreach $attr (keys(%$struct)) {
		if (($struct->{$attr}->{is_mandatory}) &&
			(! exists $attrs->{$attr})) {
				throw Mcs::Exception::Internal::IncorrectParam(error => "Entity::Systemimage->checkAttrs detect a missing attribute $attr !");
			}
	}
	#TODO Check if id (systemimage, kernel, ...) exist and are correct.
	return {global => \%global_attrs, extended => \%ext_attrs};
}

=head2 checkAttr
	
	Desc : This function check new object attribute
	args: 
		name : String : Attribute name
		value : String : Attribute value
	return : No return value only throw exception if error

=cut

sub checkAttr{
	my $self = shift;
	my %args = @_;

	if ((! exists $args{name} or ! defined $args{name}) ||
		(! exists $args{value} or ! defined $args{value})) { 
		throw Mcs::Exception::Internal::IncorrectParam(error => "Entity::Systemimage->checkAttr need a name and value named argument!"); }
	if (!exists $struct->{$args{name}}){
		throw Mcs::Exception::Internal::IncorrectParam(error => "Entity::Systemimage->checkAttr invalid name"); }
	# Here check attr value
}



sub new {
    my $class = shift;
    my %args = @_;

    if ((! exists $args{data} or ! defined $args{data}) ||
		(! exists $args{rightschecker} or ! defined $args{rightschecker})) { 
		throw Mcs::Exception::Internal::IncorrectParam(error => "Entity::Systemimage->new need a data and rightschecker named argument!"); }
	
    my $self = $class->SUPER::new( %args );
	
    return $self;
}


1;
