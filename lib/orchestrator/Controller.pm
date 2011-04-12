package Controller;

use strict;
use warnings;
use Data::Dumper;
use Administrator;
use XML::Simple;

use Monitor::Retriever;
use Entity::Cluster;
use CapacityPlanning::IncrementalSearch;
use Model::MVAModel;

use Log::Log4perl "get_logger";

my $log = get_logger("orchestrator");

sub new {
    my $class = shift;
    my %args = @_;
	
	my $self = {};
	bless $self, $class;
	
	$self->_authenticate();
	
	$self->init();
	
    return $self;
}

sub _authenticate {
	my $self = shift;
	
	$self->{config} = XMLin("/etc/kanopya/orchestrator.conf");
	if ( (! defined $self->{config}{user}{name}) ||
		 (! defined $self->{config}{user}{password}) ) { 
		throw Kanopya::Exception::Internal::IncorrectParam(error => "needs user definition in config file!");
	}
	Administrator::authenticate( login => $self->{config}{user}{name},
								 password => $self->{config}{user}{password});
	return;
}

sub init {
	my $self = shift;
	
	$self->{_monitor} = Monitor::Retriever->new( );
	
	$self->{_time_step} = 30;
	
	my $cap_plan = CapacityPlanning::IncrementalSearch->new();
	my $model = Model::MVAModel->new();

	$cap_plan->setModel(model => $model);
	$cap_plan->setConstraints(constraints => { max_latency => 22, max_abort_rate => 0.3 } );
	
	$self->{_cap_plan} = $cap_plan;
}

sub getClusterConf {
	my $self = shift;
    my %args = @_;

	my $cluster = $args{cluster};
	
	return {nb_nodes => 1, mpl => 150};	
}

sub getWorkload {
	my $self = shift;
    my %args = @_;

	#my $cluster = $args{cluster};

	my $service_info_set = "apache_workers";
	my $load_metric = "BusyWorkers";


	my $cluster_name = $args{cluster}->getAttr('name' => 'cluster_name');

	my $cluster_data_aggreg = $self->{_monitor}->getClusterData( cluster => $cluster_name,
																 set => $service_info_set,
																 time_laps => 30);

	print $cluster_data_aggreg;
		
		
	if (not defined $cluster_data_aggreg->{$load_metric} ) {
		throw Kanopya::Exception::Internal( error => "Can't get workload amount from monitoring" );	
	}
	
	#my $workload_amount = $cluster_data_aggreg->{$load_metric};
							my $workload_amount = 1;												
																
	my %workload_class = ( 	visit_ratio => [1],
							service_time => [1],
							delay => [1],
							think_time => 2 );



	return { workload_class => \%workload_class, workload_amount => $workload_amount };
}

sub manageCluster {
	my $self = shift;
    my %args = @_;

	my $cluster = $args{cluster};
	if (not defined $cluster) {
		throw Kanopya::Exception::Internal::IncorrectParam(error => "Needs named argument 'cluster'");
	}

	# TODO get mpl from cluster/component
	my $cluster_conf = $self->getClusterConf( cluster => $cluster );
	my $mpl = $cluster_conf->{mpl};
	
	$self->{_cap_plan}->setSearchSpaceForTiers( search_spaces => 	[ 
																	{	min_node => $cluster->getAttr(name => 'cluster_min_node'), 
																		max_node => $cluster->getAttr(name => 'cluster_max_node'),
																		min_mpl => $mpl,
																		max_mpl => $mpl,}
																	]
												);
	
    $self->{_cap_plan}->setNbTiers( tiers => 1);
	
	my $workload = $self->getWorkload( cluster => $cluster);						
	my $conf = $self->{_cap_plan}->calculate( workload_amount => $workload->{workload_amount}, workload_class => $workload->{workload_class} );
	
	$self->applyConf( conf => $conf, cluster => $cluster);
}

sub applyConf {
	my $self = shift;
    my %args = @_;

	my $cluster = $args{cluster};
	
	print "############ APPLY conf #####################\n";
	print Dumper $args{conf};
}

sub update {
	my $self = shift;
    my %args = @_;

	my @clusters = Entity::Cluster->getClusters( hash => { cluster_state => 'up' } );
	for my $cluster (@clusters) {
		my $cluster_name = $cluster->getAttr('name' => 'cluster_name');
		print "CLUSTER: " . $cluster_name . "\n ";
		#if($cluster->getAttr('name' => 'active')) 
		{
			# TODO get controller/orchestration conf for this cluster and init this controller
			# $cluster->getCapPlan(); $cluster->getModel()
			eval {
				$self->manageCluster( cluster => $cluster );
			};
			if ($@) {
				my $error = $@;
				$log->error("While orchestrating cluster '$cluster_name' : $error");
			}
		}	
	}
	
}

sub run {
	my $self = shift;
	my $running = shift;
	
	#$self->{_admin}->addMessage(from => 'Orchestrator', level => 'info', content => "Kanopia Orchestrator started.");
	
	while ( $$running ) {

		my $start_time = time();

		$self->update();

		my $update_duration = time() - $start_time;
		$log->info( "Manage duration : $update_duration seconds" );
		if ( $update_duration > $self->{_time_step} ) {
			$log->warn("graphing duration > graphing time step (conf)");
		} else {
			sleep( $self->{_time_step} - $update_duration );
		}

	}
	
	#$self->{_admin}->addMessage(from => 'Orchestrator', level => 'warning', content => "Kanopia Orchestrator stopped");
}

1;