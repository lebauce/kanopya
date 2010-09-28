package Monitor::Retriever;

use strict;
use warnings;
use List::Util qw(sum);
use XML::Simple;
#use General;

use Data::Dumper;

use base "Monitor";

# logger
use Log::Log4perl "get_logger";
#Log::Log4perl->init('/workspace/mcs/Monitor/Conf/log.conf');
my $log = get_logger("retriever");


# Constructor

sub new {
    my $class = shift;
    my %args = @_;
	
	my $self = $class->SUPER::new( %args );
	
	#$self->{_graph_color} = { back => "#69B033" };
	$self->{_graph_color} = { 	back => "#111111",
								font => "#DDDDDD",
								canvas => "#222222",	# graph background
								frame => "#666666",		# line around color spot
								#mgrid => "#AAAAAA",
							};
	
	#$self->{_admin_wrap} = AdminWrapper->new( );
	
    return $self;
}


sub getSetDef {
	my $self = shift;
	my %args = @_;
	
	my $set_label = $args{set_label};
	my @res = grep { $_->{label} eq $set_label } @{ $self->{_monitored_data} };
	
	die "Undefined set label : '$set_label'\n" if ( 0 == @res );
		
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

	print "\n###############   ", "getData res data   # $args{rrd_name} #", "   ##########\n";
	print Dumper \%res_data;

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
	print "\n###############   ", "getData res", "   ##########\n";
	print Dumper \%res;
	
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


#TODO now we store cluster data, so retrieve this data from rrd
sub getClusterData {
	my $self = shift;
	my %args = @_;
	
	my $aggregate = $args{aggregate};
	
	my $res;
	my %hosts_data = ();
	my $hosts = $self->getClusterHostsInfo( cluster => $args{cluster} );
	
	print "\n###############   Get Cluster Data   #############\n";
	my $up;
	#foreach my $host (@$hosts) { 
	while ( my ($hostname, $host_info) = each %$hosts ) {
		if ( $host_info->{state} =~ "up" ) {
			my $host_data = $self->getHostData( host => $host_info->{ip}, set => $args{set}, time_laps => $args{time_laps}, percent => $args{percent} );
			$hosts_data{ $hostname } = $host_data;
			$up = 1;
		}
		else {
			$hosts_data{ $hostname } = $host_info->{state};
		}
	}
	
	print Dumper \%hosts_data;
	
	die "No node 'up' in cluster '$args{cluster}'" if ( not defined $up );
	
	if ( defined $aggregate ) {
		my @data_list = values %hosts_data;
		my %aggregate_data = $self->aggregate( hash_list => \@data_list, f => $aggregate );
		$res = \%aggregate_data;
	} else {
		$res = \%hosts_data;
	}
	
	print "\n###############   ", "res", "   ##########\n";
	print Dumper $res;
	
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

=head2 graphNode
	
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

#TODO now this sub is also used to graph cluster => change sub name and sub args
sub graphNode {
	my $self = shift;
	my %args = @_;

	my $time_laps = $args{time_laps};
	my $suffix;
	print " ===> 1 time laps : $time_laps\n";
	if ( $time_laps =~ /\D/ ) { # not a number
		 $suffix = "$time_laps";
		 my %laps = ( 'hour' => 3600, 'day' => 3600*24 );
		 $time_laps = $laps{$time_laps} || 0;
	}
	print " ===> 2 time laps : $time_laps\n";

	my $host = $args{host};
	
	my $set_name = $args{set_label};
	my $rrd_name = $self->rrdName( set_name => $set_name, host_name => $host );
	#my $graph_filename = "graph_$rrd_name.png";
	my $graph_name = "graph_$host" . "_$set_name" . ( defined $suffix ? "_$suffix" : "");
	my $graph_filename = "$graph_name.png";
	
	my $graph_title = "$set_name for $host";

	my $graph_type = $args{graph_type} || "line";
	#my ($set_def) = grep { $_->{label} eq $set_name} @{ $self->{_monitored_data} };
	#my $ds_list = General::getAsArrayRef( data => $set_def, tag => 'ds');


	# get rrd     
	my $rrd = $self->getRRD( file => "$rrd_name.rrd" );

	my @graph_params = (
						'image' => "$self->{_graph_dir}/$graph_filename",
						#'vertical_label', 'ticks',
						'start' => time() - $time_laps,
						color => $self->{_graph_color},
						
						title => $graph_title,
						
						lower_limit => 0,
						
						#slope_mode => undef,	# smooth
					
						);
						
	if (defined $args{thumbnail} ) {
		push @graph_params, (	
								height => 64, width => 64,
								only_graph => undef,
							);
	}

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
	
	# backup graph
#	if ($host eq "WebBench" && $set_name eq "cpu") {
#		my $backup_dir = $self->{_graph_dir} . "/" . "backup_$host" . "_$set_name"; 
#		mkdir $backup_dir;
#		my @file_count = <$backup_dir/*.png>;
#		my $backup_filename = sprintf( "%s_%.6d.png", $graph_name, scalar @file_count);
#		`cp "$self->{_graph_dir}/$graph_filename" "$backup_dir/$backup_filename"`;
#	}
	
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
	#my $graph_filename = "graph_percent_$rrd_name.png";	
	my $graph_name = "graph_$host" . "_$set_name" . "_percent";
	my $graph_filename = "$graph_name.png";


	my $graph_type = $args{graph_type} || "line";
	#my ($set_def) = grep { $_->{label} eq $set_name} @{ $self->{_monitored_data} };
	#my $ds_list = General::getAsArrayRef( data => $set_def, tag => 'ds');


	# Retrieve max definition
	my $set_def = $self->getSetDef(set_label => $set_name);
	my @max_def;
	if ( $set_def->{max} ) { @max_def = split( /\+/, $set_def->{max} ) };
	if ( 0 == scalar @max_def ) {
		print "Warning: No max definition to compute percent for '$set_name'.\n";
	}
	
	my @required_ds_def = @{ $args{ds_def_list} };
	my @needed_ds = map { $_->{label} } @required_ds_def;
	foreach my $ds_name (@max_def) {
		if ( 0 == grep { $_ eq $ds_name } @needed_ds ) {
			push @needed_ds, $ds_name;
		}
	}

	# get rrd     
	my $rrd = $self->getRRD( file => "$rrd_name.rrd" );

	my @graph_params = (
						'image' => "$self->{_graph_dir}/$graph_filename",
						#'vertical_label', 'ticks',
						'start' => time() - $args{time_laps},
						color => $self->{_graph_color},
						lower_limit => 0,
						);


	#my $total_op = "";
	#my $nb_ds = 0;
	foreach my $ds_name ( @needed_ds ) {
		push @graph_params, (
								draw   => {
									type => "hidden",
									dsname => $ds_name,
									name => $ds_name,
									#color => $ds->{color} || "FFFFFF",
									#legend => $ds->{label},
	  							}	
							);

		#$total_op .= "$ds->{label},";
		#$nb_ds++;
	}

	#chop $total_op;
	#$total_op .= ",+"  while --$nb_ds;
	
	# TEMP
	#$total_op = "memTotal";
	
	my $total_op = join( ",", @max_def);
	for (my $i=1; $i < @max_def; ++$i) { $total_op .= ",+" };
	
	print "#### TOTAL op : $total_op\n";
	
	
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

=head2 graphCluster
	
	Class : Public
	
	Desc : generate the graph of mean value for one indicator and for one cluster
	
	Args :
		cluster: name of the cluster
		set_name: name of the set of var
		ds_name: name of the indicator in set_name to draw the mean
	
	Return :
		[0] : graph dir
		[1] : generate graph file name
	
=cut

#TODO enable multi indicators graph
sub OLD_graphCluster {
	my $self = shift;
	my %args = @_;
	
	my $cluster = $args{cluster};
	my $set_name = $args{set_name};
	my $ds_label = $args{ds_name};
	
	my $graph_filename = "graph_" . "$cluster" . "_$ds_label.png";

	my $graph_type = $args{graph_type} || "line";
	
	my @graph_params = (
						'image' => "$self->{_graph_dir}/$graph_filename",
						#'vertical_label', 'ticks',
						'start' => time() - $args{time_laps},
						#color => { back => "#69B033" },
						color => $self->{_graph_color},
						lower_limit => 0,
						);
	
	
	
	
	my $total_op = "";
	my $nb_hosts = 0;
	my $rrd_file;
	my $cluster_info = $self->getClusterHostsInfo( cluster => $cluster);
	foreach my $host_info ( values %$cluster_info ) {
		my $rrd_name = $self->rrdName( set_name => $set_name, host_name => $host_info->{ip} );
		$rrd_file = "$rrd_name.rrd";
		my $var_name = "host$nb_hosts" . "_$ds_label";
		push @graph_params, (
								draw   => {
									type => "hidden",
									file => $self->{_rrd_base_dir} . "/" . $rrd_file, 
									dsname => $ds_label,
									name => $var_name,
									#color => $ds->{color} || "FFFFFF",
									#legend => $ds->{label},
	  							}	
							);

		$total_op .= "$var_name,";
		$nb_hosts++;
	} 
	
	chop $total_op;
	my $i = $nb_hosts;
	$total_op .= ",+"  while --$i;
	
	my $mean_op = $total_op . ",$nb_hosts,/";
	
	#print "Mean op : $mean_op\n";
	
	# Add mean graph
	push @graph_params, (
								draw   => {
									type => $graph_type,
									cdef => "$mean_op",
									color => "FF0000",
									legend => "$ds_label (cluster mean)",
									name => "mean"
	  							}	
							);		

	# get rrd (we need one to graph so we get the last host rrd (arbitrary))
	my $rrd = $self->getRRD( file => $rrd_file );
	
	# Draw a graph in a PNG image
	$rrd->graph( @graph_params );
	
	return ($self->{_graph_dir}, $graph_filename);
}

sub graphCluster {
	my $self = shift;
	my %args = @_;

	my $cluster = $args{cluster};

	my $time_laps = $args{time_laps} || 3600;
	
	my $required_set = $args{required_set} || "all";
	my $required_ds = $args{required_indicators} || "all";
	
	my %res = ();
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
					my $graph_sub = defined $args{percent} && $args{percent} ne "no" ? \&graphPercent : \&graphNode;
					my $graph_filename = $graph_sub->( 	$self,
													host => $cluster,
													time_laps => $time_laps,
													set_label => $set_def->{label},
													ds_def_list => \@required_ds_def_list,
													graph_type => $args{graph_type} );
				$res{$set_def->{label}} = $graph_filename;
			};
			if ($@) {
				my $error = $@;
				#die $error;
				print "$error\n";
			}
		}
	}
	
	return \%res;
}

=head2 graphNodes
	
	Class : Public
	
	Desc : Generate graph of each defined set of data (conf), for all monitored hosts 
	
	Args :
		time_laps : int : laps in seconds
		(optional) graph_type: "stack" or "line"
		(optional) required_set : string : the name of the set we want graph (else graph all the set)
		(optional) required_indicators : array ref : names of indicators (ds) we want for the required set (else graph all ds of the set)
	
	Return : Hash ref containing filenames of all generated graph { host => { set_label => "file.png" } }
	
=cut

#TODO choix des hosts
sub graphNodes {
	my $self = shift;
	my %args = @_;
	
	my $time_laps = $args{time_laps} || 3600;
	
	my $required_set = $args{required_set} || "all";
	my $required_ds = $args{required_indicators} || "all";
	
	my %res; #the hash containing filename of all generated graph (host => { set_label => "file.png" })
	
	my @hosts = $self->retrieveHostsIp();
	foreach my $host (@hosts) {
		#print "#### $host\n";
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
					my $graph_sub = defined $args{percent} && $args{percent} ne "no" ? \&graphPercent : \&graphNode;
					my $graph_filename = $graph_sub->( 	$self,
														host => $host,
														time_laps => $time_laps,
														set_label => $set_def->{label},
														ds_def_list => \@required_ds_def_list,
														graph_type => $args{graph_type} );
					$res{$host}{$set_def->{label}} = $graph_filename;
				};
				if ($@) {
					my $error = $@;
					#die $error;
					print "$error\n";
				}
			}
		}
	}
	
	return \%res;
}

# TODO c'est pas optimisé et ça commence à être le bordel
# TODO listes de graph retournée est mauvaise et mal formé
sub graphFromConf {
	my $self = shift;
	my %args = @_;
	
	my $start_time = time();
	
	my @clusters_name = $self->getClustersName();
	
	my $config = XMLin("/workspace/mcs/Monitor/Conf/monitor.conf");
	my $all_conf = General::getAsArrayRef( data => $config, tag => 'conf' );
	my @conf = grep { $_->{label} eq $config->{use_conf} } @$all_conf;
	my $conf = shift @conf;
	my $graphs = General::getAsArrayRef( data => $conf->{generate_graph}, tag => 'graph' );
	
	my %graph_files = ();
	my $i = 0;
	foreach my $graph_def ( @$graphs ) {
		my %graph_info = ();
		++$i;
		print Dumper $graph_def;
		eval {
			my @targets = split ",", $graph_def->{targets};
			my @time_laps = split ",", $graph_def->{time_laps};
			foreach my $laps (@time_laps) {
				foreach my $target (@targets) {
					if ( $target eq 'CLUSTERS' ) {
						#TODO sub graphClusters
						foreach my $cluster (@clusters_name) {
							my ($dir, $file);
							if ( defined $graph_def->{type} && $graph_def->{type} eq 'nodecount' ) {
								($dir, $file) = $self->graphNodeCount( 	time_laps => $laps,
																		cluster => $cluster );	
							} else {
								my @required_indicators = split ",", $graph_def->{ds_label};
								my $required = $graph_def->{ds_label} eq 'ALL' ? 'all' : \@required_indicators;
								($dir, $file) = $self->graphCluster( time_laps => $laps,
																		cluster => $cluster,
																		required_set => $graph_def->{set_label},
																		required_indicators => $required,
																		percent => $graph_def->{percent},
																		graph_type => $graph_def->{graph_type} || 'line');
							}
							$graph_info{$cluster} = [ $dir, $file ];
							
						}
					} elsif ( $target eq 'NODES' ) {
						my @required_indicators = split ",", $graph_def->{ds_label};
						my $required = $graph_def->{ds_label} eq 'ALL' ? 'all' : \@required_indicators;
						my $res = $self->graphNodes( time_laps => $laps,
													required_set => $graph_def->{set_label},
													required_indicators => $required,
													percent => $graph_def->{percent},
													graph_type => $graph_def->{graph_type} || 'line' );
						%graph_info = %$res;
					}
				} # end foreach target
			} # end foreach time_laps
		};
		if ($@) {
			my $error = $@;
			#die $error;
			print "Error generating graph : $error\n";
			next;
		}
		$graph_files{ "graph_$i" } = \%graph_info;
	} 
	
	print "# graph from conf time => ", time() - $start_time, "\n";
	
	return %graph_files;
	
}

=head2 graphNodeCount
	
	Class : Public
	
	Desc :	For a cluster, generate the graph counting all nodes depending on state (up, starting, stopping, broken).
			
	
	Args :
		cluster: the cluster name for wich we want graph nodes count
		(optionnal) time_laps: seconds
	
	Return : The path of the generated graph
	
=cut

sub graphNodeCount {
	my $self = shift;
	my %args = @_;
	
	my $alpha = "66";
	
	my $cluster = $args{cluster};
    my $time_laps = $args{time_laps} || 3600;
    
    my $graph_file = "graph_$cluster" . "_nodecount.png";
	my $graph_file_path = "$self->{_graph_dir}/$graph_file";
	
	# get rrd     
	my $rrd = RRDTool::OO->new( file => "$self->{_rrd_base_dir}/nodes_$cluster.rrd" );
	
	$rrd->graph( 	'image' => $graph_file_path,
					'vertical_label' => 'number of nodes',
					'start' => time() - $time_laps,
					#color => { back => "#69B033" },
					
					color => $self->{_graph_color},
					
					lower_limit => 0,
					upper_limit => 10,
					
					'y_grid' => '1:1',
					
					draw => 	{
									type => 'stack',
									dsname => 'up',
									color => "00FF00".$alpha,
									legend => "up",
		  						},
					draw => 	{
									type => 'stack',
									dsname => 'starting',
									color => "0000FF".$alpha,
									legend => "starting",
		  						},
					draw => 	{
									type => 'stack',
									dsname => 'stopping',
									color => "FFFF00".$alpha,
									legend => "stopping",
		  						},
		  			draw => 	{
									type => 'stack',
									dsname => 'broken',
									color => "FF0000".$alpha,
									legend => "broken",
		  						},
					);
					
	return ($self->{_graph_dir}, $graph_file);
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