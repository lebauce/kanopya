use lib "../Lib";

use Administrator;

my $adm = Administrator->new( login =>'thom', password => 'pass' );
my $op = $adm->getObj( "Operation", 15 );
print $op->getValue( 'type' );