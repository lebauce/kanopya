package Entity::Component::Export::Iscsitarget1;

use strict;

use base "Entity::Component::Export";


# contructor

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new( %args );
    return $self;
}

sub addTarget {
	
}

1;
