
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
use Net::SNMP;

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
	  die $error;
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
		die $session->error();
	}

	my %values = ();
	while ( my ($name, $oid) = each %$var_map ) {
		$values{$name} = $result->{ $oid };	
	}

	return ($time, \%values);
}

sub retrieveTableData {
	my $self =shift;
	my %args = @_;

	my $var_map = $args{var_map};	
	my @columns = map { "$args{table_oid}.1." . $_ } values %$var_map;
	
	my $time =time();
	
	my $result = $self->{_session}->get_entries( -columns => \@columns );
	
	my %res = ();
	while ( my ($ds_name, $entry_oid) = each %$var_map ) {
    	my $column_oid = "$args{table_oid}.1." . $entry_oid;
	    while (my ($res_oid, $value) = each %$result) {
			if ($res_oid =~ /$column_oid\.(.*)/ ) {
		            my $index = $1;
		            $res{$index}{$ds_name} = $value;
			}
    	}
	}
	
	return ($time, \%res);
}

# destructor
sub DESTROY {
	my $self = shift;
	
	# Close session
	my $session = $self->{_session};
	$session->close();
}

1;
