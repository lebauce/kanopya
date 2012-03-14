package Monitoring;

use Dancer ':syntax'; 
use Dancer::Plugin::Ajax;
use Dancer::Plugin::EscapeHTML;
use Data::Dumper;

use Entity::ServiceProvider::Inside::Cluster;
use Entity::ServiceProvider::Outside::Externalcluster;
use AggregateRule;
use AggregateCombination;
use AggregateCondition;
use Aggregator;
use Clustermetric;
use NodemetricCombination;
use NodemetricRule;
use General;
use DateTime::Format::Strptime;
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

# --------------------------------------------------------------------#
# -----------------------------Plots view-----------------------------#
# --------------------------------------------------------------------#


=head2 get '/extclusters/:extclusterid/monitoring'

	Desc: Compute the values to be displayed on the monitoring page and create the according template
	
=cut

get '/extclusters/:extclusterid/monitoring' => sub {
    my $cluster_id = params->{extclusterid} || 0;
	my %template_config = (title_page => "Cluster Monitor Overview", cluster_id => $cluster_id);

	# we retrieve the indicator list for this external cluster
	_getIndicators(\%template_config);		
	#we retrieve the combination list for this external cluster
	_getCombinations(\%template_config);

	# $log->error('get combinations: '.Dumper\%template_config);

	template 'cluster_monitor', \%template_config;
};


=head2 ajax '/extclusters/:extclusterid/monitoring/clustersview'

	Desc: Get the values corresponding to the selected combination for the currently monitored cluster,	
	return to the monitor.js an 2D array containing the timestamped values for the combination, plus a start time and a stop time

=cut

ajax '/extclusters/:extclusterid/monitoring/clustersview' => sub {
	my $cluster_id = params->{extclusterid} || 0;   
	my $combination_id = params->{'id'};
	my $start = params->{'start'};
    my $start_timestamp;
	my $stop = params->{'stop'};
    my $stop_timestamp;	
	my $error;
    my $date_parser = DateTime::Format::Strptime->new( pattern => '%m-%d-%Y %H:%M' );
    my $combination = AggregateCombination->get('id' => $combination_id);
    my %aggregate_combination;
    my @histovalues;
    
	#If user didn't fill start and stop time, we set them at (now) to (now - 1 hour)
	if ($start eq '') {
		$start = DateTime->now->set_time_zone('local');
		$start->subtract( days => 1 );
        $start_timestamp = $start->epoch(); 
		$start = $start->mdy('-') . ' ' .$start->hour_1().':'.$start->minute();
	} else {
        my $start_dt = $date_parser->parse_datetime($start);
        $start_timestamp = $start_dt->epoch();
    }
        
	if ($stop eq '') {
		$stop = DateTime->now->set_time_zone('local');
        $stop_timestamp = $stop->epoch(); 
		$stop = $stop->mdy('-') . ' ' .$stop->hour_1().':'.$stop->minute();
	} else {
        my $stop_dt = $date_parser->parse_datetime($stop);
        $stop_timestamp = $stop_dt->epoch() ;
    }
    
    eval {
        %aggregate_combination = $combination->computeValues(start_time => $start_timestamp, stop_time => $stop_timestamp);
        # $log->error('combination gathered: '.Dumper(\%aggregate_combination));
    };
    if ($@) {
		$error="$@";
		$log->error($error);
		return to_json {error => $error};
	} elsif (!%aggregate_combination || scalar(keys %aggregate_combination) == 0) {
		$error='no values could be computed for this combination';
		$log->error($error);
		return to_json {error => $error};
	} else {
        while (my ($date, $value) = each %aggregate_combination) {				
                my $dt = DateTime->from_epoch(epoch => $date);
                my $date_string = $dt->strftime('%m-%d-%y %H:%M');
                push @histovalues, [$date_string,$value];
            }		
        # $log->info('values sent to timed graph: '.Dumper \@histovalues);
    }
	return to_json {first_histovalues => \@histovalues, min => $start, max => $stop};
};  
  
  
=head2 ajax '/extclusters/:extclusterid/monitoring/nodesview'

	Desc: Get the values corresponding to the selected nodes combination for the currently monitored cluster, 
	return to the monitor.js an array containing the nodes names for the combination, and another one containing the values for the nodes, plus the label of the node combination unit

=cut  

ajax '/extclusters/:extclusterid/monitoring/nodesview' => sub {
	my $cluster_id    = params->{extclusterid} || 0;   
	my $extcluster = Entity::ServiceProvider::Outside::Externalcluster->get(id=>$cluster_id);
	my $indicator = params->{'oid'};
	my $indicator_unit =  params->{'unit'};
	my $nodes_metrics; 
	my $error;
    
    # we retrieve the nodemetric values
	eval {
		$nodes_metrics = $extcluster->getNodesMetrics(indicators => [$indicator], time_span => 3600);
	};
    # error catching
	if ($@) {
		$error="$@";
		$log->error($error);
		return to_json {error => $error};
    # we catch the fact that there is no value available for the selected nodemetric
	} elsif (!defined $nodes_metrics || scalar(keys %$nodes_metrics) == 0) {
		$error='no values available for this metric';
		$log->error($error);
		return to_json {error => $error};
	} else {
        #we create an array containing the values, to be sorted
        my @nodes_values_to_sort;
        my @nodes_values_undef;
        while (my ($node, $metric) = each %$nodes_metrics) {
            if (defined $metric->{$indicator}) {
                push @nodes_values_to_sort, { node => $node, value => $metric->{$indicator} };
            } else {
                push @nodes_values_undef, $node;
            }
        }
        #we now sort this array
		my @sorted_nodes_values =  sort { $a->{value} <=> $b->{value} } @nodes_values_to_sort;
        # we split the array into 2 distincts one, that will be returned to the monitor.js
		my @nodes = map { $_->{node} } @sorted_nodes_values;
		my @values = map { $_->{value} } @sorted_nodes_values;	
		#we add nodes without values at the end of nodes list
		@nodes = (@nodes, @nodes_values_undef);
		
		return to_json {values => \@values, nodelist => \@nodes, unit => $indicator_unit};	
		# my (@test1, @test2);
        
		# for (my $i = 1; $i<51; $i++){
			# my $nde = 'node'.$i;
			# push @test2, $nde;
		# }
        # for (my $y = 1; $y<1500; $y+=37){
			# push @test1, $y;
		# }
        # $log->error('node list: '.Dumper @test2);
        # $log->error('values: '.Dumper @test1);
        
		# to_json {values => \@test1, nodelist => \@test2, unit => "unit"};
	}
};

get '/clustermetrics' => sub {
    my @clustermetrics = Clustermetric->search(hash=>{});
    my @clustermetrics_param;
    foreach my $clustermetric (@clustermetrics){
        my $hash = {
            id           => $clustermetric->getAttr(name => 'clustermetric_id'),
            label        => $clustermetric->toString(),
            indicator_id => $clustermetric->getAttr(name => 'clustermetric_indicator_id'),
            function     => $clustermetric->getAttr(name => 'clustermetric_statistics_function_name'),
            window       => $clustermetric->getAttr(name => 'clustermetric_window_time'),
        };
            push @clustermetrics_param, $hash;
    }
      template 'clustermetrics', {
        title_page      => "Clustermetrics Overview",
        clustermetrics  => \@clustermetrics_param,
      };
};

# ------------------------------------------------------------------------------------------------#
# ----------------------------- RELATED TO EXTCLUSTER CLUSTERMETRICS -----------------------------#
# ------------------------------------------------------------------------------------------------#


get '/extclusters/:extclusterid/clustermetrics' => sub {
    my @clustermetrics = Clustermetric->search(hash=>{'clustermetric_service_provider_id' => (params->{extclusterid})});
    my @clustermetrics_param;
    foreach my $clustermetric (@clustermetrics){
        my $hash = {
            id           => $clustermetric->getAttr(name => 'clustermetric_id'),
            label        => $clustermetric->toString(),
            indicator_id => $clustermetric->getAttr(name => 'clustermetric_indicator_id'),
            function     => $clustermetric->getAttr(name => 'clustermetric_statistics_function_name'),
            window       => $clustermetric->getAttr(name => 'clustermetric_window_time'),
        };
            push @clustermetrics_param, $hash;
    }
      template 'clustermetrics', {
        title_page      => "Clustermetrics Overview",
        clustermetrics  => \@clustermetrics_param,
        cluster_id      => params->{extclusterid},
      };

};


get '/extclusters/:extclusterid/clustermetrics/new' => sub {
    
   my $cluster_id    = params->{extclusterid} || 0;
   
    my $adm    = Administrator->new();
    my $scom_indicatorset = $adm->{'manager'}{'monitor'}->getSetDesc( set_name => 'scom' );
    my @indicators;
    
    foreach my $indicator (@{$scom_indicatorset->{ds}}){
        my $hash = {
            id     => $indicator->{id},
            label  => $indicator->{label},
        };
        push @indicators, $hash;
    }
    template 'clustermetric_new', {
        title_page => "Clustermetric creation",
        indicators => \@indicators,
        cluster_id => param('extclusterid'),
    };
};

post '/extclusters/:extclusterid/clustermetrics/new' => sub {
    my $cm_params = {
        clustermetric_service_provider_id      => param('extclusterid'),
        clustermetric_indicator_id             => param('id2'),
        clustermetric_statistics_function_name => param('function'),
        clustermetric_window_time              => '1200',
    };
    my $cm = Clustermetric->new(%$cm_params);
   
    my $comb_params = {
        aggregate_combination_service_provider_id =>param('extclusterid'),
        aggregate_combination_formula   => 'id'.($cm->getAttr(name => 'clustermetric_id'))
    };
    AggregateCombination->new(%$comb_params);
    
    my $var = param('extclusterid');
    redirect("/architectures/extclusters/$var/clustermetrics");
};


get '/extclusters/:extclusterid/clustermetrics/:clustermetricid/delete' => sub {
    my $clustermetric_id =  params->{clustermetricid};
    my $cluster_id       =  params->{extclusterid};
     
    my $clustermetric = Clustermetric->get('id' => $clustermetric_id);
    
    my @combinations = AggregateCombination->search(hash=>{});
    
    my @combinationsUsingCM;
    foreach my $combination (@combinations) {
        my $id = $combination->getAttr(name => 'aggregate_combination_id');
        
        if($combination->useClusterMetric($clustermetric_id)){
            push @combinationsUsingCM,$id 
        }
    }

    if( (scalar @combinationsUsingCM) eq 0) {
        $clustermetric->delete();
        redirect("/architectures/extclusters/$cluster_id/clustermetrics");
    }else{
        template 'clustermetric_deletion_forbidden', {
            title_page          => "Clustermetric Deletion Forbidden",
            combinationsUsingCM => \@combinationsUsingCM,
            clustermetric_id    => $clustermetric_id,
            cluster_id          => $cluster_id,
        }
    }
};



# -----------------------------------------------------------------------------#
# ------------------------- CLUSTERMETRICS COMBINATIONS------------------------#
# -----------------------------------------------------------------------------#

get '/extclusters/:extclusterid/clustermetrics/combinations' => sub {
    
    #my @clustermetric_combinations = AggregateCombination->getAllTheCombinationsRelativeToAClusterId(param('extclusterid'));
    my @clustermetric_combinations = AggregateCombination->search(hash=>{'aggregate_combination_service_provider_id' => (params->{extclusterid})});
    
    my @clustermetric_combinations_param;
    foreach my $clustermetric_combination (@clustermetric_combinations){
        my $hash = {
            id           => $clustermetric_combination->getAttr(name => 'aggregate_combination_id'),
            label        => $clustermetric_combination->toString(),
        };
        push @clustermetric_combinations_param, $hash;
        
    }
    
    template 'clustermetric_combinations', {
        title_page      => "ClusterMetrics Combinations Overview",
        combinations  => \@clustermetric_combinations_param,
        cluster_id      => params->{extclusterid},
    };
};

get '/extclusters/:extclusterid/clustermetrics/combinations/:combinationid/delete' => sub {
    
    my $combination_id =  params->{combinationid};
    my $cluster_id     =  params->{extclusterid};
     
    my $combination = AggregateCombination->get('id' => $combination_id);
    
    my @conditions = AggregateCondition->search(hash=>{});
    
    my @conditionsUsingCombination;
    foreach my $condition (@conditions) {
        if($condition->getAttr(name => 'aggregate_combination_id') eq $combination_id){
            push @conditionsUsingCombination,$condition->getAttr(name => 'aggregate_condition_id');
        }
    }

    if( (scalar @conditionsUsingCombination) eq 0) {
        $combination->delete();
        redirect("/architectures/extclusters/$cluster_id/clustermetrics/combinations");
    }else{
        template 'clustermetric_combination_deletion_forbidden', {
            title_page          => "Clustermetric Combination Deletion Forbidden",
            conditions          => \@conditionsUsingCombination,
            combination_id      => $combination_id,
            cluster_id          => $cluster_id,
        }
    }
};



get '/extclusters/:extclusterid/clustermetrics/combinations/new' => sub {
    
   my $cluster_id    = params->{extclusterid} || 0;

    my @clustermetrics = Clustermetric->search(hash=>{'clustermetric_service_provider_id' => (params->{extclusterid})});
    my @clustermetrics_param;
    foreach my $clustermetric (@clustermetrics){
        my $hash = {
            id           => $clustermetric->getAttr(name => 'clustermetric_id'),
            label        => $clustermetric->toString(),
        };
            push @clustermetrics_param, $hash;
    }

    template 'clustermetric_combination_new', {
        title_page     => "Clustermetric creation",
        cluster_id     => param('extclusterid'),
        clustermetrics => \@clustermetrics_param,
        
    };
};


post '/extclusters/:extclusterid/clustermetrics/combinations/new' => sub {
    my $params = {
        aggregate_combination_service_provider_id      => param('extclusterid'),
        aggregate_combination_formula => param('formula'),
    };
   my $cm = AggregateCombination->new(%$params);
   my $var = param('extclusterid');
   redirect("/architectures/extclusters/$var/clustermetrics/combinations");
};

# -----------------------------------------------------------------------------#
# ------------------- CLUSTERMETRIC COMBINATION CONDITIONS --------------------#
# -----------------------------------------------------------------------------#

get '/extclusters/:extclusterid/clustermetrics/combinations/conditions' => sub {
    my @clustermetric_conditions = AggregateCondition->search(hash=>{'aggregate_condition_service_provider_id' => params->{extclusterid}});
    
    
    my @clustermetric_conditions_param;
    foreach my $clustermetric_condition (@clustermetric_conditions){
        my $hash = {
            id           => $clustermetric_condition->getAttr(name => 'aggregate_condition_id'),
            label        => $clustermetric_condition->toString(),
        };
        push @clustermetric_conditions_param, $hash;
    }
    
    template 'clustermetric_combination_conditions', {
        title_page      => "ClusterMetrics Conditions Overview",
        conditions      => \@clustermetric_conditions_param,
        cluster_id      => params->{extclusterid},
    };
};

get '/extclusters/:extclusterid/clustermetrics/combinations/conditions/:conditionid/delete' => sub {
    
    my $condition_id   =  params->{conditionid};
    my $cluster_id     =  params->{extclusterid};
    
    my $condition = AggregateCondition->get('id' => $condition_id);
    
    my @rules = AggregateRule->search(hash=>{});
    
    my @rulesUsingCondition;
    
    # Check if the condition is not used by a role to delete it
    foreach my $rule (@rules) {
       
       my $id = $rule->getAttr(name => 'aggregate_rule_id');
       
       if($rule->isCombinationDependant($condition_id)){
            push @rulesUsingCondition,$id;
        }
    }
    if( (scalar @rulesUsingCondition) eq 0) {
        $condition->delete();
        redirect("/architectures/extclusters/$cluster_id/clustermetrics/combinations/conditions");
    }else{
        template 'clustermetric_condition_deletion_forbidden', {
            title_page         => "Clustermetric condition Deletion Forbidden",
            rules              => \@rulesUsingCondition,
            condition_id       => $condition_id,
            cluster_id         => $cluster_id,
        }
    }
};

post '/extclusters/:extclusterid/clustermetrics/combinations/conditions/new' => sub {
    my $comparatorHash = 
    {
        "le" => "<",
        "lt" => "<=",
        "eq" => "==",
        "gt" => ">",
        "ge" => ">=",
    };
    
    my $params = {
        aggregate_condition_service_provider_id      => param('extclusterid'),
        aggregate_combination_id => param('combinationid'),
        comparator               => $comparatorHash->{param('comparator')},
        threshold                => param('threshold'),
        state                    => 'enabled',
        time_limit               =>  'NULL',
    };
    my $aggregate_condition = AggregateCondition->new(%$params);
    my $var = param('extclusterid');    
    
    if(defined param('rule')){
       my $params_rule = {
            aggregate_rule_service_provider_id => param('extclusterid'),
            aggregate_rule_formula   => 'id'.($aggregate_condition->getAttr(name => 'aggregate_condition_id')),
            aggregate_rule_state     => 'disabled',
            aggregate_rule_action_id => $aggregate_condition->getAttr(name => 'aggregate_condition_id'),
        };
        my $aggregate_rule = AggregateRule->new(%$params_rule);
        redirect("/architectures/extclusters/$var/clustermetrics/combinations/conditions/rules");
    }else{
        redirect("/architectures/extclusters/$var/clustermetrics/combinations/conditions");
    }
};

get '/extclusters/:extclusterid/clustermetrics/combinations/conditions/new' => sub {
    
   my $cluster_id    = params->{extclusterid} || 0;
    
    my @combinations = AggregateCombination->search(hash => {});
    
    my @combinationsInput;
    
    foreach my $combination (@combinations){
        my $hash = {
            id     => $combination->getAttr(name => 'aggregate_combination_id'),
            label  => $combination->toString(),
        };
        push @combinationsInput, $hash;
    }
    template 'clustermetric_condition_new', {
        title_page    => "Condition creation",
        combinations  => \@combinationsInput,
        cluster_id    => param('extclusterid'),
    };
};

# ----------------------------------------------------------------------------#
# ---------------------CLUSTER METRIC RULES ----------------------------------#
#----------- -----------------------------------------------------------------#


get '/extclusters/:extclusterid/clustermetrics/combinations/conditions/rules' => sub {
    my @enabled_aggregaterules = AggregateRule->getRules(state => 'enabled', service_provider_id => params->{extclusterid});


#  my @enabled_aggregaterules = AggregateRule->search(hash => {aggregate_rule_state => 'enabled'});
  my @rules;
  foreach my $aggregate_rule (@enabled_aggregaterules) {
    my $label = $aggregate_rule->getAttr(name => 'aggregate_rule_label');
    
    if(not defined $label) {
        $label = $aggregate_rule->toString();
    }
    
    my $hash = {
        id        => $aggregate_rule->getAttr(name => 'aggregate_rule_id'),
        formula   => $aggregate_rule->toString(),
        last_eval => $aggregate_rule->getAttr(name => 'aggregate_rule_last_eval'),
        label     => $label,

    };
    push @rules, $hash;
  }
  
  template 'clustermetric_rules', {
        title_page      => "Enabled Rules Overview",
        rules      => \@rules,
        status     => 'enabled',
        cluster_id => param('extclusterid'),
        
  };
};



get '/extclusters/:extclusterid/clustermetrics/combinations/conditions/rules/disabled' => sub {
  my @disabled_aggregaterules = AggregateRule->getRules(state => 'disabled', service_provider_id => params->{extclusterid});
  #my @disabled_aggregaterules = AggregateRule->search(hash => {aggregate_rule_state => 'disabled'});
  my @disabled_rules;
  foreach my $aggregate_rule (@disabled_aggregaterules) {
      
    my $label = $aggregate_rule->getAttr(name => 'aggregate_rule_label');
    
    if(not defined $label) {
        $label = $aggregate_rule->toString();
    }
    
   
    my $hash = {
      id => $aggregate_rule->getAttr(name => 'aggregate_rule_id'),
      formula => $aggregate_rule->toString(),
      last_eval => -1,
      label     => $label,
      
    };
    push @disabled_rules, $hash;
  }
  
  template 'clustermetric_rules', {
        title_page      => "Disabled Rules Overview",
        rules   => \@disabled_rules,
        status  => "disabled",
        cluster_id => param('extclusterid'),
  };
    
};

get '/extclusters/:extclusterid/clustermetrics/combinations/conditions/rules/tdisabled' => sub {
  my @tdisabled_aggregaterules = AggregateRule->getRules(state => 'disabled_temp', service_provider_id => params->{extclusterid});
  #my @tdisabled_aggregaterules = AggregateRule->search(hash => {aggregate_rule_state => 'disabled_temp'});
  my @tdisabled_rules;
  foreach my $aggregate_rule (@tdisabled_aggregaterules) {
          my $label = $aggregate_rule->getAttr(name => 'aggregate_rule_label');
    
    if(not defined $label) {
        $label = $aggregate_rule->toString();
    }
    
    my $hash = {
      id        => $aggregate_rule->getAttr(name => 'aggregate_rule_id'),
      formula   => $aggregate_rule->toString(),
      last_eval => -1,
      time      => $aggregate_rule->getAttr(name => 'aggregate_rule_timestamp') - time(),
      label     => $label,
      
    };
    push @tdisabled_rules, $hash;
  }  
  
  template 'clustermetric_rules', {
        title_page      => "Temporarily Disabled Rules Overview",
        rules           => \@tdisabled_rules,
        status          => 'tdisabled',
        cluster_id      => param('extclusterid'),
  };
};



get '/extclusters/:extclusterid/clustermetrics/combinations/conditions/rules/enabled' => sub {
    
    redirect('/architectures/extclusters/'.param('extclusterid').'/clustermetrics/combinations/conditions/rules');
};



get '/extclusters/:extclusterid/clustermetrics/combinations/conditions/rules/:ruleid/enable' => sub {
    my $aggregateRule = AggregateRule->get('id' => params->{ruleid});
    $aggregateRule->enable();
    redirect('/architectures/extclusters/'.param('extclusterid').'/clustermetrics/combinations/conditions/rules');
};

get '/extclusters/:extclusterid/clustermetrics/combinations/conditions/rules/:ruleid/disable' => sub {
    my $aggregateRule = AggregateRule->get('id' => params->{ruleid});
    $aggregateRule->disable();
    redirect('/architectures/extclusters/'.param('extclusterid').'/clustermetrics/combinations/conditions/rules');
};

get '/extclusters/:extclusterid/clustermetrics/combinations/conditions/rules/:ruleid/tdisable' => sub {
    my $aggregateRule = AggregateRule->get('id' => params->{ruleid});
    $aggregateRule->disableTemporarily(length => 120);
    redirect('/architectures/extclusters/'.param('extclusterid').'/clustermetrics/combinations/conditions/rules');
};

get '/extclusters/:extclusterid/clustermetrics/combinations/conditions/rules/:ruleid/tdisable' => sub {
    my $aggregateRule = AggregateRule->get('id' => params->{ruleid});
    $aggregateRule->disableTemporarily(length => 120);
    redirect('/architectures/extclusters/'.param('extclusterid').'/clustermetrics/combinations/conditions/rules');
};

get '/extclusters/:extclusterid/clustermetrics/combinations/conditions/rules/:ruleid/details' => sub {

    my $rule_id      = param('ruleid');
    my $rule         = AggregateRule->get('id' => $rule_id);
    my $cluster_id   = params->{extclusterid} || 0;
    my $cluster      = Entity::ServiceProvider::Outside::Externalcluster->get('id'=>$cluster_id);
    #my $cluster_name = $cluster->getNode(externalnode_id=>$cluster_id);
    my $cluster_name = $cluster->getAttr(name => 'externalcluster_name');
    
    my @conditions;

    my @condition_insts = AggregateCondition->search(hash => {});
    
    foreach my $condition_inst (@condition_insts){
        my $hash = {
            label => $condition_inst->toString(),
            id    => $condition_inst->getAttr('name' => 'aggregate_condition_id'),
        };
        
        push @conditions, $hash;
    }
    
    my $rule_param = {
        id        => $rule_id,
        formula   => $rule->getAttr('name' => 'aggregate_rule_formula'),
        string    => $rule->toString(),
        state     => $rule->getAttr('name' => 'aggregate_rule_state'),
        label     => $rule->getAttr('name' => 'aggregate_rule_label'),
        action_id => $rule->getAttr('name' => 'aggregate_rule_action_id'),
    };
    
    template 'clustermetric_rules_details', {
        title_page     => "Rule details",
        cluster_id     => $cluster_id,
        cluster_name   => $cluster_name,
        rule           => $rule_param,
        conditions     => \@conditions,
        clustermetric  => 1,
    };
};



post '/extclusters/:extclusterid/clustermetrics/combinations/conditions/rules/:ruleid/edit' => sub {
    my $rule    = AggregateRule->get('id' => param('ruleid'));
    my $checker = $rule->checkFormula(formula => param('formula'));
    if($checker->{value} == 1) {
        $rule->setAttr(name => 'aggregate_rule_formula',   value => param('formula'));
        $rule->setAttr(name => 'aggregate_rule_action_id', value => param('action'));
        $rule->setAttr(name => 'aggregate_rule_state',     value => param('state'));
        $rule->setAttr(name => 'aggregate_rule_label',     value => param('label'));
        $rule->save();
        redirect('/architectures/extclusters/'.param('extclusterid').'/clustermetrics/combinations/conditions/rules');        
    }else {
        my $adm = Administrator->new();
        $adm->addMessage(from => 'Monitoring', level => 'error', content => 'Wrong formula, unkown condition id'."$checker->{attribute}");
        redirect('/architectures/extclusters/'.param('extclusterid').'/clustermetrics/combinations/conditions/rules/'.param('ruleid').'/details');        
    }
};

get '/extclusters/:extclusterid/clustermetrics/combinations/conditions/rules/new' => sub {

    my $cluster_id   = params->{extclusterid} || 0;
    my $cluster      = Entity::ServiceProvider::Outside::Externalcluster->get('id'=>$cluster_id);
    my $cluster_name = $cluster->getAttr(name => 'externalcluster_name');
    
    my @conditions   = AggregateCondition->search(hash=>{aggregate_condition_service_provider_id => $cluster_id});
    my @condition_params;
    foreach my $condition (@conditions){
        my $hash = {
            id           => $condition->getAttr(name => 'aggregate_condition_id'),
            label        => $condition->toString(),
        };
            push @condition_params, $hash;
    }
    
    template 'clustermetric_rules_details', {
        title_page    => "Rule creation",
        cluster_id    => $cluster_id,
        cluster_name  => $cluster_name,    
        conditions    => \@condition_params,
        clustermetric => 1,
    };
};

post '/extclusters/:extclusterid/clustermetrics/combinations/conditions/rules/new' => sub {

    my $checker = AggregateRule->checkFormula(formula => param('formula'));
    if($checker->{value} == 1) {
        my $params = {
            aggregate_rule_service_provider_id => param('extclusterid'),
            aggregate_rule_formula             => param('formula'),
            aggregate_rule_action_id           => param('action'),
            aggregate_rule_state               => param('state'),
            aggregate_rule_label               => param('label'),
        };
        my $cm = AggregateRule->new(%$params);
        redirect('/architectures/extclusters/'.param('extclusterid').'/clustermetrics/combinations/conditions/rules');
    }else {
        my $adm = Administrator->new();
        $adm->addMessage(from => 'Monitoring', level => 'error', content => 'Wrong formula, unkown condition id'."$checker->{attribute}");
        redirect('/architectures/extclusters/'.param('extclusterid').'/clustermetrics/combinations/conditions/rules/new');
    }
    
};

get '/extclusters/:extclusterid/clustermetrics/combinations/conditions/rules/:ruleid/delete' => sub {
   
    my $rule_id     =  params->{ruleid};
    my $cluster_id  =  params->{extclusterid};
    
    my $rule = AggregateRule->get('id' => $rule_id);
    
    $rule->delete();
    redirect("/architectures/extclusters/$cluster_id/clustermetrics/combinations/conditions/rules");
};

# -----------------------------------------------------------------------------#
# -------------------------- NODE METRICS COMBINATIONS-------------------------#
# -----------------------------------------------------------------------------#

get '/extclusters/:extclusterid/nodemetrics/combinations' => sub {
    
    #my @nodemetric_combinations = AggregateCombination->getAllTheCombinationsRelativeToAClusterId(param('extclusterid'));
    my @nodemetric_combinations = NodemetricCombination->search(hash=>{});
    
    my @nodemetric_combinations_param;
    foreach my $nodemetric_combination (@nodemetric_combinations){
        my $hash = {
            id           => $nodemetric_combination->getAttr(name => 'nodemetric_combination_id'),
            label        => $nodemetric_combination->toString(),
        };
        push @nodemetric_combinations_param, $hash;
        
    }
    
    template 'nodemetric_combinations', {
        title_page      => "nodemetrics Combinations Overview",
        combinations  => \@nodemetric_combinations_param,
        cluster_id      => params->{extclusterid},
    };
};

get '/extclusters/:extclusterid/nodemetrics/combinations/:combinationid/delete' => sub {
    
    my $combination_id =  params->{combinationid};
    my $cluster_id     =  params->{extclusterid};
     
    my $combination = NodemetricCombination->get('id' => $combination_id);
    
    #When destroying a combination
    #Check if it is not used in combinations
    my @conditions  = NodemetricCondition->search(hash=>{});
    
    my @conditionsUsingCombination;
    foreach my $condition (@conditions) {
        if($condition->getAttr(name => 'nodemetric_condition_combination_id') eq $combination_id){
            push @conditionsUsingCombination,$condition->getAttr(name => 'nodemetric_condition_id');
        }
    }

    if( (scalar @conditionsUsingCombination) eq 0) {
        $combination->delete();
        redirect("/architectures/extclusters/$cluster_id/nodemetrics/combinations");
    }else{
        template 'nodemetric_combination_error', {
            title_page          => "nodemetric Combination Deletion Forbidden",
            error_type          =>  'DELETION',
            conditions          => \@conditionsUsingCombination,
            combination_id      => $combination_id,
            cluster_id          => $cluster_id,
        }
    }
};



get '/extclusters/:extclusterid/nodemetrics/combinations/new' => sub {
    
   my $cluster_id    = params->{extclusterid} || 0;
    
    my $adm    = Administrator->new();
    my $scom_indicatorset = $adm->{'manager'}{'monitor'}->getSetDesc( set_name => 'scom' );
    my @indicators;
    
    foreach my $indicator (@{$scom_indicatorset->{ds}}){
        my $hash = {
            id     => $indicator->{id},
            label  => $indicator->{label},
        };
        push @indicators, $hash;
    }
    template 'nodemetric_combination_new', {
        title_page     => "Nodemetric combination creation",
        cluster_id     => param('extclusterid'),
        indicators     => \@indicators,
    };
};


post '/extclusters/:extclusterid/nodemetrics/combinations/new' => sub {
    
    my $formula = param('formula');
    
    my @unknownId = NodemetricCombination->checkFormula(formula => $formula);

    if (scalar @unknownId){
        
        template 'nodemetric_combination_error', {
            title_page     => "Nodemetric combination creation",
            error_type     => 'CREATION',
            cluster_id     => param('extclusterid'),
            indicator_ids  => \@unknownId,
        };
        
    }else{
        my $params = {
            nodemetric_combination_formula => param('formula'),
        };
        my $cm = NodemetricCombination->new(%$params);
        my $var = param('extclusterid');
        redirect("/architectures/extclusters/$var/nodemetrics/combinations");
    };
};


# -----------------------------------------------------------------------------#
# ---------------------------- NODEMETRIC CONDITIONS --------------------------#
# -----------------------------------------------------------------------------#

get '/extclusters/:extclusterid/nodemetrics/conditions' => sub {
    my @nodemetric_conditions = NodemetricCondition->search(hash=>{});
    
    my @nodemetric_conditions_param;
    foreach my $nodemetric_condition (@nodemetric_conditions){
        my $hash = {
            id           => $nodemetric_condition->getAttr(name => 'nodemetric_condition_id'),
            label        => $nodemetric_condition->toString(),
        };
        push @nodemetric_conditions_param, $hash;
    }
    
    template 'nodemetric_combination_conditions', {
        title_page      => "nodemetrics Conditions Overview",
        conditions      => \@nodemetric_conditions_param,
        cluster_id      => params->{extclusterid},
    };
};

get '/extclusters/:extclusterid/nodemetrics/conditions/:conditionid/delete' => sub {
    
    my $condition_id   =  params->{conditionid};
    my $cluster_id     =  params->{extclusterid};
    
    my $condition = NodemetricCondition->get('id' => $condition_id);
    
    my @rules = NodemetricRule->search(hash=>{});
    
    my @rulesUsingCondition;
    
    # Check if the condition is not used by a role to delete it
    foreach my $rule (@rules) {
       
       my $id = $rule->getAttr(name => 'nodemetric_rule_id');
       
       if($rule->isCombinationDependant($condition_id)){
            push @rulesUsingCondition,$id;
        }
    }
    if( (scalar @rulesUsingCondition) eq 0) {
        $condition->delete();
        redirect("/architectures/extclusters/$cluster_id/nodemetrics/conditions");
    }else{
        template 'nodemetric_condition_deletion_forbidden', {
            title_page         => "Nodemetric condition Deletion Forbidden",
            rules              => \@rulesUsingCondition,
            condition_id       => $condition_id,
            cluster_id         => $cluster_id,
        }
    }
};

post '/extclusters/:extclusterid/nodemetrics/conditions/new' => sub {
    my $comparatorHash = 
    {
        "le" => "<",
        "lt" => "<=",
        "eq" => "==",
        "gt" => ">",
        "ge" => ">=",
    };
    
    my $params = {
        nodemetric_condition_combination_id => param('combinationid'),
        nodemetric_condition_comparator     => $comparatorHash->{param('comparator')},
        nodemetric_condition_threshold      => param('threshold'),
    };
    my $nodemetric_condition = NodemetricCondition->new(%$params);
    my $var = param('extclusterid');    
    
    if(defined param('rule')){
       my $params_rule = {
            nodemetric_rule_service_provider_id => param('extclusterid'),
            nodemetric_rule_formula   => 'id'.($nodemetric_condition->getAttr(name => 'nodemetric_condition_id')),
            nodemetric_rule_state     => 'disabled',
            nodemetric_rule_action_id => $nodemetric_condition->getAttr(name => 'nodemetric_condition_id'),
        };
        my $nodemetric_rule = NodemetricRule->new(%$params_rule);
        redirect("/architectures/extclusters/$var/externalnodes/rules");
    }else{
        redirect("/architectures/extclusters/$var/nodemetrics/conditions");
    }
};

get '/extclusters/:extclusterid/nodemetrics/conditions/new' => sub {
    
   my $cluster_id    = params->{extclusterid} || 0;
    
    my @combinations = NodemetricCombination->search(hash => {});
    
    my @combinationsInput;
    
    foreach my $combination (@combinations){
        my $hash = {
            id     => $combination->getAttr(name => 'nodemetric_combination_id'),
            label  => $combination->toString(),
        };
        push @combinationsInput, $hash;
    }
    template 'nodemetric_condition_new', {
        title_page    => "Condition creation",
        combinations  => \@combinationsInput,
        cluster_id    => param('extclusterid'),
    };
};

# ----------------------------------------------------------------------------#
# ------------------------NODE METRIC RULES ----------------------------------#
#----------- -----------------------------------------------------------------#

get '/extclusters/:extclusterid/nodemetrics/rules' => sub {
    my $externalcluster_id = param('extclusterid');
    my @nodemetric_rules   = NodemetricRule->search(hash => {nodemetric_rule_service_provider_id => $externalcluster_id});
    
    my @rules;
    
    foreach my $rule (@nodemetric_rules){
        my $hash = {
            id         => $rule->getAttr(name => 'nodemetric_rule_id'),
            formula    => $rule->toString(),
            label      => $rule->getAttr(name => 'nodemetric_rule_label'),
        };
        push @rules, $hash;
    } 
    
    my $extclu = Entity::ServiceProvider::Outside::Externalcluster->get('id'=>$externalcluster_id);
    template 'nodemetric_rules', {
        title_page      => "Node Metric Rules Overview",
        rules           => \@rules,
        cluster_id      => $externalcluster_id,
        cluster_name    => $extclu->getAttr(name => 'externalcluster_name'),
    };
};

get '/extclusters/:extclusterid/externalnodes/:extnodeid/rules' => sub {
    my $externalnode_id    = param('extnodeid');
    my $externalcluster_id = param('extclusterid');
    
    my @nodemetric_rules = NodemetricRule->search(
                                hash => {
                                    nodemetric_rule_state => 'enabled',
                                }
                           );
    
    my @rules;
    
    foreach my $rule (@nodemetric_rules){
        my $isVerified = $rule->isVerifiedForANode(
            externalcluster_id => $externalcluster_id,
            externalnode_id    => $externalnode_id,
        );
        
        my $hash = {
            id         => $rule->getAttr(name => 'nodemetric_rule_id'),
            isVerified => $isVerified,
            formula      => $rule->toString(),
        };
        
        push @rules, $hash;
    } 
    

    my $extclu = Entity::ServiceProvider::Outside::Externalcluster->get('id'=>$externalcluster_id);
    my $node = $extclu->getNode(externalnode_id=>$externalnode_id);
    template 'nodemetric_rules', {
        title_page      => "Node Metric Rules Overview",
        rules           => \@rules,
        externalnode_id => $externalnode_id,
        cluster_id      => $externalcluster_id,
        cluster_name    => $extclu->getAttr(name => 'externalcluster_name'),
        host_name       => $node->{hostname},
    };
};


get '/extclusters/:extclusterid/nodemetrics/rules/new' => sub {
    
    my $cluster_id   = params->{extclusterid} || 0;
    my $cluster      = Entity::ServiceProvider::Outside::Externalcluster->get('id'=>$cluster_id);
    my $cluster_name = $cluster->getAttr(name => 'externalcluster_name');
    
    my @conditions = NodemetricCondition->search(hash=>{});
    my @condition_params;
    foreach my $condition (@conditions){
        my $hash = {
            id           => $condition->getAttr(name => 'nodemetric_condition_id'),
            label        => $condition->toString(),
        };
            push @condition_params, $hash;
    }
    
    template 'clustermetric_rules_details', {
        title_page    => "Rule creation",
        cluster_id    => $cluster_id,
        cluster_name  => $cluster_name,    
        conditions    => \@condition_params,
    };
};


post '/extclusters/:extclusterid/nodemetrics/rules/new' => sub {
 
    my $checker = NodemetricRule->checkFormula(formula => param('formula'));
    if($checker->{value} == 1) {
        my $params = {
            nodemetric_rule_service_provider_id => param('extclusterid'),
            nodemetric_rule_formula             => param('formula'),
            nodemetric_rule_action_id           => param('action'),
            nodemetric_rule_state               => param('state'),
            nodemetric_rule_label               => param('label'),
        };
        my $cm = NodemetricRule->new(%$params);
        redirect('/architectures/extclusters/'.param('extclusterid').'/nodemetrics/rules');
    }else {
        my $adm = Administrator->new();
        $adm->addMessage(from => 'Monitoring', level => 'error', content => 'Wrong formula, unkown condition id'."$checker->{attribute}");
        redirect('/architectures/extclusters/'.param('extclusterid').'/nodemetrics/rules/new');
    }
    
};


get '/extclusters/:extclusterid/nodemetrics/rules/:ruleid/details' => sub {
    my $rule_id      = param('ruleid');
    my $rule         = NodemetricRule->get('id' => $rule_id);
    my $cluster_id   = params->{extclusterid} || 0;
    my $cluster      = Entity::ServiceProvider::Outside::Externalcluster->get('id'=>$cluster_id);
    #my $cluster_name = $cluster->getNode(externalnode_id=>$cluster_id);
    my $cluster_name = $cluster->getAttr(name => 'externalcluster_name');
    
    my @conditions;

    my @condition_insts = NodemetricCondition->search(hash => {});
    
    foreach my $condition_inst (@condition_insts){
        my $hash = {
            label => $condition_inst->toString(),
            id    => $condition_inst->getAttr('name' => 'nodemetric_condition_id'),
        };
        
        push @conditions, $hash;
    }
    
    my $rule_param = {
        id        => $rule_id,
        formula   => $rule->getAttr('name' => 'nodemetric_rule_formula'),
        string    => $rule->toString(),
        state     => $rule->getAttr('name' => 'nodemetric_rule_state'),
        label     => $rule->getAttr('name' => 'nodemetric_rule_label'),
        action_id => $rule->getAttr('name' => 'nodemetric_rule_action_id'),
    };
    
    template 'clustermetric_rules_details', {
        title_page    => "Rule details",
        cluster_id    => $cluster_id,
        cluster_name  => $cluster_name,
        rule          => $rule_param,
        conditions    => \@conditions,
    };
};

post '/extclusters/:extclusterid/nodemetrics/rules/:ruleid/edit' => sub {
    my $rule    = NodemetricRule->get('id' => param('ruleid'));
    my $checker = $rule->checkFormula(formula => param('formula'));
    if($checker->{value} == 1) {
        $rule->setAttr(name => 'nodemetric_rule_formula',   value => param('formula'));
        $rule->setAttr(name => 'nodemetric_rule_action_id', value => param('action'));
        $rule->setAttr(name => 'nodemetric_rule_state',     value => param('state'));
        $rule->setAttr(name => 'nodemetric_rule_label',     value => param('label'));
        $rule->save();
        redirect('/architectures/extclusters/'.param('extclusterid').'/nodemetrics/rules/'.param('ruleid').'/details');        
    }else {
        my $adm = Administrator->new();
        $adm->addMessage(from => 'Monitoring', level => 'error', content => 'Wrong formula, unkown condition id'."$checker->{attribute}");
        redirect('/architectures/extclusters/'.param('extclusterid').'/nodemetrics/rules/'.param('ruleid').'/details');        
    }
};


get '/extclusters/:extclusterid/nodemetrics/rules/:ruleid/delete' => sub {
   
    my $rule_id     =  params->{ruleid};
    my $cluster_id  =  params->{extclusterid};
    
    my $rule = NodemetricRule->get('id' => $rule_id);
    
    $rule->delete();
    redirect("/architectures/extclusters/$cluster_id/nodemetrics/rules");
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
	my $template_config = shift;
	my $cluster_id = $template_config->{'cluster_id'};
	my %errors;
	my @combinations;
	my @clustermetric_combinations;
	
	eval {
		#@aggregate_combinations = AggregateCombination->getAllTheCombinationsRelativeToAClusterId($cluster_id);
        @clustermetric_combinations = AggregateCombination->search(hash=>{'aggregate_combination_service_provider_id' => $cluster_id});

	};
	if ($@) {
		my $error = "$@";
		$log->error($error);
		$template_config->{'errors'}{'combinations'} = $error;
		return %$template_config;
	}elsif (scalar(@clustermetric_combinations) == 0){
		my $error = 'No combination could be found for this external cluster';
		$log->error($error);
		$template_config->{'errors'}{'combinations'} = $error;
		return %$template_config;
	}else{
		 for my $combi (@clustermetric_combinations){
			my %combination;
			$combination{'id'} = $combi->getAttr(name => 'aggregate_combination_id');
			$combination{'label'} = $combi->toString();
			push @combinations, \%combination;
		}
	$template_config->{'combinations'} = \@combinations;
	# $log->info('combination list for external cluster '.$template_config->{'cluster_id'}.' '.Dumper($template_config->{'combinations'}));
	return %$template_config;
	}
}

#get '/rules/:ruleid/details' => sub {
#    my $aggregateRule = AggregateRule->get('id' => params->{ruleid});
#    
#    my %rule;
#     $rule{formula} = $aggregateRule->getAttr(name => 'aggregate_rule_formula')
#    
#      template 'clustermetric_rules_details', {
#            title_page      => "Rule Details",
#            rule            => $rule;
#      };
#
#};
1;
