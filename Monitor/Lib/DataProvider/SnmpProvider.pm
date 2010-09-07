
=head1 NAME

SnmpProvider - SnmpProvider object

=head1 SYNOPSIS

    use SnmpProvider;
    
    # Creates provider
    my $provider = SnmpProvider->new( $host );
    
    # Retrieve data
    my $var_map = { 'var_name' => '<snmp_OID>', ... };
    $provider->retrieveData( var_map => $var_map );

=head1 DESCRIPTION

SnmpProvider is used to retrieve snmp var values from a specific host.
Can retrieve value for all OIDs (see snmp MIBs).

=head1 METHODS

=cut

package SnmpProvider;

use strict;
use warnings;

=head2 new
	
	Class : Public
	
	Desc : Instanciate SnmpProvider instance to provide snmp var values from a specific host
	
	Args :
		host: string: ip of host
	
	Return : SnmpProvider instance
	
=cut

sub new {
    my $class = shift;
    my %args = @_;

	my $self = {};
	bless $self, $class;

	# Create snmp session
	my $host = $args{host};
	my ($session, $error) = Net::SNMP->session(
	  -hostname  => $host,
	  -community => 'my_comnt',
	);

	if (!defined $session) {
	  die "ERROR (new) : ", $error;
	}
	
	$self->{_session} = $session;
	
    return $self;
}


=head2 retrieveData
	
	Class : Public
	
	Desc : Retrieve a set of snmp var value
	
	Args :
		var_map : hash ref : required snmp var { var_name => oid }
	
	Return :
		[0] : time when data was retrived
		[1] : resulting hash ref { var_name => value }
	
=cut

sub retrieveData {
	my $self = shift;
	my %args = @_;

	my $session = $self->{_session};
	my $var_map = $args{var_map};

	my @OID_list = values( %$var_map );
	my $time =time();
	
	my $result = $session->get_request(-varbindlist =>  \@OID_list );        

	if (!defined $result) {
      	#$session->close();
		die "ERROR (retrieve) : ", $session->error();
	}

	my %values = ();
	while ( my ($name, $oid) = each %$var_map ) {
		$values{$name} = $result->{ $oid };	
	}

	return ($time, \%values);
}

# destructor
sub DESTROY {
	my $self = shift;
	
	# Close session
	my $session = $self->{_session};
	$session->close();
}

1;
