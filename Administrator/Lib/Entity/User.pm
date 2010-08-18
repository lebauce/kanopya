package Entity::User;

use strict;
use lib qw (.. ../../../Common/Lib);
use McsExceptions;
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
