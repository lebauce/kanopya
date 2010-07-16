package EntityData::OperationData;

use strict;

use base "EntityData";

# contructor 

sub new {
    my $class = shift;
    
    my $self = $class->SUPER::new(@_);
    return $self;
}

sub addParams {
	my $self = shift;
	my ($params) = @_;	
	my $data = $self->{_data}; 
	foreach my $k (keys %$params) {
			$data->create_related( 'operation_parameters', { name => $k, value => $params->{$k} } );
	}
}

1;
