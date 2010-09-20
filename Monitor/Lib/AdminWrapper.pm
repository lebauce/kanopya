package AdminWrapper;

#my $wrap_class = "MCSAdmin";
my $wrap_class = "CustomAdmin";

sub new {
	
	require "AdminWrapper/$wrap_class.pm";
	return $wrap_class->new();	
	
}

1;
