use lib qw(../Lib);
use Kanopya::Exceptions;
use Data::Dumper;

eval {
	print "Before exception\n";
	#die "test";
	throw Kanopya::Exception::DB(error => "DB connection failed");
	print "After exception";
};
if ($@) {
if ($@->isa('Kanopya::Exception')) 
   {
      print STDERR "Exception DB Received";
      print Dumper $@;
   }
}
print "After Catch\n";