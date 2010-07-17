package EntityData;

use strict;
use warnings;


# contructor 

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


#sub setData {
#	my $self = shift;
#    my ($data) = @_;
#
#	$self->{_data} =  $data;
#}

sub setValue {
	my $self = shift;
    my ($name, $value) = @_;

	$self->{_data}->set_column( $name, $value );
}

sub getValue {
	my $self = shift;
    my ($name) = @_;

	return $self->{_data}->get_column( $name );
}

sub update {
}

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
		#print "\n##### CREATE \n";
		$self->{_data}->insert;
	}
		
}

sub delete {
	my $self = shift;
		
	# check rights

	#$self->{_data}->delete( { cascade_delete => 1 } );

	$self->{_data}->delete( );
}

# override to specific treatment (ex: cascade delete)
sub _onDelete {}

# destructor
    
sub DESTROY {}

1;
