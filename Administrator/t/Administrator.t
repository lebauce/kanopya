#!/usr/bin/perl -w

use lib qw(/workspace/mcs/Administrator/Lib /workspace/mcs/Common/Lib);

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'STDOUT', layout=>'%F %L %p %m%n'});

use Test::More 'no_plan';
use Administrator;
use Data::Dumper;
use McsExceptions;

my $adm = Administrator->new( login =>'thom', password => 'pass' );

# Print sql queries
#BEGIN { $ENV{DBIC_TRACE} = 1 }


# TODO: deplacer les tests sur les entity dans Entity.t 

#
#	Test generic obj management
#
note( "Test Entity management");

eval {
	$adm->{db}->txn_begin;
	
	#################################################################################################################################
	
	# Obj creation

	my $obj = $adm->newEntity(
		type => "Motherboard", 
		params => { 
			motherboard_model_id => 1,
			processor_model_id => 1, # motherboard model has an integrated processor
			kernel_id => 1,
			motherboard_serial_number => '12345', 
			motherboard_mac_address => "00:11:22:33:44:55",
			motherboard_slot_position => 1,
			active => 0}
		);
		
		isa_ok( $obj, "Entity::Motherboard", '$obj');
		is( $obj->{_dbix}->in_storage , 0, "new obj doesn't add in DB" ); 
		is( $obj->getAttr( name => 'motherboard_serial_number' ), '12345', "get value of new obj" );

	$obj->setAttr( name => 'motherboard_serial_number' , value => '54321' );
		is( $obj->getAttr( name => 'motherboard_serial_number' ), '54321', "get value after modify new obj" );
	
	eval {
	$obj->setAttr( name => 'extParam1', value  => "extValue1" );};
	if ($@){
		is ($@->isa('Mcs::Exception'), 1, "get Mcs Exception");
		#print Dumper $@;
	}
		
	$obj->save();
		is( $obj->{_dbix}->in_storage , 1, "save obj add in DB" );

	$obj->setAttr( name => 'motherboard_serial_number', value => '666' ); # change local value but not in db
		is( $obj->getAttr( name => 'motherboard_serial_number' ), '666', "get value after local change" );
	my $obj_id = $obj->getAttr( name => 'motherboard_id' );
	
	# Obj retrieved from DB
	$obj = $adm->getEntity( type => "Motherboard", id => $obj_id );
		isa_ok( $obj, "Entity::Motherboard", '$obj');
		is( $obj->{_dbix}->in_storage , 1, "get obj from DB" );
		is( $obj->getAttr( name => 'motherboard_serial_number' ), '54321', "get value after get obj" );
		is( $obj->getAttr( name => 'motherboard_mac_address' ),  "00:11:22:33:44:55", "get extended value after get obj"  );

	$obj->setAttr( name => 'motherboard_serial_number', value => '666' );
	$obj->save();
	$obj = $adm->getEntity( type => "Motherboard", id => $obj_id );
		is( $obj->getAttr( name => 'motherboard_serial_number' ), '666', "get value after modify obj" );

	note( "Test Entity activate");
	is( $obj->getAttr( name => 'active' ), '0', "get active value" );
#	print "" .  $obj->getAttr( name => 'active') . "\n";
	$obj->activate();
	is( $obj->getAttr( name => 'active' ), '1', "get active value after activate" );
#	print "" .  $obj->getAttr( name => 'active') . "\n";

	$obj->delete();
		is( $obj->{_dbix}->in_storage , 0, "delete in DB" );
	
	# WARN we still can getAttr on deleted obj, the data are only deleted in DB ======> TODO: faire un truc pour empecher ça
		is( $obj->getAttr( name => 'motherboard_serial_number' ), '666', "get value after get obj" );
	
	#$obj = $adm->getObj( type => "Motherboard", id => $obj_id );
	#	ok( !defined $obj, "get obj with data not in DB return undef" );  # => and warning message is displayed
	
	#
	#	Test Operation
	#
#	note( "Test Operation" );
#	#my $op3 = $adm->getNextOp( );
#	#print $op3->getValue( 'type' ), "    ", $op3->getValue( 'operation_id' );
#	
#	$adm->newOp(type => 'AddMotherboard', 
#				priority => 500,
#				params => { 
#					motherboard_serial_number => "pouet", 
#					motherboard_mac_address => "truc",
#					motherboard_model_id => 1
#				});
#	my $op = $adm->getNextOp();
#		isa_ok( $op, "Operation", '$op');
#		is( $op->{_dbix}->in_storage , 1, "save op in DB" );
	
	
	#my $op = $adm->newObj( type => 'Operation', params => { type => "TortueOperation", user_id => 19, execution_rank => 3000 } );
	#$op->save;

	#################################################################################################################################

	$adm->{db}->txn_rollback;
};
if($@) {
	my $error = $@;
	
	$adm->{db}->txn_rollback;
	print "$error";
	exit 233;
#	$error->rethrow(); # we wan't fail test if exception
};

