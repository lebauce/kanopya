package Monitor::Retriever;

use strict;
use warnings;
use List::Util qw(sum);

use Data::Dumper;

use base "Monitor";

# Constructor

sub new {
    my $class = shift;
    my %args = @_;
	
	my $self = $class->SUPER::new( %args );
    return $self;
}


sub getSetDef {
	my $self = shift;
	my %args = @_;
	
	my $set_label = $args{set_label};
	my @res = grep { $_->{label} eq $set_label } @{ $self->{_monitored_data} };
	
	if ( 0 == @res ) {
		print "Undefined set label : $set_label\n";
	}	
		
	return shift @res;
		
}

=head2 getData
	
	Class : Public
	
	Desc : 	Retrieve from storage (rrd) values for required var (ds).
			For each ds can compute mean value on a time laps or percent value, using all values for the ds collected during the time laps.
	
	Args :
		rrd_name: string: the name of the rrd where data are stored.
		time_laps: int: time laps to consider.
		(optionnal) required_ds: array ref: list of ds name to retrieve. If not defined, get all ds. WARNING: don't use it if 'percent'.
		(optionnal) percent: if defined compute percent else compute mean for each ds. See 'max_def'.
		(optionnal) max_def: array: list of ds name to add to obtain max value (used to compute percent). If not defined, use all ds.
	
	Return : A hash ( ds_name => computed_value )
	
=cut

#TODO gérer le cas où les ds dans max_def ne sont pas toutes dans les required_ds
sub getData {
	my $self = shift;
	my %args = @_;
	
	Monitor::logArgs( "getData", %args );
	
	my $rrd_name = $args{rrd_name};

	# rrd constructor     
	my $rrd = $self->getRRD(file => "$rrd_name.rrd" );

	# Start fetching values
	$rrd->fetch_start( start => time() - $args{time_laps} );
	$rrd->fetch_skip_undef();

	# retrieve array of ds name ordered like in rrd (db column)	
	my $ds_names = $rrd->{fetch_ds_names};
	
	my @max_def = $args{max_def} ? @{ $args{max_def} } : @$ds_names; 
	my %res_data = ( "_MAX_" => [] );

	############################################# 
	# Build ds index map : (ds_name => rrd_idx) #
	#############################################
	
	my $required_ds = $args{required_ds} || $ds_names;
	my %required_ds_idx = ();
	my @max_idx = ();
	foreach my $ds_name (@$required_ds) {
		# find the index of required ds
		my $ds_idx = 0;
		++$ds_idx until ( ($ds_idx == scalar @$ds_names) or ($ds_names->[$ds_idx] eq $ds_name) );
		if ($ds_idx == scalar @$ds_names) {
			die "Invalid ds_name for this RRD : '$args{ds_name}'";	
		}
		$required_ds_idx{ $ds_name } = $ds_idx;
		$res_data{ $ds_name } = [];
		
		if ( 0 < grep { $_ eq $ds_name } @max_def ) {
			push @max_idx, $ds_idx;
		}
	} 
	
	# Check error in max definition
	if ( scalar @max_idx != scalar @max_def) {
		print "Warning: bad ds name in max definition: [ ", join(", ", @max_def), " ]\n"; 
	}

	################################################
	# Build res data : ( ds_name => [v1, v2, ..] ) #
	################################################
	
	while(my($time, @values) = $rrd->fetch_next()) {
		# compute max value for this row
		if (defined $values[0]) {
			my $max = 0;
			foreach my $idx (@max_idx) { $max += $values[$idx] };			
			push @{ $res_data{ "_MAX_"} }, $max;

			#push @{ $res_data{ "_MAX_"} }, sum @values;
		}
		# add values in res_data
		while ( my ($ds_name, $ds_idx) = each %required_ds_idx ) {
			if (defined $values[$ds_idx]) {
				
				#$res{ $ds_name } += $values[$ds_idx];
				
				push @{ $res_data{ $ds_name } }, $values[$ds_idx];
				
			}
		}
	}

	#print Dumper \%res_data;

	######################################################
	# Build resulting hash : ( ds_name => f(v1,v2,...) ) #
	######################################################
	
	my %res = ();
	my $max = sum @{ $res_data{"_MAX_"} };
	delete $res_data{"_MAX_"};
	while ( my ($ds_name, $values) = each %res_data ) {
		my $sum = sum( @$values ) || 0;
		eval {
			if (defined $args{percent}) {
				$res{ $ds_name } = $sum * 100 / $max;
			}
			else { # mean
				$res{ $ds_name } = $sum / scalar @$values;
			}
		};
		if ($@) {
			$res{ $ds_name } = undef;
		}
	}

	# debug
	#print Dumper \%res;
	
	Monitor::logRet( %res );
	
	return %res;
}


sub getHostData {
	my $self = shift;
	my %args = @_;
	
	Monitor::logArgs( "getHostData", %args );
	
	my $rrd_name = $self->rrdName( set_name => $args{set}, host_name => $args{host} );
	
	my $set_def = $self->getSetDef(set_label => $args{set});
	my @max_def;
	if ( $set_def->{max} ) { @max_def = split( /\+/, $set_def->{max} ) };
	if (defined $args{percent} && 0 == scalar @max_def ) {
		print "Warning: No max definition to compute percent for '$args{set}'.\n";
	}
	
	my %host_data = $self->getData( rrd_name => $rrd_name,
									time_laps => $args{time_laps},
									max_def => (scalar @max_def) ? \@max_def : undef,
									percent => $args{percent} );
	
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
	
	Monitor::logArgs( "aggregate", %args );
	
	my %res = ();
	my $nb_keys;
	my $nb_elems = 0;
	foreach my $data (@{ $args{hash_list} })
	{
		if ( ref $data eq "HASH"  ) {
			$nb_elems++;
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
	}
	
	if ( defined $args{f} && $args{f} eq "mean" && $nb_elems > 0) {
		for my $key (keys %res) {
			$res{$key} /= $nb_elems;
		}
	}
	
	return %res;
}

sub getClusterData {
	my $self = shift;
	my %args = @_;
	
	my $aggregate = $args{aggregate};
	
	my $res;
	my %hosts_data = ();
	my $hosts = $self->getClusterHostsInfo( cluster => $args{cluster} );
	
	#foreach my $host (@$hosts) {
	while ( my ($hostname, $host_info) = each %$hosts ) {
		if ( $host_info->{state} eq "up" ) {
			my $host_data = $self->getHostData( host => $host_info->{ip}, set => $args{set}, time_laps => $args{time_laps}, percent => $args{percent} );
			$hosts_data{ $hostname } = $host_data;
		}
		else {
			$hosts_data{ $hostname } = $host_info->{state};
		}
	}
	if ( defined $aggregate ) {
		my @data_list = values %hosts_data;
		my %aggregate_data = $self->aggregate( hash_list => \@data_list, f => $aggregate );
		$res = \%aggregate_data;
	} else {
		$res = \%hosts_data;
	}
	
	return $res;
}

sub getClustersData {
	my $self = shift;
	my %args = @_;
	
	#$log->debug("##########################################################");
	Monitor::logArgs( "getClusterData", %args );
	
	my %clusters_data = ();
	my @clusters = $self->getClustersName();
	for my $cluster (@clusters) {
		$clusters_data{ $cluster } = $self->getClusterData( cluster => $cluster,
													 set => $args{set},
													 time_laps => $args{time_laps},
													 percent => $args{percent},
													 aggregate => $args{aggregate});
	}
	return \%clusters_data;
}

#TODO required_ds
sub getClustersData_OLD {
	my $self = shift;
	my %args = @_;
	
	#$log->debug("##########################################################");
	Monitor::logArgs( "getClusterData", %args );
	
	my $aggregate = $args{aggregate};
	
	my %clusters_data = ();
	my %hosts_by_cluster = $self->retrieveHostsByCluster();
	while ( my ($cluster, $hosts) = each %hosts_by_cluster ) {
		my %hosts_data = ();
		#foreach my $host (@$hosts) {
		while ( my ($hostname, $host_info) = each %$hosts ) {
			if ( $host_info->{state} eq "up" ) {
				my $host_data = $self->getHostData( host => $host_info->{ip}, set => $args{set}, time_laps => $args{time_laps}, percent => $args{percent} );
				$hosts_data{ $hostname } = $host_data;
			}
			else {
				$hosts_data{ $hostname } = $host_info->{state};
			}
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
	
	my @hosts = $self->retrieveHostsIp();
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

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut