package Administrator;


use strict;
use AdministratorDB::Schema;
use Data::Dumper;

###########################################
# new (login, password)
# 
# object constructor


sub new {
	my $class = shift;
	my %args = @_;
	
	my $login = $args{login};
	my $password = $args{password};

	# ici on va chercher la conf pour se connecter à la base 
	my $dbi = 'dbi:mysql:administrator:10.0.0.1:3306';
	my $user = 'root';
	my $pass = 'Hedera@123';
	my %opts = ();
		
	my $self = {
		db => AdministratorDB::Schema->connect($dbi, $user, $pass, \%opts),
	};
	
	if( ! $self->{db} ) { die "Unable to connect to the database : "; }
	
	# on recup l'identite de l'utilisateur
	$self->{user} = $self->{db}->resultset('User')->find( { user_login => $login } );
	
	if(! $self->{user} || $self->{user}->user_password ne $password) {
		warn "incorrect login/password pair";
		return undef;
	}
	
	bless $self, $class;
	return $self;
}

# private


# permet de faire le lien entre les classes qui n'ont pas le meme noms que la table en bd
# pas beau trouver autre chose
sub _mapName {
	my %ClassTableMapping = (
		"Operation" => "OperationQueue" );
	
	my ($class_name) = @_;
	my $table_name = $ClassTableMapping{ $class_name };
	return $table_name ? $table_name : $class_name; 	
}

# get dbix class
sub _getData {
	my $self = shift;
	my ( $class_name, $id ) = @_;

	return $self->{db}->resultset( _mapName( $class_name ) )->find( $id );
}

# create dbix class and add row in db
sub _addData {
	my $self = shift;
	my ( $class_name, $obj_params )  = @_;	
	$obj_params = {} if !$obj_params;
	
	my $new_obj = $self->{db}->resultset( _mapName( $class_name ) )->create( $obj_params );
	return $new_obj;	
}

# create dbix class
sub _newData {
	my $self = shift;
	my ( $class_name, $obj_params )  = @_;	
	$obj_params = {} if !$obj_params;	
	
	print "===> ", $self, "  $class_name   $obj_params";
	
	my $new_obj = $self->{db}->resultset( _mapName( $class_name ) )->new( $obj_params );
	
	return $new_obj;
}

# instanciate concrete entity data
sub _newObj {
	my $self = shift;
    my ($type) = @_;

    my $requested_type = "$type" . "Data";    
    my $location = "EntityData/$requested_type.pm";
    my $opclass = "EntityData::$requested_type";
    
    require $location;   

    return $opclass->new( );
}

sub getObj {
	my $self = shift;
    my ($type, $id) = @_;

	my $new_obj = $self->_newObj( $type );
	my $obj_data = $self->_getData( $type, $id );
	
	$new_obj->setData( $obj_data );

    return $new_obj;
}

sub getObjs {}

sub getAllObjs {}

sub newObj {}

sub saveObj {}

1;