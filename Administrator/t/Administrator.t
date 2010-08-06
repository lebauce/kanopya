#!/usr/bin/perl -w

use FindBin qw($Bin);
use lib "$Bin/../Lib", "$Bin/../../Common/Lib";

use McsExceptions;


use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'ERROR', file=>'STDOUT', layout=>'%F %L %p %m%n'});

use Test::More 'no_plan';
use Administrator;
use Data::Dumper;

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

	my $obj = $adm->newEntity( type => "Motherboard", params => { motherboard_sn => '12345', motherboard_mac_address => "00:11:22:33:44:55"} );
		isa_ok( $obj, "Entity::Motherboard", '$obj');
		is( $obj->{_dbix}->in_storage , 0, "new obj doesn't add in DB" ); 
		is( $obj->getAttr( name => 'motherboard_sn' ), '12345', "get value of new obj" );

	$obj->setAttr( name => 'motherboard_sn' , value => '54321' );
		is( $obj->getAttr( name => 'motherboard_sn' ), '54321', "get value after modify new obj" );
	
	eval {
	$obj->setAttr( name => 'extParam1', value  => "extValue1" );};
	if ($@){
		is ($@->isa('Mcs::Exception'), 1, "get Mcs Exception");
		#print Dumper $@;
	}
		
	$obj->save();
		is( $obj->{_dbix}->in_storage , 1, "save obj add in DB" );

	$obj->setAttr( name => 'motherboard_sn', value => '666' ); # change local value but not in db
		is( $obj->getAttr( name => 'motherboard_sn' ), '666', "get value after local change" );
	my $obj_id = $obj->getAttr( name => 'motherboard_id' );
	
	# Obj retrieved from DB
	$obj = $adm->getEntity( type => "Motherboard", id => $obj_id );
		isa_ok( $obj, "Entity::Motherboard", '$obj');
		is( $obj->{_dbix}->in_storage , 1, "get obj from DB" );
		is( $obj->getAttr( name => 'motherboard_sn' ), '54321', "get value after get obj" );
		is( $obj->getAttr( name => 'motherboard_mac_address' ),  "00:11:22:33:44:55", "get extended value after get obj"  );

	$obj->setAttr( name => 'motherboard_sn', value => '666' );
	$obj->save();
	$obj = $adm->getEntity( type => "Motherboard", id => $obj_id );
		is( $obj->getAttr( name => 'motherboard_sn' ), '666', "get value after modify obj" );
		
	$obj->delete();
		is( $obj->{_dbix}->in_storage , 0, "delete in DB" );
	
	# WARN we still can getAttr on deleted obj, the data are only deleted in DB ======> TODO: faire un truc pour empecher ça
		is( $obj->getAttr( name => 'motherboard_sn' ), '666', "get value after get obj" );
		
	#$obj = $adm->getObj( type => "Motherboard", id => $obj_id );
	#	ok( !defined $obj, "get obj with data not in DB return undef" );  # => and warning message is displayed
	
	#
	#	Test Operation
	#
	note( "Test Operation" );
	#my $op3 = $adm->getNextOp( );
	#print $op3->getValue( 'type' ), "    ", $op3->getValue( 'operation_id' );
	
	$adm->newOp( type => 'AddMotherboard', params => { cluster_id => 1, motherboard_sn => "pouet", mac_address => "truc"}, priority => 500);
	my $op = $adm->getNextOp();
		isa_ok( $op, "Operation", '$op');
		is( $op->{_dbix}->in_storage , 1, "save op in DB" );
	
	
	#my $op = $adm->newObj( type => 'Operation', params => { type => "TortueOperation", user_id => 19, execution_rank => 3000 } );
	#$op->save;

	#################################################################################################################################

	$adm->{db}->txn_rollback;
};
if($@) {
	my $error = $@;
	
	$adm->{db}->txn_rollback;
	
	$error->rethrow(); # we wan't fail test if exception
};

