package Orchestration;

use Dancer ':syntax'; 

use Log::Log4perl "get_logger";

my $log = get_logger("administrator");

prefix '/architectures';

get '/clusters/:clusterid/orchestration' => sub {

    template 'view_orchestrator_settings', {
        title_page                 => 'Orchestrator settings',
    }
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
