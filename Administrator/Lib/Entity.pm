package Entity;

use strict;
use warnings;



=head2 new

	Constructor
	args: data, rightschecker
	
=cut

sub new {
    my $class = shift;
    my %args = @_;
    
    my $self = {
    	_rightschecker => $args{rightschecker},
        _data => $args{data}
    };
    bless $self, $class;

    return $self;
}

=head2 setValue
	
	args: name, value
	set entity param 'name' to 'value'
	
=cut

sub setValue {
	my $self = shift;
	my %args = @_;

	$self->{_data}->set_column( $args{name}, $args{value} );
}

=head2 getValue
	
	args: name
	return value of param 'name'

=cut

sub getValue {
	my $self = shift;
    my %args = @_;

	return $self->{_data}->get_column( $args{name} );
}

sub update {
}

=head2 save
	
	Save entity data in DB afer rights check
	Support entity creation or modification
	
=cut

sub save {
	my $self = shift;

	#TODO check rights

	if ( $self->{_data}->in_storage ) {
		# MODIFY existing db obj
		#print "\n##### MODIFY \n";
		$self->{_data}->update;
	}
	else {
		# CREATE
		my $newentity = $self->{_data}->insert;
		my $row = $self->{_rightschecker}->{_schema}->resultset('Entity')->create(
			{ user_entities => [ {user_id => $newentity->get_column('user_id')} ] },
		);
		$self->{_entity_id} = $row->get_column('entity_id');
	}
		
}

=head2 delete

	Delete entity data in DB 
	
=cut

sub delete {
	my $self = shift;
	
	$self->{_rightschecker}->{_schema}->resultset('Entity')->find( { entity_id => $self->{_entity_id} } )->delete;
	$self->{_data}->delete;
}


# destructor
    
sub DESTROY {}

1;
