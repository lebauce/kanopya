package AdminWrapper;

my $wrap_class = "MCSAdmin";

# This env var is defined when generate_cronfile.pl with options (currently only 'custom' for CustomAdmin wrapper)
if ( exists $ENV{MCS_ADMIN_WRAPPER} ) {
	$wrap_class = $ENV{MCS_ADMIN_WRAPPER};
}

sub new {
	
	require "AdminWrapper/$wrap_class.pm";
	return $wrap_class->new();	
	
}

1;
