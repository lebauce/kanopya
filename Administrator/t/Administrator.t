use lib "../Lib";

use Test::More 'no_plan';
use Administrator;

my $adm = Administrator->new( login =>'thom', password => 'pass' );

#
#	Test generic obj management
#
note( "Test Entity management");
my $obj = $adm->newObj( "Motherboard", { motherboard_sn => '12345'} );
	isa_ok( $obj, "EntityData::MotherboardData", '$obj');
	is( $obj->{_data}->in_storage , 0, "new obj doesn't add in DB" ); 
	is( $obj->getValue( 'motherboard_sn' ), '12345', "get value of new obj" );

$obj->setValue( 'motherboard_sn' , '54321' );
	is( $obj->getValue( 'motherboard_sn' ), '54321', "get value after modify new obj" );
$obj->save();
	is( $obj->{_data}->in_storage , 1, "save obj add in DB" );

$obj->setValue( 'motherboard_sn', '666' ); # change local value but not in db
	is( $obj->getValue( 'motherboard_sn' ), '666', "get value after local change" );

my $obj_id = $obj->getValue( 'motherboard_id' );
$obj = $adm->getObj( "Motherboard", $obj_id );
	isa_ok( $obj, "EntityData::MotherboardData", '$obj');
	is( $obj->{_data}->in_storage , 1, "get obj from DB" );
	is( $obj->getValue( 'motherboard_sn' ), '54321', "get value after get obj" );

$obj->setValue( 'motherboard_sn', '666' );
$obj->save();
$obj = $adm->getObj( "Motherboard", $obj_id );
	is( $obj->getValue( 'motherboard_sn' ), '666', "get value after modify obj" );
	
$obj->delete();
	is( $obj->{_data}->in_storage , 0, "delete in DB" );


#
#	Test Operation
#
note( "Test Operation" );
#my $op3 = $adm->getNextOp( );
#print $op3->getValue( 'type' ), "    ", $op3->getValue( 'operation_id' );

my $op = $adm->newObj( 'Operation', { type => "TortueOperation", execution_rank => 16 } );
	isa_ok( $op, "EntityData::OperationData", '$op');
	is( $op->{_data}->in_storage , 0, "new op doesn't add in DB" );
$op->save;
	is( $op->{_data}->in_storage , 1, "save op in DB" );
$op->addParams( { param_1 => 'toto', param_2 => 'tutu'} );
	is ( $op->getParamValue( 'param_1' ), 'toto', "retrieve op param directly after addParams");
my $params_rs = $op->{_data}->operation_parameters; # just for test DON'T DO THIS! -> local $params_rs will be not updated
	is ( $params_rs->next->in_storage, 1, "op params directly added in db");
$op->delete();
	is( $op->{_data}->in_storage , 0, "auto delete operation in DB when op->delete()" );
$params_rs = $op->{_data}->operation_parameters;
	is ( $params_rs, 0, "auto delete op params in db when op->delete()");

