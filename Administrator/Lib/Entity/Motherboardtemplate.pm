package Entity::Motherboardtemplate;

use strict;

use base "Entity";

# contructor 

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new( %args );

    return $self;
}

sub specific {
	#print "\nje peux faire des trucs specifiques à motherboard!\n";
}

1;
