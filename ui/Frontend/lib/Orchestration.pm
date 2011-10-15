package Orchestration;

use Dancer ':syntax'; 

use Log::Log4perl "get_logger";

my $log = get_logger("administrator");

prefix '/architectures';

sub _actionTranslate {
    my %args = @_;
    
    my %map = ("add_node" => "Add node", "remove_node" => "Remove node");
    while ( my ($k, $v) = each ( %map ) ) {
        return $v if $k eq $args{action};
        return $k if $v eq $args{action};
    }
    return "none";
}

get '/clusters/:clusterid/orchestration' => sub {
    my $cluster_id = params->{'clusterid'};

    my $adm    = Administrator->new();
    # Build var choice list of all collected set
    my $sets = $adm->{manager}{monitor}->getCollectedSets( cluster_id => $cluster_id );
    my @choices = ();
    foreach my $set (@$sets) {
        push( @choices, map { "$set->{label}:" . $_->{label} } @{ $set->{ds} } );
    }
    my $var_choices = join ",", @choices;
    
    my @rules = ();
    my $rules_manager = $adm->{manager}->{rules};
    my $cluster_rules = $rules_manager->getClusterRules( cluster_id => $cluster_id );
    my $op_id = 0;
    foreach my $rule (@$cluster_rules) {
        my $condition_tree = $rule->{condition_tree};

        my @conditions = ();
        $op_id++;
        my $bin_op;
        foreach my $cond (@$condition_tree) {
            if ( ref $cond eq 'HASH' ) {
                push @conditions, { var => $cond->{var},
                                    time_laps => $cond->{time_laps},
                                    inf => $cond->{operator} eq 'inf',
                                    value => $cond->{value},
                                    var_choices => $var_choices,                    
                                    op_id => $op_id,
                                };
            } else {
                $bin_op = {'|' => 'or', '&' => 'and'}->{$cond};
            }
        }
        
        $conditions[0]{master_row} = 1;
        $conditions[0]{bin_op} = $bin_op if (defined $bin_op);
        $conditions[0]{action} = _actionTranslate( action => $rule->{action} );
        $conditions[0]{span} = scalar @conditions;
        
        push @rules, { conditions => \@conditions };
    }
    
    my @optim_conditions = ();
    my $optim_condition_tree = $rules_manager->getClusterOptimConditions( cluster_id => $cluster_id );
    foreach my $cond (@$optim_condition_tree) {
            if ( ref $cond eq 'HASH' ) {
                push @optim_conditions, { var => $cond->{var},
                                    time_laps => $cond->{time_laps},
                                    inf => $cond->{operator} eq 'inf',
                                    value => $cond->{value},
                                    var_choices => $var_choices,                    
                                    op_id => 0,
                                };
            } else {
                #$bin_op = {'|' => 'or', '&' => 'and'}->{$cond};
            }
        }
    
#    # SLA
#    my $qos_constraints = $rules_manager->getClusterQoSConstraints( cluster_id => $cluster_id );
#    $tmpl->param('QOS_CONSTRAINTS_LATENCY' => $qos_constraints->{max_latency});
#    $tmpl->param('QOS_CONSTRAINTS_ABORT_RATE' => $qos_constraints->{max_abort_rate} * 100);
#
#    # Model parameters
#    my $workload_characteristic = $rules_manager->getClusterModelParameters( cluster_id => $cluster_id );
#    $tmpl->param('WORKLOAD_VISIT_RATIO' => $workload_characteristic->{visit_ratio});
#    $tmpl->param('WORKLOAD_SERVICE_TIME' => $workload_characteristic->{service_time} * 1000);
#    $tmpl->param('WORKLOAD_DELAY' => $workload_characteristic->{delay} * 1000);
#    $tmpl->param('WORKLOAD_THINK_TIME' => $workload_characteristic->{think_time} * 1000);
    

    template 'view_orchestrator_settings', {
        title_page          => 'Orchestrator settings',
        var_choices         => $var_choices,
        optim_conditions    => \@optim_conditions,
        rules               => \@rules,
    }
};

get '/clusters/:clusterid/orchestration/save' => sub {
    my $adm    = Administrator->new();
        
    my $cluster_id = params->{'clusterid'};
    my $rules_str = params->{'rules'}; # stringified array of hash
    my $rules = from_json $rules_str;
    
    my $optim_str = params->{'optim_conditions'}; # stringified array of hash
    my $optim_cond = from_json $optim_str;
        
    my $rules_manager = $adm->{manager}->{rules};
    eval {
        $rules_manager->deleteClusterRules( cluster_id => $cluster_id );
        foreach my $rule (@$rules) {
            $rules_manager->addClusterRule( cluster_id => $cluster_id,
                                            condition_tree => (ref $rule->{condition} eq 'ARRAY') ? $rule->{condition} : [$rule->{condition}],
                                            action => _actionTranslate( action => $rule->{action} )
                                            );
        }
        
        $rules_manager->deleteClusterOptimConditions( cluster_id => $cluster_id );
        $rules_manager->addClusterOptimConditions( cluster_id => $cluster_id, condition_tree => $optim_cond );
    };
    if ($@) {
        my $error = $@;
        return "Error while recording rule for cluster $cluster_id\n$error";
    }
    
    return "Rules saved for cluster $cluster_id ";
};

get '/orchestrator/controller/settings/:id' => sub {
    my $cluster_id    = params->{id} || 0;
    my $adm_object    = Administrator->new();
    my $rules_manager = $adm_object->{manager}->{rules};

    my $qos_constraints = $rules_manager->getClusterQoSConstraints( cluster_id => $cluster_id );
    my $workload_characteristic = $rules_manager->getClusterModelParameters( cluster_id => $cluster_id );

    template 'view_controller_settings', {
        title_page                 => 'Controller settings',
        qos_constraints_lantency   => $qos_constraints->{max_latency},
        qos_constraints_abort_rate => $qos_constraints->{max_abort_rate} * 1000,
		workload_visit_ratio => $workload_characteristic->{visit_ratio},
		workload_service_time => $workload_characteristic->{service_time},
		workload_delay => $workload_characteristic->{delay},
		workload_think_time => $workload_characteristic->{think_time},
    };
};

get '/orchestrator/controller/:id' => sub {
    my $cluster_id    = params->{id} || 0;
    my $adm_object    = Administrator->new();
    my $rules_manager = $adm_object->{manager}->{rules};
    my $graph_name_prefix = "cluster$cluster_id" .  "_controller_server_";
	my $graphs = [  { graph => "/graph/" . $graph_name_prefix . "load.png"},
                                { graph => "/graph/" . $graph_name_prefix . "latency.png"},
                                { graph => "/graph/" . $graph_name_prefix . "abortrate.png"},
                                { graph => "/graph/" . $graph_name_prefix . "throughput.png"},
                            ];

    template 'view_controller', {
        title_page => "Cluster - Controller's activity",
		graphs => $graphs,
    };
};

1;
