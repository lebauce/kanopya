use lib qw(../Lib);
use McsExceptions;
use Data::Dumper;

eval {
	print "Before exception\n";
	#die "test";
	throw Mcs::Exception::DB(error => "DB connection failed");
	print "After exception";
};
if ($@) {
if ($@->isa('Mcs::Exception')) 
   {
      print STDERR "Exception DB Received";
      print Dumper $@;
   }
}
print "After Catch\n";