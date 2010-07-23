use Data::Dumper;
use Log::Log4perl qw(:easy);
use Test::More 'no_plan';

use lib qw(../Lib/);
use McsError;
#use Error qw(:try);

#$SIG{__DIE__} = sub {print "Die De moi !!!\n";};
#die ("Héhé");
try {
	print "In Try\n";
	throw McsError "Error in try";
}
catch McsError with {
	my $error = shift;
	print "In Catch\n";
	print Dumper $error;
}
finally {
	print "In Finally\n";
}
