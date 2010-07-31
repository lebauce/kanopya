package EEntity::EComponent::EWebserver::EApache2;

use strict;

use base "EEntity::EComponent::EWebserver";


# contructor

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new( %args );
    return $self;
}


1;
