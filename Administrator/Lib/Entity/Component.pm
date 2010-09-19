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

sub getComponentAttr {
	my $self = shift;
	my %args = @_;
	my $componentAttr = {};
	
	$componentAttr->{component_name} = $self->{_dbix}->component_id->get_column('component_name');
	$componentAttr->{component_id} = $self->{_dbix}->component_id->get_column('component_id');	
	$componentAttr->{component_version} = $self->{_dbix}->component_id->get_column('component_version');
	$componentAttr->{component_category} = $self->{_dbix}->component_id->get_column('component_category');
	
	return $componentAttr;	
}


1;
