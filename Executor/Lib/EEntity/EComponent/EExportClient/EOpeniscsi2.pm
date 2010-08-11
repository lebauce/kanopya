package EEntity::EComponent::EExportCliebt::EOpeniscsi2;

use strict;

use base "Entity::Component::EExportClient";


# contructor

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new( %args );
    return $self;
}


1;
