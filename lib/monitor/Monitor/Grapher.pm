package Monitor::Grapher;

use strict;
use warnings;
use List::Util qw(sum);
use XML::Simple;
#use General;

use Data::Dumper;

use base "Monitor";

# logger
use Log::Log4perl "get_logger";
my $log = get_logger("grapher");


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
	
	$self->{_graph_title_font} = { name => "Times", element => "title", size => 15 };
	
	$self->{_graph_width} = 600;
	$self->{_graph_height} = 100;
	
    return $self;
}



sub _timeLaps {
	my $self = shift;
	my %args = @_;
	
	my $time_laps = $args{time_laps};
	my ($time_start, $time_end, $time_suffix);
	if ( $time_laps =~ /\D/ ) { # not a number
		 $time_suffix = "$time_laps";
		 my %laps = ( 'hour' => 3600, 'day' => 3600*24 );
		 $time_laps = $laps{$time_laps} || 0;
		 $time_end = time();
	} elsif ( defined $args{time_range} ) {
		my @range = split ",", $args{time_range};
		# TODO check validity of range 
		
		use DateTime::Format::Strptime;
		
		#my $time_zone = 'Europe/Paris';
		my $time_zone = 'local';
			
  		my $analyseur = DateTime::Format::Strptime->new( pattern => '%Y-%m-%d %H:%M' );
  		my $dt_start = $analyseur->parse_datetime( $range[0] )->set_time_zone( $time_zone );
  		
  		if ( $range[1] =~ 'now' ) {
  			$time_end = time();
  		} else {
  			my $dt_end = $analyseur->parse_datetime( $range[1] )->set_time_zone( $time_zone );
  			$time_end = $dt_end->epoch();
  		}
		
		$time_laps = $time_end - $dt_start->epoch();
		
	} else {
		$time_end = time();
	}
	
	$time_start = $time_end - $time_laps; 
	
	return ($time_start, $time_end,  $time_suffix);
}

sub graphTable {
	my $self = shift;
	my %args = @_;

	my $host = $args{host};
	my $set_name = $args{set_label};
	my $options = $args{options} || {};
	
	# Retrieve list of rrd files corresponding of each raw for the table
	my %rrds = ();
	my $rrd_files = `ls $self->{_rrd_base_dir} | grep $set_name`;
	foreach my $file_name ( split '\n', $rrd_files ) {
		if ( $file_name =~ /$set_name\.(.*)_$host.*/) {
			$rrds{$1} = $file_name;
		}
	}

	#################################
	# Case 1: one graph for one raw #
	#################################
	if ( (not defined $options->{all_in_one}) || ($options->{all_in_one} ne 'yes') ) {
		while ( my ($index, $rrd_file) = each %rrds ) {
			my $graph_filename = $self->graphNode(
									host => $args{host},
									time_laps => $args{time_laps},
									time_range => $args{time_range},
									set_label => "$args{set_label}.$index",
									ds_def_list => $args{ds_def_list},
									graph_type => $args{graph_type},
									type => $args{type},
									aggreg_ext => $args{aggreg_ext},
									with_total => $args{with_total});
		}
		return;
	}

	###################################
	# Case 2: one graph with all raws #
	###################################
		
	my ($time_start, $time_end, $time_suffix) = $self->_timeLaps( time_laps => $args{time_laps}, time_range => $args{time_range} );
	
	my $graph_name = "graph_$host" . "_$set_name";
	$graph_name .= "_$args{aggreg_ext}" if (defined $args{aggreg_ext});
	$graph_name .= ( defined $time_suffix ? "_$time_suffix" : "");
	my $graph_filename = "$graph_name.png";
	
#	my $graph_title = (defined $args{type} && $args{type} eq 'cluster') ?
#					"$set_name for cluster $host " . ( defined $cluster_total ? "(total)" : "(average)" )
#					: "$set_name for $host";
	my $graph_title = "$set_name for $host";


	my $graph_type = $args{graph_type} || "line";
		
	my @graph_params = (
					'image' => "$self->{_graph_dir}/tmp/$graph_filename",
					#'vertical_label', 'ticks',
					'start' => $time_start,
					'end' => $time_end,
					color => $self->{_graph_color},				
					font => $self->{_graph_title_font},
					title => $graph_title,
					width => $self->{_graph_width},
					height => $self->{_graph_height},
					lower_limit => 0,
					slope_mode => undef,	# smooth
				
					);
	
	my $file;				
	while ( my ($index, $rrd_file) = each %rrds ) {
		$file = $rrd_file;
		foreach my $ds (@{ $args{ds_def_list} }) {		
			push @graph_params, (
									'draw', {
										file => "$self->{_rrd_base_dir}/$rrd_file",
										type => $graph_type,
										dsname => $ds->{label},# . "_P",
										color => $ds->{color} || "FFFFFF",
										legend => $ds->{label} . " ($index)",
		  							},
								);
		}
	}
	
	if ( defined $file) {
		my $rrd = $self->getRRD( file => "$file" );
		
		# Draw a graph in a PNG image
		$rrd->graph( @graph_params );
		
		# mv graph file from tmp dir to graph_dir
		`mv $self->{_graph_dir}/tmp/$graph_filename $self->{_graph_dir}`;
		
		$log->info("table => $graph_filename");
	} else {
		$log->info("info: nothing to graph in the table '$set_name'");
	}
	
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
#TODO name of rrd and name of resulting graph file must be parameters!
sub graphNode {
	my $self = shift;
	my %args = @_;

	my ($time_start, $time_end, $time_suffix) = $self->_timeLaps( time_laps => $args{time_laps}, time_range => $args{time_range} );

	my $host = $args{host};
	
	my $set_name = $args{set_label};
	my $base_rrd_name = $self->rrdName( set_name => $set_name, host_name => $host );
	
	my $rrd_name = $base_rrd_name;
	$rrd_name .= "_$args{aggreg_ext}" if (defined $args{aggreg_ext});	

	my $cluster_total = (defined $args{aggreg_ext} && $args{aggreg_ext} eq 'total') ? 1 : undef;

	my $graph_name = "graph_$host" . "_$set_name";
	$graph_name .= "_$args{aggreg_ext}" if (defined $args{aggreg_ext});
	$graph_name .= ( defined $time_suffix ? "_$time_suffix" : "");
	
	my $graph_filename = "$graph_name.png";
	
	my $graph_title = (defined $args{type} && $args{type} eq 'cluster') ?
						"$set_name for cluster $host " . ( defined $cluster_total ? "(total)" : "(average)" )
						: "$set_name for $host";

	my $graph_type = $args{graph_type} || "line";

	# get rrd     
	my $rrd = $self->getRRD( file => "$rrd_name.rrd" );

	my @graph_params = (
						'image' => "$self->{_graph_dir}/tmp/$graph_filename",
						#'vertical_label', 'ticks',
						'start' => $time_start,
						'end' => $time_end,
						color => $self->{_graph_color},				
						font => $self->{_graph_title_font},
						title => $graph_title,
						width => $self->{_graph_width},
						height => $self->{_graph_height},
						lower_limit => 0,
						slope_mode => undef,	# smooth
					
						);
						
	if (exists $args{thumbnail} ) {
		push @graph_params, (	
								height => 64, width => 64,
								only_graph => undef,
							);
	}

	foreach my $ds (@{ $args{ds_def_list} }) {
		
		# 
		if ( defined $args{with_total} && $args{with_total} eq 'yes' ) {
			push @graph_params, (
									'draw', {
										file => "$self->{_rrd_base_dir}/$base_rrd_name" . "_total" . ".rrd",
										type => $graph_type,
										dsname => $ds->{label},
										#color => $ds->{color} || "FFFFFF",
										color => "FF000077",
										legend => $ds->{label} . " (total)",
		  							},
								);
		}
								
		push @graph_params, (
								'draw', {
									#type   => $first == 1 ? "stack" : "stack",
									name => $ds->{label},
									type => $graph_type,
									dsname => $ds->{label},
									color => (defined $cluster_total) ? "FF0000" : $ds->{color} || "FFFFFF",
									#color => $ds->{color} || "FFFFFF",
									legend => $ds->{label} . ((defined $args{type} && $args{type} eq 'cluster') ? (defined $cluster_total ? " (total)" : " (node average)") : ""),
								},
	  							
	  							
	  							# TODO why this don't work (current value is not the same depending on time laps (?!))
#	  							'draw', {
#							        type      => "hidden",
#							        name      => "last_$ds->{label}",
#							        vdef      => "$ds->{label},LAST"
#							     },
#							
#							   	'gprint', {
#							        draw      => "last_$ds->{label}",
#							        format    => 'Current=%lf',
#							      },
	  								
							);

	}

	# Draw a graph in a PNG image
	$rrd->graph( @graph_params );
	
	if ( -e "$self->{_graph_dir}/tmp/$graph_filename") {	
		`mv $self->{_graph_dir}/tmp/$graph_filename $self->{_graph_dir}`;	
	} else {
		$log->error("graph not generated '$graph_filename'");
		return undef;
	}
	
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


#TODO paramétre pour choisir la liste des ds dont on veut afficher le pourcentage
sub graphPercent {
	my $self = shift;
	my %args = @_;
	
	my $host = $args{host};
	
	my ($time_start, $time_end, $time_suffix) = $self->_timeLaps( time_laps => $args{time_laps}, time_range => $args{time_range} );
	
	my $set_name = $args{set_label};
	
	my $rrd_name = $self->rrdName( set_name => $set_name, host_name => $host );	
	$rrd_name .= "_$args{aggreg_ext}" if (defined $args{aggreg_ext});
	#$rrd_name .= "_total" if (defined $args{aggreg_ext});
	
	my $cluster_total = (defined $args{aggreg_ext} && $args{aggreg_ext} eq 'total') ? 1 : undef;
	
	my $graph_name = "graph_$host" . "_$set_name" . (defined $args{aggreg_ext} ? "_$args{aggreg_ext}" : "") . ( defined $time_suffix ? "_$time_suffix" : "" );
	#TODO Specific graph in percent . "_percent";
	my $graph_filename = "$graph_name.png";

	# TODO graph cluster total percent ? -> est ce que c'est logique ? => die?
	
	my $graph_title = (defined $args{type} && $args{type} eq 'cluster') ?
						"$set_name for cluster $host " . ( defined $cluster_total ? "(total)" : "(average)" )
						: "$set_name for $host";

	my $graph_type = $args{graph_type} || "line";
	#my ($set_def) = grep { $_->{label} eq $set_name} @{ $self->{_monitored_data} };
	#my $ds_list = General::getAsArrayRef( data => $set_def, tag => 'ds');


	# Retrieve max definition
	my $set_def = $self->getSetDesc(set_label => $set_name);
	my @max_def;
	if ( $set_def->{max} ) { @max_def = split( /\+/, $set_def->{max} ) };
	if ( 0 == scalar @max_def ) {
		$log->warn("Warning: No max definition to compute percent for '$set_name'.");
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
						'image' => "$self->{_graph_dir}/tmp/$graph_filename",
						title => $graph_title,
						#'vertical_label', 'ticks',
						'start' => $time_start,
						'end' => $time_end,
						font => $self->{_graph_title_font},
						color => $self->{_graph_color},
						width => $self->{_graph_width},
						height => $self->{_graph_height},
						lower_limit => 0,
						);


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
	}
	
	my $total_op = join( ",", @max_def);
	for (my $i=1; $i < @max_def; ++$i) { $total_op .= ",+" };
	
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
										legend => $ds->{label} . " (%)",
		  							}	
								);
				#}
	}

	# Draw a graph in a PNG image
	my $res = $rrd->graph( @graph_params );

	if ( -e "$self->{_graph_dir}/tmp/$graph_filename") {	
		`mv $self->{_graph_dir}/tmp/$graph_filename $self->{_graph_dir}`;
	} else {
		$log->error("graph not generated '$graph_filename'");
		return undef;
	}
	
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

sub graphCluster {
	my $self = shift;
	my %args = @_;

	my $cluster = $args{cluster};

	my $time_laps = $args{time_laps} || 3600;
	
	my $required_set = $args{required_set} || "all";
	my $required_ds = $args{required_indicators} || "all";
	
	my $monitManager = $self->{_admin_wrap}{_admin}->{manager}{monitor};
	my $sets = ($required_set eq "all") ? $monitManager->getIndicatorSets() : [$monitManager->getSetDesc( set_name => $required_set )]; 
	
	my %res = ();
	foreach my $set_def ( @$sets ) {
		if ( $required_set eq "all" || $required_set eq $set_def->{label} )
		{
			my $ds_def_list = General::getAsArrayRef( data => $set_def, tag => 'ds');
			my @required_ds_def_list;
			foreach my $ds_def ( @$ds_def_list ) {
				push( @required_ds_def_list, $ds_def ) if $required_ds eq "all" || 0 < grep { $ds_def->{label} eq $_ } @$required_ds;
			}

			eval {
				my $graph_sub = defined $args{percent} && $args{percent} ne "no" ? \&graphPercent : \&graphNode;
				$graph_sub = \&graphTable if defined $set_def->{'table_oid'};
				# graph mean
				my $graph_filename = $graph_sub->( 	$self,
												host => $cluster,
												time_laps => $time_laps,
												time_range => $args{time_range},
												set_label => $set_def->{label},
												ds_def_list => \@required_ds_def_list,
												graph_type => $args{graph_type},
												type => 'cluster',
												aggreg_ext => 'avg',
												with_total => $args{with_total},
												options => $args{options} );
				# graph total
#				$graph_filename = $graph_sub->( 	$self,
#												host => $cluster,
#												time_laps => $time_laps,
#												time_range => $args{time_range},
#												set_label => $set_def->{label},
#												ds_def_list => \@required_ds_def_list,
#												graph_type => $args{graph_type},
#												type => 'cluster',
#												aggreg_ext => "total" );
												
				$res{$set_def->{label}} = $graph_filename;
			};
			if ($@) {
				my $error = $@;
				#die $error;
				$log->error("$error");
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
		nodes_ip : array ref of string : list of ip of nodes we want graph
		(optional) graph_type: "stack" or "line"
		(optional) required_set : string : the name of the set we want graph (else graph all the set)
		(optional) required_indicators : array ref : names of indicators (ds) we want for the required set (else graph all ds of the set)
	
	Return : Hash ref containing filenames of all generated graph { host => { set_label => "file.png" } }
	
=cut

sub graphNodes {
	my $self = shift;
	my %args = @_;
	
	my $time_laps = $args{time_laps} || 3600;
	
	my $required_set = $args{required_set} || "all";
	my $required_ds = $args{required_indicators} || "all";
	
	my $monitManager = $self->{_admin_wrap}{_admin}->{manager}{monitor};
	my $sets = ($required_set eq "all") ? $monitManager->getIndicatorSets() : [$monitManager->getSetDesc( set_name => $required_set )]; 
	
	my %res; #the hash containing filename of all generated graph (host => { set_label => "file.png" })
	
	#my @hosts = $self->retrieveHostsIp();
	my @hosts = @{ $args{nodes_ip} };
	
	foreach my $set_def ( @$sets ) {

		my $ds_def_list = General::getAsArrayRef( data => $set_def, tag => 'ds');
		my @required_ds_def_list;
		foreach my $ds_def ( @$ds_def_list ) {
			push( @required_ds_def_list, $ds_def ) if $required_ds eq "all" || 0 < grep { $ds_def->{label} eq $_ } @$required_ds;
		}
		
		foreach my $host (@hosts) {
			eval {
				my $graph_sub = defined $args{percent} && $args{percent} ne "no" ? \&graphPercent : \&graphNode;
				$graph_sub = \&graphTable if defined $set_def->{'table_oid'};
				my $graph_filename = $graph_sub->( 	$self,
													host => $host,
													time_laps => $time_laps,
													time_range => $args{time_range},
													set_label => $set_def->{label},
													ds_def_list => \@required_ds_def_list,
													graph_type => $args{graph_type},
													options => $args{options} );
				$res{$host}{$set_def->{label}} = $graph_filename;
			};
			if ($@) {
				my $error = $@;
				#die $error;
				$log->error("$error");
			}

		}
	}
	
	return \%res;
}


sub graphFromConf {
	my $self = shift;
	my %args = @_;
	
	# retrieve custom graph conf
	my $custom_file = "/tmp/gen_graph_custom.conf";
	my $time_range;
	if ( -e $custom_file ) {
		open FILE, "<$custom_file";
		my @lines = <FILE>;
		$time_range = shift @lines;
	}
	my @time_laps = ('1200', 'hour', 'day');
	
	my %hosts_by_cluster = $self->retrieveHostsByCluster();

	while ( my ($cluster_name, $cluster_nodes) = each %hosts_by_cluster ) {
		eval {
			my $cluster_id = $self->{_admin_wrap}->getClusterId( cluster_name => $cluster_name );
			my $graphs_settings = $self->{_admin_wrap}{_admin}->{manager}{monitor}->getClusterGraphSettings( cluster_id => $cluster_id );
			
			my @nodes_ip = map { $_->{ip} } values %$cluster_nodes;
			
			foreach my $graph_def ( @$graphs_settings ) {
				my @required_indicators = split ",", $graph_def->{ds_label};
				my $required = $graph_def->{ds_label} eq 'ALL' ? 'all' : \@required_indicators;
					
				foreach my $laps (@time_laps) {
					# Graph cluster
					$self->graphCluster( 	time_laps => $laps,
											time_range => $time_range,
											cluster => $cluster_name,
											required_set => $graph_def->{set_label},
											required_indicators => $required,
											percent => $graph_def->{percent},
											graph_type => $graph_def->{graph_type} || 'line',
											with_total => $graph_def->{with_total},
											options => $graph_def );
											
					# Graph cluster Nodes
					$self->graphNodes( 	nodes_ip => \@nodes_ip,
										time_laps => $laps,
										time_range => $time_range,
										required_set => $graph_def->{set_label},
										required_indicators => $required,
										percent => $graph_def->{percent},
										graph_type => $graph_def->{graph_type} || 'line',
										options => $graph_def );
					
				} # foreach time_laps
				
			} # foreach graph_desc
			
			# Graph Node Count
			foreach my $laps (@time_laps) {
				$self->graphNodeCount( 	time_laps => $laps,
										time_range => $time_range,
										cluster => $cluster_name );
			}
		};
		if ($@) {
			my $error = $@;
			$log->error("Error generating graph : $error");
			next;
		}
											
	} # foreach cluster
	
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
    
    my ($time_start, $time_end, $time_suffix) = $self->_timeLaps( time_laps => $args{time_laps}, time_range => $args{time_range} );
    
    my $graph_file = "graph_$cluster" . "_nodecount" . (defined $time_suffix ? "_$time_suffix" : "") . ".png";
	my $graph_file_path = "$self->{_graph_dir}/tmp/$graph_file";
	
	# get rrd     
	my $rrd = RRDTool::OO->new( file => "$self->{_rrd_base_dir}/nodes_$cluster.rrd" );
	
	$rrd->graph( 	'image' => $graph_file_path,
					#'vertical_label' => 'number of nodes',
					'title' => "Node count for cluster $cluster",
					'start' => $time_start,
					'end' => $time_end,
					#color => { back => "#69B033" },
					
					color => $self->{_graph_color},
					font => $self->{_graph_title_font},
					width => $self->{_graph_width},
					height => $self->{_graph_height},
					
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
					
	`mv $self->{_graph_dir}/tmp/$graph_file $self->{_graph_dir}`;
	
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


=head2 run
	
	Class : Public
	
	Desc : Launch graph generation every time_step (configuration)
	
=cut
 
sub run {
	my $self = shift;
	my $running = shift;
	
	my $adm = $self->{_admin_wrap};
	$adm->addMessage(from => 'Monitor', level => 'info', content => "Kanopia Grapher started.");
	
	while ( $$running ) {

		my $start_time = time();

		$self->graphFromConf();

		my $update_duration = time() - $start_time;
		$log->info( "Graphing duration : $update_duration seconds" );
		if ( $update_duration > $self->{_grapher_time_step} ) {
			$log->warn("graphing duration > graphing time step conf ($self->{_grapher_time_step})");
		} else {
			sleep( $self->{_grapher_time_step} - $update_duration );
		}

	}
	
	$adm->addMessage(from => 'Monitor', level => 'warning', content => "Kanopia Grapher stopped");
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut