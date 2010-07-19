package Entity::Components::Storage;

use strict;

use base "Entity::Components";


# contructor

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new( %args );
    return $self;
}


1;
