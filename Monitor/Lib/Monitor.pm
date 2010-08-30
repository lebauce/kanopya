package Monitor;

use strict;
use warnings;
use RRDTool::OO;
use Net::SNMP;
use String::Random; #temp
use List::Util qw(sum);
use threads;
use XML::Simple;

################################### UTIL ###################################################

#TODO commenter, mettre un exemple, déplacer dans Common

# warning: don't use attribute ['name','id','key'] in your xml tag when list context!
# see @DefKeyAttr in XML::Simple

# return an array ref containing all the elements corresponding to <tag> (in data)
sub getAsArrayRef {
	my %args = @_;
	
	my $data = $args{data};
	#my $tag = $args{tag};
	my $elems = $data->{ $args{tag} };
	if ( ref $elems eq 'ARRAY' ) {
		return $elems;
	}
	return [$elems];
}

# return an hash ref containing all the elements corresponding to <tag> (in data)
# the key is the value of the param key for each elements.
sub getAsHashRef {
	my %args = @_;
	
	my $key = $args{key};
	my $array = getAsArrayRef( data => $args{data}, tag => $args{tag} );
	my %res = ();
	for my $elem (@$array) {
		my $val = delete $elem->{$key}; 
		$res{ $val } = $elem; 
	}
	return \%res;
}

###################################################################################################

=head2 new
	
	Class : Public
	
	Desc : Instanciate Monitor object
	
	Return : Monitor instance
	
=cut

sub new {
    my $class = shift;
    my %args = @_;

	my $self = {};
	bless $self, $class;

	my $conf = XMLin("/workspace/mcs/Monitor/Conf/monitor.conf");

	
	$self->{_time_step} = $conf->{time_step};
	$self->{_rrd_base_dir} = $conf->{rrd_base_dir} || '/tmp';
	$self->{_graph_dir} = $conf->{graph_dir} || '/tmp';
	$self->{_monitored_data} = getAsArrayRef( data => $conf, tag => 'set' );
	
    return $self;
}

=head2 retrieveHosts
	
	Class : Public
	
	Desc : Retrieve the list of monitored hosts
	
	Return : Array of host ip adress
	
=cut

#TODO recuperer vraiment les hosts (en DB ou conf?)
sub retrieveHosts {
	my $self = shift;
	
	return ('192.168.0.123', 'localhost', '127.0.0.1');
}

=head2 createSNMPSession
	
	Class : Public
	
	Desc : Open a snmp connection to host. Don't forget to call CloseSNMPSession() after use.
	
	Args :
		host : string : ip of host
	
	Return : snmp session
	
=cut

sub createSNMPSession {
	my $self = shift;
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

=head2 closeSNMPSession
	
	Class : Public
	
	Desc : Close a snmp session created with createSNMPSession().
	
	Args :
		session : NET::SNMP::Session : the session to close
	
=cut

sub closeSNMPSession {
	my $self = shift;
	my %args = @_;	
 	my $session = $args{session};
	$session->close();
}

=head2 retrieve data
	
	Class : Public
	
	Desc : Retrieve a set of snmp var value
	
	Args :
		session : NET::SNMP::Session : the session used to communicate with host
		var_map : hash ref : required snmp var { var_name => oid }
	
	Return :
		[0] : time when data was retrived
		[1] : resulting hash ref { var_name => value }
	
=cut

sub retrieveData {
	my $self = shift;
	my %args = @_;

	my $session = $args{session};
	my $var_map = $args{var_map};

	my @OID_list = values( %$var_map );
	my $time =time();
	
	my $result = $session->get_request(-varbindlist =>  \@OID_list );        

	if (!defined $result) {
      	#$session->close();
		die "ERROR: ", $session->error();
	}

	print "$time : ";
	my %values = ();
	while ( my ($name, $oid) = each %$var_map ) {
		$values{$name} = $result->{ $oid };
		print " $name : ", $result->{ $oid }, ", ";	
	}
	print "\n";

	return ($time, \%values);
}

=head2 getRRD
	
	Class : Public
	
	Desc : Instanciate a RRDTool object to manipulate the required rrd
	
	Args :
		file : string : the name of the rrd file
	
	Return : The RRDTool object
	
=cut

sub getRRD {
	my $self = shift;
	my %args = @_;

	my $RRDFile = $args{file};
	# rrd constructor (doesn't create file if not exists)
	my $rrd = RRDTool::OO->new( file =>  $self->{_rrd_base_dir} . "/". $RRDFile );

	return $rrd;
}

=head2 createRRD
	
	Class : Public
	
	Desc : Instanciate a RRDTool object and create a rrd
	
	Args :
		dsname_list : the list of var name to store in the rrd
		ds_type : the type of var ( GAUGE, COUNTER, DERIVE, ABSOLUTE )
		file : the name of the rrd file to create
	
	Return : The RRDTool object
	
=cut

sub createRRD {
	my $self = shift;
	my %args = @_;

	my $dsname_list = $args{dsname_list};

	my $rrd = $self->getRRD( file => $args{file} );

	my @rrd_params = ( 	'step', $self->{_time_step},
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

=head2 rebuild
	
	Class : Public
	
	Desc : Recreate a rrd for all monitored host, all stored data will be lost. Use when configuration (set definition) changes.
	
	Args :
		set_label: the name of the set who changed (corresponding to set label in conf)

=cut

sub rebuild {
	my $self = shift;
	my %args = @_;

	my $set_label = $args{set_label}; 
	
	my ($set_def) = grep { $_->{label} eq $set_label} @{ $self->{_monitored_data} };
	my @dsname_list = map { $_->{label} } @{ getAsArrayRef( data => $set_def, tag => 'ds') };
	
	my @hosts = $self->retrieveHosts();
	for my $host (@hosts) {
		$self->createRRD( file => "$set_label"."_$host.rrd", dsname_list => \@dsname_list, ds_type => $set_def->{ds_type} );
	}
}

=head2 updateRRD
	
	Class : Public
	
	Desc : Store values in rrd
	
	Args :
		time: the time associated with values retrieving
		rrd_name: the name of the rrd
		values: hash ref { var_name => value }
		ds_type: the type of data sources (vars)
	
=cut

sub updateRRD {
	my $self = shift;
	my %args = @_;
	
	my $time = $args{time};
	my $rrdfile_name = "$args{rrd_name}.rrd";
	my $rrd = $self->getRRD( file => $rrdfile_name );

	eval {
		$rrd->update( time => $time, values =>  $args{values} );
	};
	# we catch error to handle unexisting file or configuration change.
	# if happens then we create the rrd file. All stored data will be lost.
	if ($@) {
		my $error = $@;
		print "Info: update : unexisting RRD file or set definition changed in conf => we (re)create it ($rrdfile_name).\n";
		my @dsname_list = keys %{ $args{values} };
		$rrd = $self->createRRD( file => $rrdfile_name, dsname_list => \@dsname_list, ds_type => $args{ds_type} );
		$rrd->update( time => $time, values =>  $args{values} );
	} 

}

=head2 graph
	
	Class : Public
	
	Desc : Generate a graph from a rrd, corresponding to one host and one set of data
	
	Args :
		host: the host name
		set_label: the name of the set
		time_laps: the laps in seconds
		ds_def_list: the list of ds definition (ds config: label, color.. ) to stack on the graph
	
	Return : The name of generated graph file
	
=cut

sub graph {
	my $self = shift;
	my %args = @_;

	my $host = $args{host};
	
	my $set_name = $args{set_label};
	my $rrd_name = $set_name . "_" . $host;
	my $graph_filename = "graph_$rrd_name.png";

	#my ($set_def) = grep { $_->{label} eq $set_name} @{ $self->{_monitored_data} };
	#my $ds_list = getAsArrayRef( data => $set_def, tag => 'ds');


	# rrd constructor     
	my $rrd = $self->getRRD( file => "$rrd_name.rrd" );

	my @graph_params = (
						'image', "$self->{_graph_dir}/$graph_filename",
						#'vertical_label', 'ticks',
						'start', time() - $args{time_laps}
						);

	my $color = new String::Random;
	my $first = 1;
	foreach my $ds (@{ $args{ds_def_list} }) {
		push @graph_params, (
								draw   => {
									type   => $first == 1 ? "area" : "stack",
									dsname => $ds->{label},
									#color  => $color->randregex('[1F]{6}'),
									color => $ds->{color} || "FFFFFF",
									legend => $ds->{label},
	  							}	
							);
		$first = 0;
	}

	# Draw a graph in a PNG image
	$rrd->graph( @graph_params );
	
	return $graph_filename;
}

=head2 makeGraph
	
	Class : Public
	
	Desc : Generate graph of each defined set of data (conf), for all monitored hosts 
	
	Args :
		time_laps : int : laps in seconds
	
	Return : Hash ref containing filenames of all generated graph { host => { set_label => "file.png" } }
	
=cut

sub makeGraph {
	my $self = shift;
	my %args = @_;
	
	my $time_laps = $args{time_laps};
	
	my %res; #the hash containing filename of all generated graph (host => { set_label => "file.png" })
	
	my @hosts = $self->retrieveHosts();
	foreach my $host (@hosts) {
		foreach my $set_def ( @{ $self->{_monitored_data} } ) {
			my $ds_def_list = getAsArrayRef( data => $set_def, tag => 'ds');
			eval {
				my $graph_filename = $self->graph( 	host => $host,
													time_laps => $time_laps,
													set_label => $set_def->{label},
													ds_def_list => $ds_def_list );
				$res{$host}{$set_def->{label}} = $graph_filename;
			};
			if ($@) {
				my $error = $@;
				#print "$error\n";
			}
		}
	}
	
	return \%res;
}

#TODO amélioration
sub fetch {
	my $self = shift;
	my %args = @_;

	my $rrd_name = $args{rrd_name};

	# rrd constructor     
	my $rrd = $self->getRRD(file => "$rrd_name.rrd" );

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

#TODO un truc mieux qui marche
# getData( rdd_name, ds_name, nb, percent ) 
# if percent is defined then return percentage instead direct value 
sub getData {
	my $self = shift;
	my %args = @_;
	
	my $rrd_name = $args{rrd_name};

	# rrd constructor     
	my $rrd = $self->getRRD(file => "$rrd_name.rrd" );

	# Start fetching values
	$rrd->fetch_start( start => time() - ( $self->{_time_step} * $args{nb} ) );
	$rrd->fetch_skip_undef();

	# retrieve array of ds name ordered like in rrd (db column)	
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

	# debug
	for my $v (@res) {
		print "$v\n";	
	}
	
	return @res;
}

=head2 updateHostData
	
	Class : Public
	
	Desc : For a host, retrieve value of all monitored data (snmp var defined in conf) and store them in corresponding rrd
	
	Args :
		host : the host name

=cut

sub updateHostData {
	my $self = shift;
	my %args = @_;

	my $host = $args{host};
	my $session = $self->createSNMPSession( host => $host );
	eval {
		#For each set of snmp var defined in conf file
		foreach my $set ( @{ $self->{_monitored_data} } ) {

			# Build the required var map: ( var_name => oid )
			my %var_map = map { $_->{label} => $_->{oid} } @{ getAsArrayRef( data => $set, tag => 'ds') };
			
			# Retrieve the map ref { var_name => snmp_value } corresponding to required var_map
			my ($time, $update_values) = $self->retrieveData( session => $session, var_map => \%var_map );
			
			# Store new values in the corresponding RRD
			$self->updateRRD( rrd_name => "$set->{label}"."_$host", ds_type => $set->{ds_type}, time => $time, values => $update_values );
		}
	};
	if ($@) {
		my $error = $@;
		print "===> $error";
	}
	$self->closeSNMPSession(session => $session);
}

=head2 udpate
	
	Class : Public
	
	Desc : Create a thread to update data for every monitored host
	
=cut

sub update {
	my $self = shift;
	my @hosts = $self->retrieveHosts();
	for my $host (@hosts) {
		# We create a thread for each host to don't block update if a host is unreachable 
		my $thr = threads->create('updateHostData', $self, host => $host);
		$thr->detach();
	}
}

=head2 run
	
	Class : Public
	
	Desc : Launch an update every time_step (configuration)
	
=cut

sub run {
	my $self = shift;
	
	while ( 1 ) {
		$self->update();
		sleep( $self->{_time_step} );
	}
}

1;

