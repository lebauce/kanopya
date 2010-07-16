package EntityData::MotherboardData;

use strict;

use base "EntityData";

# contructor 

sub new {
    my $class = shift;
    
    my $self = $class->SUPER::new(@_);
    return $self;
}

sub specific {
	print "\nje peux faire des trucs specifiques à motherboard!\n";
}

1;
