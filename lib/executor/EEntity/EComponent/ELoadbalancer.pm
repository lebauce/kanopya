package EEntity::EComponent::ELoadbalancer;

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