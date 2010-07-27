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


1;
