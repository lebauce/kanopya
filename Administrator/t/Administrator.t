use lib "../Lib";

use Test::More 'no_plan';
use Administrator;

my $adm = Administrator->new( login =>'thom', password => 'pass' );

#
#	Test generic obj management
#
my $obj = $adm->newObj( "Motherboard", { motherboard_sn => '12345'} );
	isa_ok( $obj, "EntityData::MotherboardData", '$obj');
	is( $obj->{_data}->in_storage , 0, "new obj doesn't add in DB" ); 
	is( $obj->getValue( 'motherboard_sn' ), '12345', "get value" );

$obj->setValue( 'motherboard_sn' , '54321' );
	is( $obj->getValue( 'motherboard_sn' ), '54321', "get value of new obj" );
$obj->save();
	is( $obj->{_data}->in_storage , 1, "save obj add in DB" );

$obj->setValue( 'motherboard_sn', '666' ); # change local value but not in db
	is( $obj->getValue( 'motherboard_sn' ), '666', "get value after local change" );

my $obj_id = $obj->getValue( 'motherboard_id' );
my $obj = $adm->getObj( "Motherboard", $obj_id );
	isa_ok( $obj, "EntityData::MotherboardData", '$obj');
	is( $obj->{_data}->in_storage , 1, "get obj from DB" );
	is( $obj->getValue( 'motherboard_sn' ), '54321', "get value after get obj" );

$obj->setValue( 'motherboard_sn', '666' );
$obj->save();
my $obj = $adm->getObj( "Motherboard", $obj_id );
	is( $obj->getValue( 'motherboard_sn' ), '666', "get value after modify obj" );
	
$obj->delete();
	is( $obj->{_data}->in_storage , 0, "delete in DB" );


#
#	Test Operation
#
my $op3 = $adm->getNextOp( );
#print $op3->getValue( 'type' ), "    ", $op3->getValue( 'operation_id' );


my $op4 = $adm->newObj( 'Operation', { type => "AddMotherBoard", execution_rank => 11 } );
$op4->save;
$op4->addParams( { param_1 => 'toto', param_2 => 'tutu'} );

is ( $op4->getParamValue( 'param_1' ), 'toto', "retrieve op param directly after addParams");

$op4->delete;

#my $op5 = $adm->getObj( 'Operation', 15 );
#$op5->delete();

