package Entity::Component::Export::Iscsitarget;

use strict;

use base "Entity::Component::Export";


# contructor

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new( %args );
    return $self;
}


1;
