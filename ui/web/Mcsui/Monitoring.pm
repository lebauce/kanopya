package Mcsui::Monitoring;
use Data::Dumper;
use base 'CGI::Application';
use Log::Log4perl "get_logger";
use CGI::Application::Plugin::AutoRunmode;
use CGI::Application::Plugin::Redirect;
use XML::Simple;
use JSON;

my $log = get_logger("administrator");

my $conf_file_path = "/etc/kanopya/monitor.conf";

sub setup {
	my $self = shift;
	$self->{'admin'} = Administrator->new(login => 'thom', password => 'pass');
}

# Build an array of html template hash for graphs associated to one target (cluster or node) and one set of indicators
sub graphs {
	my $self = shift;
	my %args = @_;
	
	my ($dir, $dir_alias, $subdir) = ($args{dir}, $args{dir_alias}, $args{subdir});
	my $target = $args{target};
	my $set = $args{set};
	my $ext = defined $args{ext} ? "_$args{ext}" : ""; 
	
	my @graphs = ();

	my $graph_name = "graph_" . "$target" . "_$set";
	if ( -e "$dir/$subdir/$graph_name$ext.png" ) {
		push @graphs, { CUSTOM_GRAPH_FILE => "$dir_alias/$subdir/$graph_name$ext.png",
						HOUR_GRAPH_FILE => "$dir_alias/$subdir/$graph_name$ext" . "_hour.png",
						DAY_GRAPH_FILE => "$dir_alias/$subdir/$graph_name$ext" . "_day.png",
						};
	} else {
		# Here we manage graph of table when there is one graph per raw
		my $files = `ls $dir/$subdir/ | grep $graph_name`;
		my %indexes = ();
		foreach $file (split '\n', $files) {
			if ( $file =~ /$graph_name\.(.*)_.*/ ) { $indexes{$1} = undef }
		}
		foreach $index ( keys %indexes) {
			push @graphs,	{
								CUSTOM_GRAPH_FILE => "$dir_alias/$subdir/$graph_name" . ".$index$ext.png",
								HOUR_GRAPH_FILE => "$dir_alias/$subdir/$graph_name" . ".$index$ext" . "_hour.png",
								DAY_GRAPH_FILE => "$dir_alias/$subdir/$graph_name" . ".$index$ext" . "_day.png",
							}
		}
	}
	
	return @graphs;
}


sub getMonitorConf () {
	my $self = shift;
	
	my $config = XMLin($conf_file_path);
	my $all_conf = General::getAsArrayRef( data => $config, tag => 'conf' );
	my @conf = grep { $_->{label} eq $config->{use_conf} } @$all_conf;
	my $conf = shift @conf;
	return $conf;
}

sub getMonitoredSets {
	my $self = shift;
	
	my $conf = $self->getMonitorConf();
	return General::getAsArrayRef( data => $conf, tag => 'monitor' )
}

sub getAllSets {
	my $self = shift;
	
	my $config = XMLin($conf_file_path);
	my $sets = General::getAsArrayRef( data => $config, tag => 'set' );
	
	return $sets;
}

#TODO passer par le monitor (et supprimer les bases inutiles) 
sub writeConf {
	my $self = shift;
	my %args = @_; 
	
	my $config = XMLin($conf_file_path);
	
	my $conf = $self->getMonitorConf();
	$conf->{generate_graph} = { graph => $args{graphs_settings} };
	$conf->{monitor} = $args{collect_settings};
	
	$config->{conf} = [$conf];
	
	#my $xml_conf = XMLout($conf, RootName => 'conf');
	my $xml_conf = XMLout($config, RootName => 'config');
	
	open CONF_FILE, ">$conf_file_path" or die "Can't open conf file for writing";
	print CONF_FILE $xml_conf;
	close CONF_FILE;
	
	return $xml_conf;
}

sub view_clustermonitoring : Runmode {
	my $self = shift;
	my $errors = shift;
	my $tmpl = $self->load_tmpl('Monitor/view_clustermonitoring.tmpl');
	
	my $cluster_id = $self->query()->param('cluster_id');
	
	#SETS
	my @sets = map { { id => $_->{set}, label => $_->{set} } } @{$self->getMonitoredSets()};
	$tmpl->param('SETS' => \@sets);
	
	#NODES
	my $cluster = $self->{'admin'}->getEntity(type => 'Cluster', id => $cluster_id);
	my $motherboards = $cluster->getMotherboards(administrator => $self->{'admin'});
	my @nodes = map { { id => $_->getAttr(name=>'motherboard_id'),
						name => $_->getAttr(name=>'motherboard_internal_ip')}
					} values %$motherboards;
	$tmpl->param('NODES' => \@nodes);
	
	#CLUSTER
	$cluster_name = $cluster->getAttr( name => 'cluster_name' );
	$tmpl->param('CLUSTER_ID' => $cluster_name);
	$tmpl->param('CLUSTER_NAME' => $cluster_name);
	
	$tmpl->param('TITLEPAGE' => "Cluster's activity");
	#$tmpl->param('MENU_CLUSTERSMANAGEMENT' => 1);
	
	return $tmpl->output();
}

sub xml_graph_list : Runmode {
	my $self = shift;
	my $errors = shift;
	my $tmpl = $self->load_tmpl('Monitor/subview_clustermonitoring.tmpl');
	my $query = $self->query();
	my $set_name = $query->param('set');
	my $node_id = $query->param('node');
	my $period = $query->param('period') || "hour";
	
	my $cluster_id = $query->param('cluster_id');
	my $cluster = $self->{'admin'}->getEntity(type => 'Cluster', id => $cluster_id);
	my $motherboards = $cluster->getMotherboards(administrator => $self->{'admin'});
	my @all_ids = keys %$motherboards;
	my $cluster_name = $cluster->getAttr( name => 'cluster_name' ); 
	push @all_ids, $cluster_name;
	
	my @sets_name = map { $_->{set} } @{$self->getMonitoredSets()};
	
	my ($graph_dir, $graph_dir_alias, $graph_subdir) = ("/tmp", "/graph", "monitor/graph");
	
	my @graphs = ();	
	foreach my $node_id ( defined $node_id ? ($node_id) : @all_ids) {
		my $node_ip = '';
		my $aggreg_ext = '';
		if ($node_id eq $cluster_name) {
			$aggreg_ext = '_avg';
			$node_ip = $cluster_name;	
		} else {
			$node_ip = $motherboards->{$node_id}->getAttr(name=>'motherboard_internal_ip');
		}
		my @sets = ();
		foreach my $set ( defined $set_name ? ($set_name) : @sets_name ) {
			my $graph_name = "graph_" . $node_ip . "_" . $set . $aggreg_ext . "_" . $period . ".png";
			if ( -e  "$graph_dir/$graph_subdir/$graph_name" ) {
				push @sets, { 	set_name => $set,
								img_src => "$graph_dir_alias/$graph_subdir/$graph_name"};
			} else {
				push @sets, { 	set_name => $set,
								no_graph => 1};
			}
		}
		push @graphs, { id => $node_id, sets => \@sets};
	}
	$tmpl->param('GRAPHS' => \@graphs);
	return $tmpl->output();
	
}



=head2 save_monitoring_settings
	
	Class : Public
	
	Desc : 	Called by client to save monitoring settings.
			Transform: query params (json) -> perl type (according to xml conf struct) -> xml (conf) 
	
=cut

sub save_monitoring_settings : Runmode {
	my $self = shift;
	my $errors = shift;
	my $query = $self->query();
	
	my @monit_sets = $query->param('collect_sets[]'); # array of set name
	my @formated_monit_sets = map { { set => $_} } @monit_sets;
	
	my $graphs_settings_str = $query->param('graphs_settings'); # stringified array of hash
	my $graphs_settings = decode_json $graphs_settings_str;
		
	
	my $xml_conf = $self->writeConf( graphs_settings => $graphs_settings, collect_settings => \@formated_monit_sets );
	
	#my $xml_conf = XMLout($conf, RootName => 'conf');
	
	return "$xml_conf";
}

sub view_monitoring_settings : StartRunmode {
	my $self = shift;
	my $errors = shift;
	my $tmpl = $self->load_tmpl('Monitor/view_monitoring_settings.tmpl');
	
	#TODO put this in Monitor (method for retrieve conf)
	my $conf = $self->getMonitorConf();
	
	my $collect_sets = General::getAsArrayRef( data => $conf, tag => 'monitor' );
	my $all_sets = $self->getAllSets();

	my @sets = ();
	foreach $set (@$all_sets) {
		my @all_ds = ();
		foreach $ds ( @{ General::getAsArrayRef( data => $set, tag => 'ds' ) } ) {
			push @all_ds, { ds_name => $ds->{label}, oid => $ds->{oid}};
		}
		 
		push @sets, {	label => $set->{label},
						provider_name => ($set->{data_provider} =~ /(.*)Provider/) ? $1 : ($set->{data_provider} ? $set->{data_provider} : "Snmp"),
						component => $set->{component},
						ds_type => $set->{ds_type},
						is_table => defined $set->{table_oid},
						table_oid => $set->{table_oid},
						ds => \@all_ds};
	}
	$tmpl->param('SETS' => \@sets);
	
	$tmpl->param(	'TIME_STEP' => $conf->{time_step},
					'PERIOD' => $conf->{period},
					'RRD_BASE_DIR'=> $conf->{rrd_base_dir},
					'GRAPH_DIR'=> $conf->{graph_dir} );
	
	$tmpl->param('TITLEPAGE' => "Monitoring settings");
	$tmpl->param('MSETTINGS' => 1);
	$tmpl->param('SUBMMONITOR' => 1);
	
	return $tmpl->output();
}

=head2 view_clustermonitoring_settings
	
	Class : Public
	
	Desc : 	build html page of monitoring settings for client.
			Tranform: conf (xml) -> perl type (according to html template) -> html
	
	Args :
	
	Return :
	
=cut

sub view_clustermonitoring_settings : Runmode {
	my $self = shift;
	my $errors = shift;
	my $tmpl = $self->load_tmpl('Monitor/view_clustermonitoring_settings.tmpl');
	
	#TODO put this in Monitor (method for retrieve conf)
	my $conf = $self->getMonitorConf();
	my $collect_sets = General::getAsArrayRef( data => $conf, tag => 'monitor' );
	my $graphs_settings = General::getAsHashRef( data => $conf->{generate_graph}, tag => 'graph', key => 'set_label' );
	my $all_sets = $self->getAllSets();
	my @sets = ();
	foreach $set (@$all_sets) {
		my @all_ds = ();
		my $graph_settings = $graphs_settings->{$set->{label}};
		my @ds_on_graph = defined $graph_settings ? split(",", $graph_settings->{ds_label}) : ();
		my $is_graphed = scalar @ds_on_graph;
		foreach $ds ( @{ General::getAsArrayRef( data => $set, tag => 'ds' ) } ) {
			push @all_ds, {
							ds_name => $ds->{label},
							on_graph => scalar ( grep { $_ eq $ds->{label} || $_ eq 'ALL'} @ds_on_graph ),
							};
		}
		 
		push @sets, {	label => $set->{label},
						collected => scalar ( grep { $_->{set} eq $set->{label} } @$collect_sets ),
						graphed => $is_graphed,
						is_table => defined $set->{table_oid},
						
						graph_type => defined $graph_settings ? $graph_settings->{graph_type} || 'line' : 'line',
						percent => defined $graph_settings ? $graph_settings->{percent} || 'no' : 'no',
						with_total => defined $graph_settings ? $graph_settings->{with_total} || 'no' : 'no',
						all_in_one => defined $graph_settings ? $graph_settings->{all_in_one} || 'no' : 'no',
													
						ds => \@all_ds,
					};
	}
	$tmpl->param('SETS' => \@sets);
	
	$tmpl->param('TITLEPAGE' => "CLuster monitoring settings");
	$tmpl->param('MSETTINGS' => 1);
	$tmpl->param('SUBMMONITOR' => 1);
	
	return $tmpl->output();
}


sub process_customgraph : Runmode {
	my $self = shift;
	
	 my $query = $self->query();
	 
	 my ($date_start, $time_start, $date_end, $time_end) = ( $query->param('date_start'), $query->param('time_start'),
	 														 $query->param('date_end'), $query->param('time_end') );
	 
	 # we write custom range in a specific file which will be read by Monitor::Retriever at the next graph generation iteration
	 `echo "$date_start $time_start,$date_end $time_end" > /tmp/gen_graph_custom.conf`;
	 
#	 use Monitor::Retriever;
#	 my $monitor = Monitor::Retriever->new();
#	 my %graph_infos = $monitor->graphFromConf();
	
	 $self->redirect('/cgi/mcsui.cgi/clusters/view_clusterdetails?cluster_id='.$query->param('cluster_id') . "&custom" . "#monitoring");
}

1;
