#    Copyright © 2011 Hedera Technology SAS
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
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
    
    $self->{config} = XMLin("/opt/kanopya/conf/orchestrator.conf");
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
    
    my $admin = Administrator->new();
    $self->{data_manager} = $admin->{manager}{rules};
    
    $self->{_monitor} = Monitor::Retriever->new( );
    
    $self->{_time_step} = 30;
    
    my $cap_plan = CapacityPlanning::IncrementalSearch->new();
    my $model = Model::MVAModel->new();
    $self->{_model} = $model;
    $cap_plan->setModel(model => $model);
    #$cap_plan->setConstraints(constraints => { max_latency => 22, max_abort_rate => 0.3 } );
    
    $self->{_cap_plan} = $cap_plan;

    
}

sub getControllerRRD {
    my $self = shift;
    my %args = @_;
    
    # RRD

    my $cluster_id = $args{cluster}->getAttr('name' => 'cluster_id');

    my $rrd_file = "/tmp/cluster" . $cluster_id .  "_controller.rrd";
    my $rrd = RRDTool::OO->new( file =>  $rrd_file );
    if ( not -e $rrd_file ) {    
        
        $rrd->create(
                     step        => $self->{_time_step},  # interval
                     data_source => { name    => "workload_amount",
                                       type     => "GAUGE" },
                    data_source => { name      => "latency",
                                       type     => "GAUGE" },                
                      data_source => { name    => "abort_rate",
                                       type      => "GAUGE" },
                    data_source => { name      => "throughput",
                                       type      => "GAUGE" },
                     archive     => { rows      => 500 }
                     );
    }
    
    return $rrd;
}

sub getClusterConf {
    my $self = shift;
    my %args = @_;

    my $cluster = $args{cluster};
    
    return {nb_nodes => 1, mpl => 1500};    
}

sub getWorkload {
    my $self = shift;
    my %args = @_;

    #my $cluster = $args{cluster};

    my $service_info_set = "apache_workers";
    my $load_metric = "BusyWorkers";


    my $cluster_name = $args{cluster}->getAttr('name' => 'cluster_name');
    my $cluster_id = $args{cluster}->getAttr('name' => 'cluster_id');

    my $cluster_data_aggreg = $self->{_monitor}->getClusterData( cluster => $cluster_name,
                                                                 set => $service_info_set,
                                                                 time_laps => 30);

    print $cluster_data_aggreg;
        
        
    if (not defined $cluster_data_aggreg->{$load_metric} ) {
#        throw Kanopya::Exception::Internal( error => "Can't get workload amount from monitoring" );    
    }
    
    my $workload_amount = $cluster_data_aggreg->{$load_metric};
    #my $workload_amount = 666;                                                
                                                                
#    my %workload_class = (     visit_ratio => [1],
#                            service_time => [0.002],
#                            delay => [0],
#                            think_time => 0.01 );


    # Get model parameters for this cluster (tier)
    my $cluster_workload_class = $self->{data_manager}->getClusterModelParameters( cluster_id =>  $cluster_id );
    # Compute workload class (i.e we put param for each cluster in an array representing each tiers) to be used by model 
    my %workload_class = (     visit_ratio => [ $cluster_workload_class->{visit_ratio} ],
                            service_time => [ $cluster_workload_class->{service_time} ],
                            delay => [ $cluster_workload_class->{delay} ],
                            think_time => $cluster_workload_class->{think_time} );
    

    return { workload_class => \%workload_class, workload_amount => $workload_amount };
}

sub manageCluster {
    my $self = shift;
    my %args = @_;

    General::checkParams args => \%args, required => ['cluster'];

    my $cluster = $args{cluster};
    my $cluster_id = $args{cluster}->getAttr('name' => 'cluster_id');

    # Refresh qos constraints
    my $constraints = $self->{data_manager}->getClusterQoSConstraints( cluster_id => $cluster_id );
    $self->{_cap_plan}->setConstraints(constraints => $constraints );    


    # TODO get mpl from cluster/component
    my $cluster_conf = $self->getClusterConf( cluster => $cluster );
    my $mpl = $cluster_conf->{mpl};
    
    $self->{_cap_plan}->setSearchSpaceForTiers( search_spaces =>     [ 
                                                                    {    min_node => $cluster->getAttr(name => 'cluster_min_node'), 
                                                                        max_node => $cluster->getAttr(name => 'cluster_max_node'),
                                                                        min_mpl => $mpl,
                                                                        max_mpl => $mpl,}
                                                                    ]
                                                );
    
    $self->{_cap_plan}->setNbTiers( tiers => 1);
    
    my $workload = $self->getWorkload( cluster => $cluster);                        
    
    $self->validateModel( workload => $workload, cluster_conf => $cluster_conf, cluster => $cluster );
    #$self->store( workload => $workload );
    
    
    my $conf = $self->{_cap_plan}->calculate( workload_amount => $workload->{workload_amount}, workload_class => $workload->{workload_class} );
    
    $self->applyConf( conf => $conf, cluster => $cluster);
}

sub validateModel {
    my $self = shift;
    my %args = @_;
    
    my $workload = $args{workload};
    my $cluster_conf = $args{cluster_conf};
    
    my %perf = $self->{_model}->calculate( configuration => { M => 1, AC => [1], LC => [$cluster_conf->{mpl}] },
                                             workload_class => $workload->{workload_class},
                                            workload_amount => $workload->{workload_amount});
                
    my $rrd = $self->getControllerRRD( cluster => $args{cluster} );
    $rrd->update( time => time(), values =>  [     $workload->{workload_amount},
                                                
                                                $perf{latency} * 1000,
                                                
                                                $perf{abort_rate},
                                                
                                                $perf{throughput},
                                                ] );
                                                
    $self->genGraph( cluster => $args{cluster} );
}

sub genGraph {
    my $self = shift;
    my %args = @_;
    
    my $rrd = $self->getControllerRRD( cluster => $args{cluster} );
    
    my $cluster_id = $args{cluster}->getAttr('name' => 'cluster_id');
    my $graph_file_prefix = "cluster$cluster_id" . "_controller_server_";
    
    #
    my %profil_latency_draw = ();
    my %profil_throughput_draw = ();
    my $cluster_public_ips = $args{cluster}->getPublicIps();
    if (defined $cluster_public_ips->[0]) {
        my $profil_rrd_name = "perf_" . $cluster_public_ips->[0]{address} . ".rrd";
        if ( -e "/tmp/$profil_rrd_name") {
            %profil_latency_draw = ( draw => {     type => 'line', color => '0000FF',
                                                dsname  => "latency", legend => "latency(profil)", file => "/tmp/$profil_rrd_name" } );
            %profil_throughput_draw = ( draw => {     type => 'line', color => '0000FF',
                                                    dsname  => "throughput", legend => "throughput(profil)", file => "/tmp/$profil_rrd_name" } );    
        }
    }
        
    # LOAD
    $rrd->graph(
      image          => "/tmp/" . $graph_file_prefix . "load.png",
      vertical_label => 'req',
      start => time() - 3600,
      title => "Load",
      draw    => {
        type      => 'line',
        color      => 'FF0000',
        dsname     => "workload_amount",
          legend    => "load amount (concurrent connections)" },
    );
    
    
    # LATENCY
    
    $rrd->graph(
      image          => "/tmp/" . $graph_file_prefix . "latency.png",
      vertical_label => 'ms',
      start => time() - 3600,
      title => "Latency",
      draw     => {
        type      => 'line',
        color     => '00FF00', 
        dsname  => "latency",
          legend    => "latency"},
      %profil_latency_draw,
    );
    
    $rrd->graph(
      image          => "/tmp/" . $graph_file_prefix . "abortrate.png",
      vertical_label => 'rate',
      start => time() - 3600,
      title => "Abort rate",
      draw     => {
        type      => 'area',
        color     => '00FF00', 
        dsname    => "abort_rate",
          legend     => "abortRate"},
    );

    $rrd->graph(
      image          => "/tmp/" . $graph_file_prefix . "throughput.png",
      vertical_label => 'req/sec',
      start => time() - 3600,
      title => "Throughput",
      draw    => {
        type      => 'area',
        color     => '00FF00', 
        dsname    => "throughput",
          legend    => "throughput"},
      %profil_throughput_draw,
    );
        
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
    
    #$self->{_admin}->addMessage(from => 'Orchestrator', level => 'info', content => "Kanopya Orchestrator started.");
    
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
    
    #$self->{_admin}->addMessage(from => 'Orchestrator', level => 'warning', content => "Kanopya Orchestrator stopped");
}

1;