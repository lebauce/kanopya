package Entity::Component::Webserver::Apache2;

use strict;

use base "Entity::Component::Webserver";


# contructor

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new( %args );
    return $self;
}


1;
