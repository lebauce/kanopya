package Entity::Cluster;

use strict;

use base "Entity";
use lib qw (..);
use Entity::Component;

# contructor

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new( %args );
    return $self;
}

sub getComponents{
	
}

1;
