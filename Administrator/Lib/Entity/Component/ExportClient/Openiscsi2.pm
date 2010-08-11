package Entity::Component::ExportClient::Openiscsi2;

use strict;

use base "Entity::Component::ExportClient";


# contructor

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new( %args );
    return $self;
}


1;
