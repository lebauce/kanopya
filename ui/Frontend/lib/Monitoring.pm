package Monitoring;

use Dancer ':syntax'; 
use Dancer::Plugin::Ajax;
use Data::Dumper;

use Entity::ServiceProvider::Inside::Cluster;
use Entity::ServiceProvider::Outside::Externalcluster;
use AggregateRule;
use General;
use Log::Log4perl "get_logger";

my $log = get_logger("webui");

prefix '/architectures';

sub _getMonitoredSets {
    my %args = @_;
    my $adm    = Administrator->new();

    return $adm->{'manager'}{'monitor'}->getCollectedSets( cluster_id => $args{cluster_id} );
}

sub _getAllSets {
    my $adm    = Administrator->new();
        
    return $adm->{'manager'}{'monitor'}->getIndicatorSets();
}

#TODO change for ajax
#TODO something better than sending xml and building html in javascript (monitor.js) using this xml :/
get '/clusters/:clusterid/monitoring/graphs' => sub {
    my $set_name    = params->{'set'};
    my $node_id     = params->{'node'};
    my $period      = params->{'period'} || "hour";
    
    my $cluster_id = params->{'clusterid'};
    my $cluster = Entity::ServiceProvider::Inside::Cluster->get( id => $cluster_id );
    my $hosts = $cluster->getHosts();
    my @all_ids = keys %$hosts;
    my $cluster_name = $cluster->getAttr( name => 'cluster_name' ); 
    push @all_ids, $cluster_name;

    my @sets_name = map { $_->{label} } @{_getMonitoredSets( cluster_id => $cluster_id )};
    
    #TODO retrieve from conf
    my ($graph_dir, $graph_dir_alias, $graph_subdir) = ("/tmp/monitor/graph", "/images/graphs", "");

    # node count graph
    my $nodecount_graph = "graph_" . $cluster_name . "_nodecount_" . $period . ".png";
    my $nodecount_graph_path = "$graph_dir_alias/$nodecount_graph";
    
    my @graphs = ();
    my @node_info = ();
    foreach my $node_id ( defined $node_id ? ($node_id) : @all_ids) {
        my @sets = ();
        my $node_ip = '';
        my $aggreg_ext = '';
        if ($node_id eq $cluster_name) {
            $aggreg_ext = '_avg';
            $node_ip = $cluster_name;    

        } else {
            $node_ip = $hosts->{$node_id}->getInternalIP()->{ipv4_internal_address};
        }
        
#        foreach my $set ( defined $set_name ? ($set_name) : @sets_name ) {
#            my $graph_name = "graph_" . $node_ip . "_" . $set . $aggreg_ext . "_" . $period . ".png";
#            if ( -e  "$graph_dir/$graph_subdir/$graph_name" ) {
#                push @sets, {   set_name => $set,
#                                img_src => "$graph_dir_alias/$graph_subdir/$graph_name"};
#            } else {
#                push @sets, {     set_name => $set,
#                                no_graph => 1};
#            }
#        }
#        push @graphs, { id => $node_id, sets => \@sets};
#        
        my $graph_name = "graph_" . $node_ip . "_" . $set_name . $aggreg_ext . "_" . $period . ".png";
        push @node_info, {id => $node_id, img_src => "$graph_dir_alias/$graph_name"};
    }
#    $tmpl->param('GRAPHS' => \@graphs);
#    
#    my $nodecount_graph = "graph_" . $cluster_name . "_nodecount_" . $period . ".png";
#    $tmpl->param('NODECOUNT_GRAPH' => "$graph_dir_alias/$graph_subdir/$nodecount_graph");

    content_type('text/xml');
    return to_xml { node => \@node_info, nodecount_graph => { src => $nodecount_graph_path } };
     
};

get '/clusters/:clusterid/monitoring' => sub {
    my $cluster_id    = params->{clusterid} || 0;

    #SETS
    my @sets = map { { id => $_->{label}, label => $_->{label} } } @{_getMonitoredSets( cluster_id => $cluster_id )};
    
    #NODES
    my $cluster = Entity::ServiceProvider::Inside::Cluster->get( id => $cluster_id );
    my $hosts = $cluster->getHosts();
    my $masterId = $cluster->getMasterNodeId();
    my @nodes = map { { id => $_->getAttr(name=>'host_id'),
                        name => $_->getInternalIP()->{ipv4_internal_address},
                        master => ($_->getAttr(name=>'host_id') == $masterId) }
                    } values %$hosts;
    
    #CLUSTER
    my $cluster_name = $cluster->getAttr( name => 'cluster_name' );
    
    my $period = 'hour';
    #TODO retrieve from conf
    my ($graph_dir, $graph_dir_alias, $graph_subdir) = ("/tmp/monitor/graph", "/images/graphs", "");
    
    my $nodecount_graph = "graph_" . $cluster_name . "_nodecount_" . $period . ".png";
    my $nodecount_graph_path = "$graph_dir_alias/$nodecount_graph";
    

    template 'view_clustermonitoring', {
        title_page                 => "Cluster's activity",
        nodecount_graph => $nodecount_graph_path,
        cluster_id      => $cluster_id,
        cluster_name    => $cluster_name,
        nodes => \@nodes,
        sets => \@sets,
    };
};

get '/clusters/:clusterid/monitoring/settings' => sub  {
    my $adm    = Administrator->new();
    
    my $cluster_id = params->{clusterid};
    my $collect_sets = _getMonitoredSets( cluster_id => $cluster_id );
    my $all_sets = _getAllSets();
    my @sets = ();

    foreach my $set (@$all_sets) {
        my @all_ds = ();
        my $graph_settings = $adm->{'manager'}{'monitor'}->getGraphSettings(    cluster_id => $cluster_id,
                                                                                set_name => $set->{label} );
        my @ds_on_graph = defined $graph_settings ? split(",", $graph_settings->{ds_label}) : ();
        my $is_graphed = scalar @ds_on_graph;
        foreach my $ds ( @{ General::getAsArrayRef( data => $set, tag => 'ds' ) } ) {
            push @all_ds, {
                            ds_name => $ds->{label},
                            on_graph => scalar ( grep { $_ eq $ds->{label} || $_ eq 'ALL'} @ds_on_graph ),
                            };
        }
         
        push @sets, {   label => $set->{label},
                        collected => scalar ( grep { $_->{label} eq $set->{label} } @$collect_sets ),
                        graphed => $is_graphed,
                        is_table => defined $set->{table_oid},
                        
                        graph_type => defined $graph_settings ? $graph_settings->{graph_type} || 'line' : 'line',
                        percent => defined $graph_settings ? $graph_settings->{percent} || 'no' : 'no',
                        with_total => defined $graph_settings ? $graph_settings->{with_total} || 'no' : 'no',
                        all_in_one => defined $graph_settings ? $graph_settings->{all_in_one} || 'no' : 'no',
                                                    
                        ds => \@all_ds,
                    };
    }
    
    template 'view_clustermonitoring_settings', {
        title_page      => "Cluster monitoring settings",
        cluster_id      => $cluster_id,
        sets  => \@sets,
    };
};

=head2 save_clustermonitoring_settings
    
    Class : Public
    
    Desc : Called by client to save monitoring settings for a cluster (collected sets and graphs options). 
    
=cut

get '/clusters/:clusterid/monitoring/settings/save' => sub  {
    my $adm    = Administrator->new();
    
    my $cluster_id = params->{clusterid};
    
    $log->info("Save monitoring settings for cluster $cluster_id");
    
    my $collect_sets = params->{'collect_sets'};
    my $monit_sets = from_json $collect_sets;
    #my @monit_sets = params->{'collect_sets[]'}; # array of set name

    my $graphs_settings_str = params->{'graphs_settings'}; # stringified array of hash
    my $graphs_settings = from_json $graphs_settings_str;
        
    my $res = "conf saved";
    
    eval {
        $adm->{'manager'}{'monitor'}->collectSets( cluster_id => $cluster_id, sets_name => $monit_sets );
        $adm->{'manager'}{'monitor'}->graphSettings( cluster_id => $cluster_id, graphs => $graphs_settings );
    };
    if ($@) {
        $res = "Error while saving: $@";
    }
    
    content_type('text/text');
    return "$res";
};

get '/monitoring/browse' => sub  {
    my $cluster_id = params->{clusterid};
    
    my $route_name = 'monitor_data';
    my $path = "../public/";
    
    my $ls_output = `ls $path$route_name`;

   # my @files = grep { -f "$path$_" } split(" ", $ls_output);
    my @files = split(" ", $ls_output);
 
    my @rrd_files = map { {
                    route   => $route_name,
                    name    => $_
                } } @files;
    
    template 'view_clustermonitoring_flot', {
        title_page      => "Monitor rrd plot",
        cluster_id      => $cluster_id,
        rrd_files       => \@rrd_files,
    };
};

# ---------------------------------------------------------------------------------------------#
# -----------------------------external cluster monitoring (poc BT)----------------------------#
# ---------------------------------------------------------------------------------------------#

get '/extclusters/:extclusterid/monitoring' => sub {
    my $cluster_id = params->{extclusterid} || 0;
   

	my %template_config = (title_page => "Cluster Monitor Overview", cluster_id => $cluster_id);
	my %labels;
	
	# we retrieve the indicator list for this external cluster
	_getIndicators(\%template_config);
	# $log->error('after indicator request: '.Dumper(\%template_config));
		
	#we retrieve the combination list for this external cluster
	# _getCombinations(\%template_config);
	
	
	template 'cluster_monitor', \%template_config;
};

# ajax '/extclusters/:extclusterid/monitoring/clustermetricview' => sub {
	# my $cluster_id    = params->{extclusterid} || 0;   

# };  
  

ajax '/extclusters/:extclusterid/monitoring/metricview' => sub {
    my $cluster_id    = params->{extclusterid} || 0;   
    my $extcluster = Entity::ServiceProvider::Outside::Externalcluster->get(id=>$cluster_id);
    my $indicator = params->{'oid'};
	my $indicator_unit =  params->{'unit'};
	my $nodes_metrics; 
	my $error;
	# $log->error('login before eval, indicator: '.Dumper($indicator));
	# $log->error('login before eval, indicator_unit: '.Dumper($indicator_unit));
	eval {
		$nodes_metrics = $extcluster->getNodesMetrics(indicators => [$indicator], time_span => 3600);
		# $log->error('login from eval: '.Dumper($nodes_metrics));
	};
	if ($@){
		$error="$@";
		$log->error($error);
		to_json {error => $error};
	}elsif (!defined $nodes_metrics || %$nodes_metrics == ()){
		$error='no values could be retrieved for this metric';
		$log->error($error);
		to_json {error => $error};
	}else{
		my @nodes;
		my @values;
		
		while (my ($node, $metric) = each %$nodes_metrics){
			push @nodes, $node;
			push @values, int($metric->{$indicator});
		}		
		to_json {values => \@values, nodelist => \@nodes, unit => $indicator_unit};
	}
};


get '/rules' => sub {
  my @enabled_aggregaterules = AggregateRule->getRules(state => 'enabled'); 
#  my @enabled_aggregaterules = AggregateRule->search(hash => {aggregate_rule_state => 'enabled'});
  my @rules;
  foreach my $aggregate_rule (@enabled_aggregaterules) {
    my $hash = {
        id        => $aggregate_rule->getAttr(name => 'aggregate_rule_id'),
        formula   => $aggregate_rule->toString(),
        last_eval => $aggregate_rule->getAttr(name => 'aggregate_rule_last_eval'),

    };
    push @rules, $hash;
  }
  
  template 'clustermetric_rules', {
        title_page      => "Enabled Rules Overview",
        rules   => \@rules,
        status  => 'enabled',
  };
    
};

get '/rules/disabled' => sub {
  my @disabled_aggregaterules = AggregateRule->getRules(state => 'disabled');
  #my @disabled_aggregaterules = AggregateRule->search(hash => {aggregate_rule_state => 'disabled'});
  my @disabled_rules;
  foreach my $aggregate_rule (@disabled_aggregaterules) {
      
    my $hash = {
      id => $aggregate_rule->getAttr(name => 'aggregate_rule_id'),
      formula => $aggregate_rule->toString(),
      last_eval => -1,
    };
    push @disabled_rules, $hash;
  }
  
  template 'clustermetric_rules', {
        title_page      => "Disabled Rules Overview",
        rules   => \@disabled_rules,
        status  => "disabled",
  };
    
};

get '/rules/tdisabled' => sub {
  my @tdisabled_aggregaterules = AggregateRule->getRules(state => 'disabled_temp');
  #my @tdisabled_aggregaterules = AggregateRule->search(hash => {aggregate_rule_state => 'disabled_temp'});
  my @tdisabled_rules;
  foreach my $aggregate_rule (@tdisabled_aggregaterules) {
    my $hash = {
      id        => $aggregate_rule->getAttr(name => 'aggregate_rule_id'),
      formula   => $aggregate_rule->toString(),
      last_eval => -1,
      time      => $aggregate_rule->getAttr(name => 'aggregate_rule_timestamp') - time(),
    };
    push @tdisabled_rules, $hash;
  }  
  
  template 'clustermetric_rules', {
        title_page      => "Temporarily Disabled Rules Overview",
        rules           => \@tdisabled_rules,
        status          => 'tdisabled',
        
  };
    
};
get '/rules/enabled' => sub {
    redirect('/architectures/rules');
};


get '/rules/:ruleid/enable' => sub {
    my $aggregateRule = AggregateRule->get('id' => params->{ruleid});
    $aggregateRule->enable();
    redirect('/architectures/rules');
};

get '/rules/:ruleid/disable' => sub {
    my $aggregateRule = AggregateRule->get('id' => params->{ruleid});
    $aggregateRule->disable();
    redirect('/architectures/rules');
};

get '/rules/:ruleid/tdisable' => sub {
    my $aggregateRule = AggregateRule->get('id' => params->{ruleid});
    $aggregateRule->disableTemporarily(length => 120);
    redirect('/architectures/rules');

};


########################################
#######INNER FUNCTION DECLARATION#######
########################################

sub _getIndicators(){
	my $template_config = shift;
	my %errors;
	my $scom_indicatorset;
	my @indicators;
	my $hash;
	my $adm = Administrator->new();
	
	eval {
		$scom_indicatorset = $adm->{'manager'}{'monitor'}->getSetDesc( set_name => 'scom' );
	};
	if ($@) {
		my $error = "$@";
		$log->error($error);
		$template_config->{'errors'}{'indicators'} = $error;
		return %$template_config;
	}else{ 
		foreach my $indicator (@{$scom_indicatorset->{ds}}){
			$hash = {
				oid => $indicator->{oid},
				unit => $indicator->{unit},
				label =>  $indicator->{label},
			};
			push @indicators, $hash;
		}
		$template_config->{'indicators'} = \@indicators;
		return %$template_config;
	}
}

sub _getCombinations(){
		# my @combinations;
	
	# my @clustermetrics = Clustermetric->search(
            # hash => {
                # clustermetric_cluster_id => $cluster_id
            # }
        # );
	# for my $clustermetric (@clustermetrics){
		# push @combinations, $clustermetric->toString();
		# print $clustermetric->toString()."\n";
	# }
}
1;