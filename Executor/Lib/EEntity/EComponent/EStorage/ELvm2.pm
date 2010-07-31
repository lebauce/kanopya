package EEntity::EComponent::EStorage::ELvm2;

use strict;
use Data::Dumper;
use base "EEntity::EComponent::EStorage";


# contructor

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new( %args );
    return $self;
}


1;
