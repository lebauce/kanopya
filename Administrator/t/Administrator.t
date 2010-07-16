use lib "../Lib";

use Administrator;

my $adm = Administrator->new( login =>'thom', password => 'pass' );
#my $op = $adm->getObj( "Operation", 15 );
#print $op->getValue( 'type' ), "\n";

#my $op2 = $adm->getObj( "Motherboard", 7 );
#print $op2->getValue( 'motherboard_sn' ), "\n";

my $op3 = $adm->getNextOp( );
print $op3->getValue( 'type' ), "    ", $op3->getValue( 'operation_id' );


my $op4 = $adm->newObj( 'Operation', { execution_rank => 11 } );
$op4->save;
$op4->addParams( { param_1 => 'toto', param_2 => 'tutu'} );
print "######## ", $op4->getParamValue( 'param_1' ), "\n";

$op4->delete;

#my $op5 = $adm->getObj( 'Operation', 15 );
#$op5->delete();