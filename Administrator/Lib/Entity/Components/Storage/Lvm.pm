package Entity::Components::Storage::Lvm;

use strict;

use base "Entity::Components::Storage";


# contructor

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new( %args );
    return $self;
}


1;
