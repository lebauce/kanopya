package Monitor;

use strict;
use warnings;
use RRDTool::OO;
use Net::SNMP;
use String::Random;
use List::Util qw(sum);
use threads;

############################ CONFIGURATION ####################################

my %RRDs_def = 	( "memory" => {
								ds_type => "GAUGE",
								data_sources => {
													'TotalSwap' => '.1.3.6.1.4.1.2021.4.3.0',
													'AvailableSwap' => '.1.3.6.1.4.1.2021.4.4.0',
													'memTotal' => '.1.3.6.1.4.1.2021.4.5.0',
													'memAvail' => '.1.3.6.1.4.1.2021.4.6.0',
													'memFree' => '.1.3.6.1.4.1.2021.4.11.0',
													#'Total RAM Shared' => '.1.3.6.1.4.1.2021.4.13.0', #pas implémenté sur certains host (comme d'autre snmp var) faire une vérification
													'memBuffered' => '.1.3.6.1.4.1.2021.4.14.0',
													'memCached' => '.1.3.6.1.4.1.2021.4.15.0',
												}
								},
					"cpu" => {
								ds_type => "COUNTER",
								data_sources => {
													'rawUserCPU' => '.1.3.6.1.4.1.2021.11.50.0',
													'rawNiceCPU' => '.1.3.6.1.4.1.2021.11.51.0',
													'rawSystCPU' => '.1.3.6.1.4.1.2021.11.52.0', # Des fois implementé comme la somme de 'ssCpuRawWait(54)' et 'ssCpuRawKernel(55)'

													'rawIdleCPU' => '.1.3.6.1.4.1.2021.11.53.0',
													'rawWaitCPU' => '.1.3.6.1.4.1.2021.11.54.0',
													'rawKernelCPU' => '.1.3.6.1.4.1.2021.11.55.0',
													'rawInterruptCPU' => '.1.3.6.1.4.1.2021.11.56.0',
												}
							},
				);

my $STEP = 5;

my $RRD_DIR = "./data";
my $GRAPH_DIR = "./graph";

###########################################################################################################

sub new {
    my $class = shift;
    my %args = @_;

	my $self = {};

	bless $self, $class;
    return $self;
}


sub retrieveHosts {
	return ('192.168.0.123', 'localhost', '127.0.0.1');
}

sub createSNMPSession {
	my %args = @_;	

	# Create snmp session
	my $host = $args{host};
	my ($session, $error) = Net::SNMP->session(
	  -hostname  => $host,
	  -community => 'my_comnt',
	);

	if (!defined $session) {
	  die "ERROR: ", $error;
	}
	
	return $session;
}

sub closeSNMPSession {
	my %args = @_;	
 	my $session = $args{session};
	$session->close();
}

sub retrieveData {
	my %args = @_;

	my $session = $args{session};
	my $var_map = $args{var_map};

	my @OID_list = values( %$var_map );
	my $result = $session->get_request(-varbindlist =>  \@OID_list );        

	if (!defined $result) {
      	#$session->close();
		die "ERROR: ", $session->error();
	}

	my $time = time();
	print "$time : ";
	my %values = ();
	while ( my ($name, $oid) = each %$var_map ) {
		$values{$name} = $result->{ $oid };
		print " $name : ", $result->{ $oid }, ", ";	
	}
	print "\n";

	return \%values;
}

sub getRRD {
	my %args = @_;

	my $RRDFile = $args{file};
	# rrd constructor (doesn't create file if not exists)
	my $rrd = RRDTool::OO->new( file =>  $RRD_DIR . "/". $RRDFile );

	return $rrd;
}

sub createRRD {
	my %args = @_;

	my $RRDFile = $args{file};
	my $dsname_list = $args{dsname_list};

	my $rrd = RRDTool::OO->new( file =>  $RRD_DIR . "/". $RRDFile );

	my @rrd_params = ( 	'step', $args{nb_step},
						'archive', { rows      => 100 }
					 );
	for my $name ( @$dsname_list ) {
		push @rrd_params, 	(
								'data_source' => { 	name      => $name,
			     	         						type      => $args{ds_type} },
							);
	}

	# Create a round-robin database
	$rrd->create( @rrd_params );
	
	return $rrd;
}

sub updateRRD {
	my %args = @_;
	
	my $step = $args{nb_step};
	my $rrd_def = $args{rrd_def};
	my $var_map = $rrd_def->{data_sources};
	my @dsname_list = keys %$var_map;
	
	# get RRD or create if doesn't exist
	my $rrdfile_name = "$args{rrd_name}.rrd";
	my $rrd = ( -e $RRD_DIR."/".$rrdfile_name )
	 			? getRRD( file => $rrdfile_name )
				: createRRD( file => $rrdfile_name, dsname_list => \@dsname_list, ds_type => $rrd_def->{ds_type}, nb_step => $step);

	$rrd->update( time => time(), values => $args{values} );

}

sub graph {
	my %args = @_;

	my $rrd_name = $args{rrd_name};
	my $rrd_def = $RRDs_def{ $rrd_name };
	my $var_map = $rrd_def->{data_sources};
	my @dsname_list = keys %$var_map;

	# rrd constructor     
	my $rrd = getRRD( file => "$rrd_name.rrd" );

	my @graph_params = (
						'image', "$GRAPH_DIR/graph_$rrd_name.png",
						#'vertical_label', 'ticks',
						'start', time() - 60
						);

	my $color = new String::Random;

	for my $dsname (@dsname_list) {
		push @graph_params, (
								draw   => {
									type   => "stack",
									dsname => $dsname,
									color  => $color->randregex('[1F]{6}'),
									legend => $dsname,
	  							}	
							);
	}

	# Draw a graph in a PNG image
	$rrd->graph( @graph_params );
}

sub fetch {
	my %args = @_;

	my $rrd_name = $args{rrd_name};

	# rrd constructor     
	my $rrd = getRRD(file => "$rrd_name.rrd" );

	# Start fetching values from one day back, 
	# but skip undefined ones first
	$rrd->fetch_start( start => time() - 60);
	$rrd->fetch_skip_undef();

	# Fetch stored values
	while(my($time, @values) = $rrd->fetch_next()) {
		print "$time: ", ( map { (defined $_ ? $_ : "[undef]") . " | " } @values ), "\n";
		print ("SUM = ", sum(@values), "\n") if defined $values[0];
	}
}

# getData( rdd_name, ds_name, nb, percent ) 
# if percent is defined then return percentage instead direct value 
sub getData {
	my %args = @_;
	
	my $rrd_name = $args{rrd_name};

	# rrd constructor     
	my $rrd = RRDTool::OO->new(file => "$rrd_name.rrd" );

	# Start fetching values from one day back, 
	# but skip undefined ones first
	$rrd->fetch_start( start => time() - ( $STEP * $args{nb} ) );
	$rrd->fetch_skip_undef();

	# retrieve array of ds name ordered like in rrd 	
	my $ds_names = $rrd->{fetch_ds_names};
	# find the index of required ds
	my $ds_idx = 0;
	++$ds_idx until ( ($ds_idx == scalar @$ds_names) or ($ds_names->[$ds_idx] eq $args{ds_name}) ); 
	
	if ($ds_idx == scalar @$ds_names) {
		die "Invalid ds_name for this RRD : '$args{ds_name}'";	
	}

	# Build res array and hash (with time as key, warning hash is not ordered )
	my @res = ();
	while(my($time, @values) = $rrd->fetch_next()) {
		#print "$time: ", $values[$ds_idx] , "\n";
		#$res{$time} = $values[$ds_idx] if defined $values[$ds_idx];
		if (defined $values[$ds_idx]) {		
			if (defined $args{percent}) {
				my $total = sum @values;
				my $p = ($values[$ds_idx] * 100) / $total;	
				push @res, $p;
			} else {
				push @res, $values[$ds_idx];
			}
		}
	}

	for my $v (@res) {
		print "$v\n";	
	}
	
	return @res;
}

sub updateHostData {
	my %args = @_;

	my $host = $args{host};
	my $session = createSNMPSession( host => $host );
	eval {
		while ( my ($RRD_name, $RRD_def) = each %RRDs_def ) {
		
			my $update_values = retrieveData( session => $session, var_map => $RRD_def->{data_sources} );
			updateRRD( rrd_name => "$RRD_name"."_$host", rrd_def => $RRD_def, values => $update_values, nb_step => $STEP);
		}
	};
	if ($@) {
		my $error = $@;
		print "===> $error";
		#closeSNMPSession(session => $session);
	}
	closeSNMPSession(session => $session);
}

sub update {
	my @hosts = retrieveHosts();
	for my $host (@hosts) {
		#updateHostData( host => $host );

		my $thr = threads->create('updateHostData', host => $host);
		$thr->detach();
	}
}

sub run {
	while ( 1 ) {
		update();
		sleep( $STEP );
	}
}

1;

