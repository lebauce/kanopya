package EEntity::EComponent::EDhcpserver::EDhcpd3;

use strict;

use base "EEntity::EComponent::EDhcpserver";


# contructor

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new( %args );
    return $self;
}


1;
