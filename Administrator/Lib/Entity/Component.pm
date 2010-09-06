package Entity::Component;

use strict;

use base "Entity";


# contructor

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new( %args );
    return $self;
}

sub getTemplateDirectory {
	my $self = shift;
	if( defined $self->{_dbix}->get_column('component_template_id') ) {
		return $self->{_dbix}->component_template_id->get_column('component_template_directory');
	} else {
		return undef;
	}
}


1;
