
=head1 NAME

VirtualProvider - VirtualProvider object

=head1 SYNOPSIS

    use VirtualProvider;
    
    # Creates provider
    my $provider = VirtualProvider->new( $host );
    
    # Retrieve data
    my $var_map = { 'var_name' => '<Virtual status var name>', ... };
    $provider->retrieveData( var_map => $var_map );

=head1 DESCRIPTION

VirtualProvider is used to retrieve Virtual status values from a specific host.
Virtual status var names correspond to strings in virtual_nodes.adm 

=head1 METHODS

=cut

package VirtualProvider;

use strict;
use warnings;

=head2 new
	
	Class : Public
	
	Desc : Instanciate VirtualProvider instance to provide Virtual stat from a specific host
	
	Args :
		host: string: ip of host
	
	Return : VirtualProvider instance
	
=cut

sub new {
    my $class = shift;
    my %args = @_;

	my $self = {};
	bless $self, $class;

	$self->{_host} = $args{host};
	
    return $self;
}


=head2 retrieveData
	
	Class : Public
	
	Desc : Retrieve a set of snmp var value
	
	Args :
		var_map : hash ref : required  var { var_name => oid }
	
	Return :
		[0] : time when data was retrived
		[1] : resulting hash ref { var_name => value }
	
=cut

sub retrieveData {
	my $self = shift;
	my %args = @_;

	my $var_map = $args{var_map};

	my @OID_list = values( %$var_map );
	my $time =time();

	my %values = ();
	
	open NODES, "</tmp/virtual_nodes.adm";
	while (<NODES>) {
		my $line = $_;
		chomp($line);
		my ($ip, $data) = split " ", $line;
		if ($ip eq $self->{_host}) {
			
			my $load;
			if ($data =~ /LOAD:([\d\.]+)/) {
				$load = $1 || 0;
			}
			else
			{
				$load = undef;

				# TODO autre
				print "## Warning: LOAD not found in virtual nodes file for '$ip'.\n";
			}
			
			while ( my ($name, $oid) = each %$var_map ) {
				my $value = $self->compute( var => $oid, load => $load );
				$values{$name} = $value;
			}
			
#			while ( my ($name, $oid) = each %$var_map ) {
#				my $value;
#				if ($data =~ /$oid:([\d\.]+)/) {
#					$value = $1 || 0;
#				}
#				else
#				{
#					$value = undef;
#					
#					# TODO autre
#					print "## Warning: '$oid' not found in Virtual status.\n";
#				}
#				$values{$name} = $value;
#			}
			last;
		}
	}
	close NODES;
	
	return ($time, \%values);
}

sub compute {
	my $self = shift;
	my %args = @_;
	
	my $var = $args{var};
	my $load =$args{load};
	
	if ($var =~ "CPU") {	
		my $idle;
		if ($load >= 500) {
			$idle = 0;
		} else {
			$idle = 100 - int ($load / 5);
			$idle += ( rand() * 10 ) - 5;
			$idle = $idle < 0 ? 0 : $idle > 90 ? 90 + ( rand() * 10 ) - 5 : $idle;
		}
		my $rest = 95 - $idle;
		my $syst = $rest / ( 4 + rand() );
		my $user = $rest - $syst;
		
		my %res = ( 'idleCPU' => $idle, 'systCPU' => $syst, 'userCPU' => $user);
		return $res{$var};
	} elsif ($var eq "reqPerSec") {
		return $load;
	}
	
	print "Error: no definition to compute virtual var '$args{var}'\n";
	return undef;
}

# destructor
sub DESTROY {
}

1;