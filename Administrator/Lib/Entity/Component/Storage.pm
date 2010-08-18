package Entity::Component::Storage;

use strict;
use Data::Dumper;
use base "Entity::Component";


# contructor

sub new {
    my $class = shift;
    my %args = @_;
	
    my $self = $class->SUPER::new( %args );
    return $self;
}


1;
