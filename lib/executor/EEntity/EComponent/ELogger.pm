package EEntity::EComponent::ELogger;

use strict;

use base "EEntity::EComponent";


# contructor

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new( %args );
    return $self;
}

1;