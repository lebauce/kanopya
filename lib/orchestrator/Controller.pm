package Controller;

use strict;
use warnings;
use Data::Dumper;
use Administrator;
use XML::Simple;
use Entity::Cluster;
use CapacityPlanning::IncrementalSearch;
use Model::MVAModel;


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
	
	return {nb_nodes => 1, mpl => 300};	
}

sub getWorkload {
	my $self = shift;
    my %args = @_;

	my $cluster = $args{cluster};

	my %workload_class = ( 	visit_ratio => [1],
							service_time => [1],
							delay => [1],
							think_time => 2 );

	my $workload_amount = 301;
		
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

	my @clusters = Entity::Cluster->getClusters(hash => {});
	for my $cluster (@clusters) {
		print "CLUSTER: " . $cluster->getAttr('name' => 'cluster_name') . "\n ";
		#if($cluster->getAttr('name' => 'active')) 
		{
			# TODO get controller/orchestration conf for this cluster and init this controller
			# $cluster->getCapPlan(); $cluster->getModel()
			$self->manageCluster( cluster => $cluster );
		}	
	}
	
}

1;