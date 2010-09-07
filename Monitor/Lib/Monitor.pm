# Monitor.pm - Object class of Monitor

# Copyright (C) 2009, 2010, 2011, 2012, 2013
#   Free Software Foundation, Inc.

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; see the file COPYING.  If not, write to the
# Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
# Boston, MA 02110-1301 USA.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.
# Created 20 august 2010

=head1 NAME

Monitor - Monitor object

=head1 SYNOPSIS

    use Monitor;
    
    # Creates monitor
    my $monitor = Monitor->new();

=head1 DESCRIPTION

Monitor is the main object used to collect, store and provide hosts informations. 

=head1 METHODS

=cut

package Monitor;

#TODO Modulariser: Collector, DataProvider (snmp, generator,...), DataStorage (rrd, ...), DataManipulator, Grapher, ...

use lib qw(/workspace/mcs/Administrator/Lib /workspace/mcs/Common/Lib);

use strict;
use warnings;
use RRDTool::OO;
use Net::SNMP;
use List::Util qw(sum);
use threads;
use XML::Simple;
use Net::Ping;
use Administrator;
use General;

#use SnmpProvider;

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

	# Load conf
	my $conf = XMLin("/workspace/mcs/Monitor/Conf/monitor.conf");
	$self->{_time_step} = $conf->{time_step};
	$self->{_period} = $conf->{period};
	$self->{_rrd_base_dir} = $conf->{rrd_base_dir} || '/tmp';
	$self->{_graph_dir} = $conf->{graph_dir} || '/tmp';
	$self->{_monitored_data} = General::getAsArrayRef( data => $conf, tag => 'set' );

	# Get Administrator
	$self->{_admin} = Administrator->new( login =>'thom', password => 'pass' );

	# test (data generator)
	$self->{_t} = 0;
	
    return $self;
}

=head2 retrieveHostsByCluster
	
	Class : Public
	
	Desc : Retrieve the list of monitored hosts
	
	Return : Hash with key the cluster name and value an array ref of host ip address for this cluster
	
=cut

sub retrieveHostsByCluster {
	my $self = shift;

	my $adm = $self->{_admin};
	my @clusters = $adm->getEntities( type => "Cluster", hash => { } );
	my %hosts_by_cluster;
	foreach my $cluster (@clusters) {
		my @mb_ip;
		foreach my $mb ( values %{ $cluster->getMotherboards( administrator => $adm) } ) {
			push @mb_ip, $mb->getAttr( name => "motherboard_internal_ip" );
		}
		$hosts_by_cluster{ $cluster->getAttr( name => "cluster_name" ) } = \@mb_ip;
	}	
	
	# TEMPORARY !!
	%hosts_by_cluster = ( 	"cluster_1" => ['localhost', '127.0.0.1'],
							"cluster_2" => ['192.168.0.123'] );
	
	return %hosts_by_cluster;
}

=head2 retrieveHosts
	
	Class : Public
	
	Desc : Retrieve the list of monitored hosts
	
	Return : Array of host ip address
	
=cut

sub retrieveHosts {
	my $self = shift;
	
	my %hosts_by_cluster = $self->retrieveHostsByCluster();
	my @hosts = map { @$_ } values( %hosts_by_cluster );
	
	return @hosts;
}

############ TEST #################
sub gaussData {
	my $self = shift;
	my %args = @_;
	
	my $var_map = $args{var_map};
	
	my $time = time();
	print "$time : ";
	my %values = ();
	for my $var_name (keys %$var_map) {
		$values{ $var_name } = sin $self->{_t}; 
		print " $var_name : ", $values{ $var_name }, ", ";
	}
	print "\n";
	
	return ($time, \%values);
}


=head2 rrdName
	
	Class : Public
	
	Desc : build the rrd name uniformly.
	
	Args :
		set_name: string: name of the data set stored in the rrd
		host_name: string: name of the host providing the data
	
	Return :
	
=cut

sub rrdName {
	my $self = shift;
	my %args = @_;
	return $args{set_name} . "_" . $args{host_name};
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

	my $raws = $self->{_period} / $self->{_time_step};

	my @rrd_params = ( 	'step', $self->{_time_step},
						'archive', { rows	=> $raws }
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
	my @dsname_list = map { $_->{label} } @{ General::getAsArrayRef( data => $set_def, tag => 'ds') };
	
	my @hosts = $self->retrieveHosts();
	for my $host (@hosts) {
		my $rrd_name = $self->rrdName( set_name => $set_label, host_name => $host );
		$self->createRRD( file => "$rrd_name.rrd", dsname_list => \@dsname_list, ds_type => $set_def->{ds_type} );
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
		$rrd->update( time => $time, values =>  $args{data} );
	};
	# we catch error to handle unexisting file or configuration change.
	# if happens then we create the rrd file. All stored data will be lost.
	if ($@) {
		my $error = $@;
		#print "==> $error\n";
		print "=> Info: update : unexisting RRD file or set definition changed in conf => we (re)create it ($rrdfile_name).\n";
		my @dsname_list = keys %{ $args{data} };
		$rrd = $self->createRRD( file => $rrdfile_name, dsname_list => \@dsname_list, ds_type => $args{ds_type} );
		$rrd->update( time => $time, values =>  $args{data} );
		
		#print "Warning : unexisting RRD file or set definition changed in conf => nothing will be done until you rebuild the corresponding set ($rrdfile_name).\n";
	} 

}

=head2 graph
	
	Class : Public
	
	Desc : Generate a graph from a rrd, corresponding to one host and one set of data
	
	Args :
		host: the host name
		set_label: the name of the set
		time_laps: the laps in seconds
		ds_def_list: the list of ds definition (ds config: label, color.. ) to draw on the graph
		(optional) graph_type: "stack" or "line" (default : "stack")
	
	Return : The name of generated graph file
	
=cut

sub graph {
	my $self = shift;
	my %args = @_;

	my $host = $args{host};
	
	my $set_name = $args{set_label};
	my $rrd_name = $self->rrdName( set_name => $set_name, host_name => $host );
	my $graph_filename = "graph_$rrd_name.png";

	my $graph_type = $args{graph_type} || "stack";
	#my ($set_def) = grep { $_->{label} eq $set_name} @{ $self->{_monitored_data} };
	#my $ds_list = General::getAsArrayRef( data => $set_def, tag => 'ds');


	# get rrd     
	my $rrd = $self->getRRD( file => "$rrd_name.rrd" );

	my @graph_params = (
						'image' => "$self->{_graph_dir}/$graph_filename",
						#'vertical_label', 'ticks',
						'start' => time() - $args{time_laps},
						color => { back => "#69B033" }
						);

	my $first = 1;
	foreach my $ds (@{ $args{ds_def_list} }) {
		push @graph_params, (
								draw   => {
									#type   => $first == 1 ? "stack" : "stack",
									type => $graph_type,
									dsname => $ds->{label},# . "_P",
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

#TODO gérer le calcul du total de façon paramétrable (pour l'instant c'est la somme de toutes les ds)
#TODO paramétre pour choisir la liste des ds dont on veut afficher le pourcentage
sub graphPercent {
	my $self = shift;
	my %args = @_;
	
	my $host = $args{host};
	
	my $set_name = $args{set_label};
	my $rrd_name = $self->rrdName( set_name => $set_name, host_name => $host );
	my $graph_filename = "graph_percent_$rrd_name.png";

	my $graph_type = $args{graph_type} || "stack";
	#my ($set_def) = grep { $_->{label} eq $set_name} @{ $self->{_monitored_data} };
	#my $ds_list = General::getAsArrayRef( data => $set_def, tag => 'ds');


	# get rrd     
	my $rrd = $self->getRRD( file => "$rrd_name.rrd" );

	my @graph_params = (
						'image' => "$self->{_graph_dir}/$graph_filename",
						#'vertical_label', 'ticks',
						'start' => time() - $args{time_laps},
						color => { back => "#69B033" }
						);


	my $total_op = "";
	my $nb_ds = 0;
	foreach my $ds (@{ $args{ds_def_list} }) {
		push @graph_params, (
								draw   => {
									type => "hidden",
									dsname => $ds->{label},
									name => $ds->{label},
									color => $ds->{color} || "FFFFFF",
									legend => $ds->{label},
	  							}	
							);

		$total_op .= "$ds->{label},";
		$nb_ds++;
	}

	chop $total_op;
	$total_op .= ",+"  while --$nb_ds;
	
	# TEMP
	$total_op = "memTotal";
	
	# Add total graph
	push @graph_params, (
								draw   => {
									type => 'hidden',
									cdef => "$total_op",
									color => "FF0000",
									legend => "TOTAL",
									name => "total"
	  							}	
							);
	
	# Add percent graph
	foreach my $ds (@{ $args{ds_def_list} }) {
				#if ($ds->{label} eq "rawIdleCPU") {
			push @graph_params, (
									draw   => {
										type => $graph_type,
										#cdef => "total,$ds->{label},-,total,/,100,*",
										cdef => "$ds->{label},total,/,100,*",
										color => $ds->{color} || "FFFFFF",
										legend => $ds->{label} . "_perc",
		  							}	
								);
				#}
	}

	# Draw a graph in a PNG image
	$rrd->graph( @graph_params );
	
	return $graph_filename;
}

sub graphCluster {
	
}

=head2 makeGraph
	
	Class : Public
	
	Desc : Generate graph of each defined set of data (conf), for all monitored hosts 
	
	Args :
		time_laps : int : laps in seconds
		(optional) graph_type: "stack" or "line"
		(optional) required_set : string : the name of the set we want graph (else graph all the set)
		(optional) required_indicators : array ref : names of indicators (ds) we want for the required set (else graph all ds of the set)
	
	Return : Hash ref containing filenames of all generated graph { host => { set_label => "file.png" } }
	
=cut

sub makeGraph {
	my $self = shift;
	my %args = @_;
	
	my $time_laps = $args{time_laps} || 3600;
	
	my $required_set = $args{required_set} || "all";
	my $required_ds = $args{required_indicators} || "all";
	
	my %res; #the hash containing filename of all generated graph (host => { set_label => "file.png" })
	
	my @hosts = $self->retrieveHosts();
	foreach my $host (@hosts) {
		foreach my $set_def ( @{ $self->{_monitored_data} } ) {
			if ( $required_set eq "all" || $required_set eq $set_def->{label} )
			{
				#TODO optimisation: là on rebuild le même array pour chaque host, il faudrait le faire une seule fois
				my $ds_def_list = General::getAsArrayRef( data => $set_def, tag => 'ds');
				my @required_ds_def_list;
				foreach my $ds_def ( @$ds_def_list ) {
					push( @required_ds_def_list, $ds_def ) if $required_ds eq "all" || 0 < grep { $ds_def->{label} eq $_ } @$required_ds;
				}
	
				eval {
					my $graph_filename = $self->graph( 	host => $host,
														time_laps => $time_laps,
														set_label => $set_def->{label},
														ds_def_list => \@required_ds_def_list,
														graph_type => $args{graph_type} );
					$res{$host}{$set_def->{label}} = $graph_filename;
				};
				if ($@) {
					my $error = $@;
					#die $error;
					#print "$error\n";
				}
			}
		}
	}
	
	return \%res;
}

=head2 getIndicators
	
	Class : Public
	
	Desc : Build the hash associating set_name with the list of indicators (ds) for each set defined in conf 
	
	Return : Hash ref { set_name => [ "indicator1", ... ] }
	
=cut

sub getIndicators {
	my $self = shift;
	my %args = @_;
	
	my %res;
	foreach my $set_def ( @{ $self->{_monitored_data} } ) {
		my @indicators_name = map { $_->{label} } @{ General::getAsArrayRef( data => $set_def, tag => 'ds') };
		$res{ $set_def->{label} } = \@indicators_name;
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

=head2 getData
	
	Class : Public
	
	Desc : 	Retrieve from storage (rrd) values for required var (ds).
			For each ds can compute mean value on a time laps or percent value, using all values for the ds collected during the time laps.
	
	Args :
		rrd_name: string: the name of the rrd where data are stored.
		time_laps: int: time laps to consider.
		(optionnal) required_ds: array ref: list of ds name to retrieve. If not defined, get all ds.
		(optionnal) percent: if defined compute percent else compute mean for each ds.
	
	Return : A hash ( ds_name => computed_value )
	
=cut

#TODO parametre pour définir les ds a sommer pour obtenir le total
sub getData {
	my $self = shift;
	my %args = @_;
	
	my $rrd_name = $args{rrd_name};

	# rrd constructor     
	my $rrd = $self->getRRD(file => "$rrd_name.rrd" );

	# Start fetching values
	$rrd->fetch_start( start => time() - $args{time_laps} );
	$rrd->fetch_skip_undef();

	my %res_data = ( "_TOTAL_" => [] );
	

	# retrieve array of ds name ordered like in rrd (db column)	
	my $ds_names = $rrd->{fetch_ds_names};
	 
	# Build map (ds_name => rrd_idx)
	my $required_ds = $args{required_ds} || $ds_names;
	my %required_ds_idx = ();
	foreach my $ds_name (@$required_ds) {
		# find the index of required ds
		my $ds_idx = 0;
		++$ds_idx until ( ($ds_idx == scalar @$ds_names) or ($ds_names->[$ds_idx] eq $ds_name) );
		if ($ds_idx == scalar @$ds_names) {
			die "Invalid ds_name for this RRD : '$args{ds_name}'";	
		}
		$required_ds_idx{ $ds_name } = $ds_idx;
		#$res{ $ds_name } = 0;
		$res_data{ $ds_name } = [];
	} 
	

	# Build res data
	while(my($time, @values) = $rrd->fetch_next()) {
		
		if (defined $values[0]) {
			push @{ $res_data{ "_TOTAL_"} }, sum @values;
		}
		while ( my ($ds_name, $ds_idx) = each %required_ds_idx ) {	
			if (defined $values[$ds_idx]) {
				
				#$res{ $ds_name } += $values[$ds_idx];
				
				push @{ $res_data{ $ds_name } }, $values[$ds_idx];
				
			}
		}
	}

	# Build resulting hash
	my %res = ();
	my $total = sum @{ $res_data{"_TOTAL_"} };
	delete $res_data{"_TOTAL_"};
	while ( my ($ds_name, $values) = each %res_data ) {
		my $sum = sum @$values;
		if (defined $args{percent}) {
			$res{ $ds_name } = $sum * 100 / $total;
		}
		else { # mean
			$res{ $ds_name } = $sum / scalar @$values;
		}
	}

	# debug
	use Data::Dumper;
	print Dumper \%res;
	
	
	
	return %res;
}


sub getHostData {
	my $self = shift;
	my %args = @_;
	
	my $rrd_name = $self->rrdName( set_name => $args{set}, host_name => $args{host} );
	
	my %host_data = $self->getData( rrd_name => $rrd_name, time_laps => $args{time_laps}, );
	
	return \%host_data;
}

=head2 aggregate
	
	Class : Public
	
	Desc :	Aggregate a list of hash into one hash by applying desired function (sum, mean).
	
	Args :
		hash_list: array ref: list of hashes to aggregate. [ { p1 => v11, p2 => v12}, { p1 => v21, p2 => v22} ]
		(optionnal) f: "mean", "sum" : aggregation function. If not defined, f() = sum().
		
	Return : The aggregated hash. ( p1 => f(v11,v21), p2 => f(v12,v22) )
	
=cut

sub aggregate {
	my $self = shift;
	my %args = @_;
	
	my %res = ();
	my $nb_keys;
	foreach my $data (@{ $args{hash_list} })
	{
		if ( 0 == scalar keys %res ) {
			%res = %$data;
			$nb_keys = scalar keys %res;
		} else {
			if (  $nb_keys != scalar keys %$data) {
				print "Warning: hash to aggregate have not the same number of keys. => mean computing will be incorrect.\n";
			}
			while ( my ($key, $value) = each %$data ) {
					$res{ $key } += $value;
			}
		}
	}
	
	if ( defined $args{f} && $args{f} eq "mean" ) {
		my $nb_elem = scalar @{ $args{hash_list} };
		for my $key (keys %res) {
			$res{$key} /= $nb_elem;
		}
	}
	
	return %res;
}

#TODO required_ds
#TODO percentage
sub getClustersData {
	my $self = shift;
	my %args = @_;
	
	my $aggregate = $args{aggregate};
	
	my %clusters_data = ();
	my %hosts_by_cluster = $self->retrieveHostsByCluster();
	while ( my ($cluster, $hosts) = each %hosts_by_cluster ) {
		my %hosts_data = ();
		foreach my $host (@$hosts) {
			my $host_data = $self->getHostData( host => $host, set => $args{set}, time_laps => $args{time_laps} );
			$hosts_data{ $host } = $host_data;
		}
		if ( defined $aggregate ) {
			my @data_list = values %hosts_data;
			my %aggregate_data = $self->aggregate( hash_list => \@data_list, f => $aggregate );
			$clusters_data{ $cluster } = \%aggregate_data;
		} else {
			$clusters_data{ $cluster } = \%hosts_data;
		}
	}
	
	return \%clusters_data;
}

#TODO comm
sub computeData {
	my $self = shift;
	my %args = @_;
	
	my $data = $args{data};
	my $total = sum values %$data;

	my %percents = ();
	while ( my ($name, $value) = each %$data ) {
		$percents{ $name . "_P" } = $value * 100 / $total;
	}
	
	return \%percents;
}

#TODO gérer les hosts starting, stopping, broken, up, down
sub manageUnreachableHost {
	my $self = shift;
	my %args = @_;
	
	my $STARTING_MAX_TIME = 300;
	my $STOPPING_MAX_TIME = 300;
	
	my $adm = $self->{_admin};
	
	my $host = $args{host};
	$host = "127.0.0.1"; ############ TEMP #######""
	
	eval {
		my @mb_res = $adm->getEntities( type => "Motherboard", hash => { motherboard_internal_ip => $host } );
			
		my $mb = shift @mb_res;
		my $mb_state = $mb->getAttr( name => "motherboard_state" );
		my $state = "something";
		my $state_time = 666;
		
		if ( 	$state eq "up"
			|| 	( $state eq "starting" && $state_time > $STARTING_MAX_TIME )
			||	( $state eq "stopping" && $state_time > $STOPPING_MAX_TIME ) )
		{
			$mb->setAttr( name => "motherboard_state", value => "broken" );
			$mb->save();
		} elsif ( $state eq "stopping" ) {
			# we check if host is really stopped (unpingable)
			my $p = Net::Ping->new();
			my $reachable = $p->ping($host);
			$p->close();
			if ( not $reachable ) {
				$mb->setAttr( name => "motherboard_state", value => "down" );
				$mb->save();
			}
		}
	};
	if (@_) {
		my $error = $@;
		print "===> $error";
	}
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
	#my $session = $self->createSNMPSession( host => $host );
	
	#my $provider_class = "SnmpProvider";
	#require "$provider_class.pm";
	#my $data_provider = SnmpProvider->new( host => $host );
	#my $data_provider = $provider_class->new( host => $host );
	
	print "\n###############   ", $host, "   ##########\n";
	
	eval {
		#For each set of snmp var defined in conf file
		foreach my $set ( @{ $self->{_monitored_data} } ) {

			# Build the required var map: ( var_name => oid )
			my %var_map = map { $_->{label} => $_->{oid} } @{ General::getAsArrayRef( data => $set, tag => 'ds') };
			
			# Get the specific DataProvider
			# TODO vérifier que c'est pas trop moche (possibilité plusieurs fois le même require,...)
			my $provider_class = $set->{'data_provider'} || "SnmpProvider";
			require "DataProvider/$provider_class.pm";
			my $data_provider = $provider_class->new( host => $host );
			
			# Retrieve the map ref { var_name => snmp_value } corresponding to required var_map
			#my ($time, $update_values) = $self->retrieveData( session => $session, var_map => \%var_map );
			#my ($time, $update_values) = $self->gaussData( var_map => \%var_map );
			my ($time, $update_values) = $data_provider->retrieveData( var_map => \%var_map );
			
			# DEBUG print values
			print "$time : ", join( " | ", map { "$_: $update_values->{$_}" } keys %$update_values ), "\n";
	
			# Store new values in the corresponding RRD
			my $rrd_name = $self->rrdName( set_name => $set->{label}, host_name => $host );
			$self->updateRRD( rrd_name => $rrd_name, ds_type => $set->{ds_type}, time => $time, data => $update_values );
		}
	};
	if ($@) {
		my $error = $@;
		print "===> $error";
		
		if ( "$error" =~ "No response" ) {
			#$self->manageUnreachableHost( host => $host );
		}
	}
	
	#$self->closeSNMPSession(session => $session);
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
		$self->{_t} += 0.1;
		sleep( $self->{_time_step} );
	}
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut