package Mapper;

use AdministratorDB::Schema;

my %ClassTableMapping = (
	"Operation" => "OperationQueue" );

sub _mapName {
	my ($class_name) = @_;
	my $table_name = $ClassTableMapping{ $class_name };
	return $table_name ? $table_name : $class_name; 	
}

sub getObjData() {

	shift;
	my ( $class_name, $id ) = @_;

	my $dbi_dsn = 'dbi:mysql:administrator:10.0.0.1:3306';
	my $user = 'root';
	my $pass = 'Hedera@123';
	my %dbi_params = ();
	my $schema = AdministratorDB::Schema->connect($dbi_dsn, $user, $pass, \%dbi_params);

	return $schema->resultset( _mapName( $class_name ) )->find( $id );
}

sub getObjs() {

	shift;
	my ( $class_name ) = @_;

	my $dbi_dsn = 'dbi:mysql:administrator:10.0.0.1:3306';
	my $user = 'root';
	my $pass = 'Hedera@123';
	my %dbi_params = ();
	my $schema = AdministratorDB::Schema->connect($dbi_dsn, $user, $pass, \%dbi_params);

	return $schema->resultset( _mapName( $class_name ) );
}

sub addObjData() {
	shift;
	my ( $class_name, $obj_params )  = @_;	
	$obj_params = {} if !$obj_params;

	my $dbi_dsn = 'dbi:mysql:administrator:10.0.0.1:3306';
	my $user = 'root';
	my $pass = 'Hedera@123';
	my %dbi_params = ();
	my $schema = AdministratorDB::Schema->connect($dbi_dsn, $user, $pass, \%dbi_params);


	my $new_obj = $schema->resultset( _mapName( $class_name ) )->create( $obj_params );
	# $new_obj->update; #useless?
	return $new_obj;
}

sub newObjData() {
	shift;
	my ( $class_name, $obj_params )  = @_;	
	$obj_params = {} if !$obj_params;	

	my $dbi_dsn = 'dbi:mysql:administrator:10.0.0.1:3306';
	my $user = 'root';
	my $pass = 'Hedera@123';
	my %dbi_params = ();
	my $schema = AdministratorDB::Schema->connect($dbi_dsn, $user, $pass, \%dbi_params);


	my $new_obj = $schema->resultset( _mapName( $class_name ) )->new( $obj_params );
	
	return $new_obj;
}

1;
