#!/usr/bin/perl -w
# $Bin is full path to this file directory
# we can now call this script from everywhere
# warn: not secure
# TODO: il y a surement mieux à faire pour gérer les path
#use FindBin qw($Bin);
#use lib "$Bin/../Lib";
use lib qw(../Lib); # same as above


use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'STDOUT', layout=>'%F %L %p %m%n'});

use Test::More 'no_plan';
use Administrator;

use Try::Tiny;

my $adm = Administrator->new( login =>'thom', password => 'pass' );

# Print sql queries
#BEGIN { $ENV{DBIC_TRACE} = 1 }


# TODO: deplacer les tests sur les entity dans Entity.t 

#
#	Test generic obj management
#
note( "Test Entity management");

try {
	$adm->{db}->txn_begin;
	
	#################################################################################################################################
	
	# Obj creation
	my $obj = $adm->newObj( type => "Motherboard", params => { motherboard_sn => '12345'} );
		isa_ok( $obj, "Entity::Motherboard", '$obj');
		is( $obj->{_data}->in_storage , 0, "new obj doesn't add in DB" ); 
		is( $obj->getValue( name => 'motherboard_sn' ), '12345', "get value of new obj" );
	
	$obj->setValue( name => 'motherboard_sn' , value => '54321' );
		is( $obj->getValue( name => 'motherboard_sn' ), '54321', "get value after modify new obj" );
	
	$obj->setValue( name => 'extParam1', value  => "extValue1" );
		is( $obj->{_data}->in_storage , 0, "set ext values doesn't add obj in DB" );
		is( $obj->getValue( name => 'extParam1' ), 'extValue1', "get ext value after modify new obj" );
		
	$obj->save();
		is( $obj->{_data}->in_storage , 1, "save obj add in DB" );
	
	$obj->setValue( name => 'motherboard_sn', value => '666' ); # change local value but not in db
		is( $obj->getValue( name => 'motherboard_sn' ), '666', "get value after local change" );
	my $obj_id = $obj->getValue( name => 'motherboard_id' );
	
	# Obj retrieved from DB
	$obj = $adm->getObj( type => "Motherboard", id => $obj_id );
		isa_ok( $obj, "Entity::Motherboard", '$obj');
		is( $obj->{_data}->in_storage , 1, "get obj from DB" );
		is( $obj->getValue( name => 'motherboard_sn' ), '54321', "get value after get obj" );
		is( $obj->getValue( name => 'extParam1' ),  "extValue1", "get extended value after get obj"  );
	
	$obj->setValue( name => 'motherboard_sn', value => '666' );
	$obj->save();
	$obj = $adm->getObj( type => "Motherboard", id => $obj_id );
		is( $obj->getValue( name => 'motherboard_sn' ), '666', "get value after modify obj" );
		
	$obj->delete();
		is( $obj->{_data}->in_storage , 0, "delete in DB" );
	
	# WARN we still can getValue on deleted obj, the data are only deleted in DB ======> TODO: faire un truc pour empecher ça
		is( $obj->getValue( name => 'motherboard_sn' ), '666', "get value after get obj" );
		
	#$obj = $adm->getObj( type => "Motherboard", id => $obj_id );
	#	ok( !defined $obj, "get obj with data not in DB return undef" );  # => and warning message is displayed
	
	#
	#	Test Operation
	#
	note( "Test Operation" );
	#my $op3 = $adm->getNextOp( );
	#print $op3->getValue( 'type' ), "    ", $op3->getValue( 'operation_id' );
	
	my $op = $adm->newObj( type => 'Operation', params => { type => "TortueOperation", user_id => 19, execution_rank => 18 } );
		isa_ok( $op, "Entity::Operation", '$op');
		is( $op->{_data}->in_storage , 0, "new op doesn't add in DB" );
		
	$op->save;
		is( $op->{_data}->in_storage , 1, "save op in DB" );
	$op->addParams( { param_1 => 'toto', param_2 => 'tutu'} );
		is ( $op->getParamValue( 'param_1' ), 'toto', "retrieve op param directly after addParams");
	my $params_rs = $op->{_data}->operation_parameters; # just for test DON'T DO THIS! -> local $params_rs will be not updated
		is ( $params_rs->next->in_storage, 1, "op params directly added in db");
	$op->delete();
		is( $op->{_data}->in_storage , 0, "delete operation in DB when op->delete()" );
	$params_rs = $op->{_data}->operation_parameters;
		is ( $params_rs, 0, "auto delete op params in db when op->delete()");
	
	
	#my $op = $adm->newObj( type => 'Operation', params => { type => "TortueOperation", user_id => 19, execution_rank => 3000 } );
	#$op->save;

	#################################################################################################################################

	$adm->{db}->txn_rollback;
}
catch {
	#my $error = shitf;
	
	$adm->{db}->txn_rollback;
	
	print "##### ERROR\n";
};

