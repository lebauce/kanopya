use lib "../Lib";

use Administrator;

my $adm = Administrator->new( login =>'thom', password => 'pass' );
#my $op = $adm->getObj( "Operation", 15 );
#print $op->getValue( 'type' ), "\n";

#my $op2 = $adm->getObj( "Motherboard", 7 );
#print $op2->getValue( 'motherboard_sn' ), "\n";

my $op3 = $adm->getOp( );
print $op3->getValue( 'type' ), "    ", $op3->getValue( 'operation_id' );
