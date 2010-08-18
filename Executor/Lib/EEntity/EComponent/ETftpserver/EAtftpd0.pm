package EEntity::EComponent::ETftpserver::EAtftpd0;

use strict;

use base "Entity::Component::ETftpserver";


# contructor

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new( %args );
    return $self;
}


1;
