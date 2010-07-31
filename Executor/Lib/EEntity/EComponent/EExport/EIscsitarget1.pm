package EEntity::EComponent::EExport::EIscsitarget1;

use strict;

use base "EEntity::EComponent::EExport";

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
	#$args{params} = {} if !$args{params};	

	if ((! exists $args{id} or ! defined $args{id})) { 
		throw Mcs::Exception::Internal(error => "EEntity::EStorage::EIscsitarget1->generateInitiatorname need an id named argument to generate initiatorname!"); }
	
}
1;
