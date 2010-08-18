package Entity::Component::Dhcpserver::Dhcpd3;

use strict;

use base "Entity::Component::Dhcpserver";


# contructor

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new( %args );
    return $self;
}


1;
