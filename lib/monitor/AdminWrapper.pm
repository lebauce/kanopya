package AdminWrapper;

my $wrap_class = "MCSAdmin";

# set this env var to specific admin wrapper class name
if ( exists $ENV{MCS_ADMIN_WRAPPER} ) {
	$wrap_class = $ENV{MCS_ADMIN_WRAPPER};
}

sub new {
	shift;
	my @args = @_;
	
	require "AdminWrapper/$wrap_class.pm";
	return $wrap_class->new( @args );	
	
}

1;
