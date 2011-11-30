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
#use Tuning;
use Actuator;


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
    
    $self->{_time_step} = 60; # controller update frequency
    $self->{_time_laps} = 60; # metrics retrieving laps
    
    my $model = Model::MVAModel->new();
    $self->{_model} = $model;
    
    my $cap_plan = CapacityPlanning::IncrementalSearch->new();
    $cap_plan->setModel(model => $model);
    
    # $self->{_modelTuning} = Tuning->new(model=>$model);
    
    #$log->info( "Init constraints in controlleur init\n");
    
    # Set constarints directly on DB
    #my $max_latency    = 0.3;
    #my $max_abort_rate = 0.5;
    #$cap_plan->setConstraints(constraints => { max_latency => $max_latency, max_abort_rate => $max_abort_rate } );
    #$log->info("Constraints max_latency = $max_latency ; max_abort_rate = $max_abort_rate\n");
    
    $self->{_cap_plan} = $cap_plan;

    $self->{_actuator} = Actuator->new();
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
                    data_source => {    name    => "workload_amount",
                                        type    => "GAUGE" },
                    data_source => {    name    => "latency",
                                        type    => "GAUGE" },
                    data_source => {    name    => "abort_rate",
                                        type    => "GAUGE" },
                    data_source => {    name    => "throughput",
                                        type    => "GAUGE" },
                    archive     => {    rows    => 500 }
                    );
    }
    
    return $rrd;
}

sub getClusterConf {
    my $self = shift;
    my %args = @_;

    my $cluster = $args{cluster};
    
    my @hosts = values %{ $cluster->getMotherboards( ) };
    my @in_nodes = grep { $_->getNodeState() =~ '^in' } @hosts; 

    # TODO get mpl from cluster/component
    return {nb_nodes => scalar(@in_nodes), mpl => 1000};
}

sub getWorkload {
    my $self = shift;
    my %args = @_;

    #my $cluster = $args{cluster};

    my $service_info_set = "haproxy_conns"; #"apache_workers";
    my $load_metric = "Active"; #"BusyWorkers";


    my $cluster_name = $args{cluster}->getAttr('name' => 'cluster_name');
    my $cluster_id = $args{cluster}->getAttr('name' => 'cluster_id');

    my $cluster_data_aggreg = $self->{_monitor}->getClusterData( cluster => $cluster_name,
                                                                 set => $service_info_set,
                                                                 time_laps => $self->{_time_laps});

    #print Dumper $cluster_data_aggreg;
        
        
    if (not defined $cluster_data_aggreg->{$load_metric} ) {
#        throw Kanopya::Exception::Internal( error => "Can't get workload amount from monitoring" );    
    }
    
    my $workload_amount = $cluster_data_aggreg->{$load_metric};

    # Get model parameters for this cluster (tier)
    my $cluster_workload_class = $self->{data_manager}->getClusterModelParameters( cluster_id =>  $cluster_id );
    # Compute workload class (i.e we put param for each cluster in an array representing each tiers) to be used by model 
    my %workload_class = (  visit_ratio => [ $cluster_workload_class->{visit_ratio} ],
                            service_time => [ $cluster_workload_class->{service_time} ],
                            delay => [ $cluster_workload_class->{delay} ],
                            think_time => $cluster_workload_class->{think_time} );
    

    return { workload_class => \%workload_class, workload_amount => $workload_amount };
}




=head2 getMonitoredPerfMetrics
    
    Class : Public
    
    Desc : Get the metrics from the monitor. (At the present time, only latency)
    
    Args :
        Cluster : The monitored cluster
    
    Return :
        HASHREF {latency=>float, abort_rate=>float (not implemented yet)); throughput=>(not implemented yet)}
=cut

sub getMonitoredPerfMetrics {
    my $self = shift;
    my %args = @_;
    
    my $time_laps = $args{time_laps} || $self->{_time_laps};
    
    
    my $cluster_name = $args{cluster}->getAttr('name' => 'cluster_name');

   # Get the monitored values    
    my $monitored_haproxy_timers = $self->{_monitor}
                                   ->getClusterData( 
                                        cluster   => $cluster_name,
                                        set       => "haproxy_timers",
                                        time_laps => $time_laps
                                     );
                                     

    #Get monitored througput by apache 
    my $monitored_apache_stats = $self->{_monitor}
                                   ->getClusterData( 
                                        cluster    => $cluster_name,
                                        set        => "apache_stats",
                                        time_laps  => $time_laps,
                                        aggregation => 'total',
                                     );
   

    
    #print Dumper $cluster_data_aggreg;
    
    return {
      latency => $monitored_haproxy_timers->{Tt}/1000, #get ms and return seconds
      abort_rate => 0, #TODO implement abort rate
      throughput => $monitored_apache_stats->{ReqPerSec},
    };
}

=head2 _updateModelInternalParameters
    
    Class : Private
    
    Desc : Launch model autotunning and update parameters and 
           set the parameters.
           NEED TO RE-IMPLEMENT method when params DB saving is managed 
    
    Args :
        algo_conf : Configuration of the autotune algorithm configuration 
        workload :
        infra_conf : Current infastructure configuration 
        curr_perf : Monitored performance
        cluster_id :
        
    Return :
        best_params: Until DB saving is not managed, otherwise return void.
=cut

sub _autoTuneAndUpdateModelInternalParameters {
    
    my $self = shift;
    my %args = @_;

    General::checkParams args => \%args, required => [
        'algo_conf',
        'workload',
        'infra_conf',
        'curr_perf',
        'cluster_id'
    ];

    my $algo_conf         = $args{algo_conf};
    my $workload          = $args{workload};
    my $curr_perf         = $args{curr_perf};
    my $infra_conf        = $args{infra_conf};
    my $cluster_id        = $args{cluster_id};
    
    # Dumper inline
    $Data::Dumper::Indent = 0;
    $log->debug("Infra conf: " . (Dumper $infra_conf));
    
#    print "algo_conf\n";
#    print Dumper $algo_conf;
#    print "workload\n";
#    print Dumper $workload;
#    print "infra_conf\n";
#    print Dumper $infra_conf;
#    print "curr_perf\n";
#    print Dumper $curr_perf;
    
    # Launch autoTune algorithm in order to get Si/Di that match with real
    # monitored model 
    my $best_params = $self->modelTuning( 
        algo_conf  => $algo_conf, 
        workload   => $workload, 
        infra_conf => $infra_conf, 
        curr_perf  => $curr_perf 
    );


    
#    my $best_params = $self->{_modelTuning}->modelTuning( 
#        algo_conf  => $algo_conf, 
#        workload   => $workload, 
#        infra_conf => $infra_conf, 
#        curr_perf  => $curr_perf 
#    );

print Dumper $best_params;
    
    
    
#    $self->updateModelInternaParameters( cluster_id   => $cluster_id, 
#                                         delay        => $best_params->{D}, 
#                                         service_time => $best_params->{S});
#    $log->debug("update parameters: D = " . (Dumper $args{delay}) . " ## S = " . (Dumper $args{service_time}) );
    
    # We update parameters for one cluster (considering only one tier for the moment, no infra entity yet)
    
    #print Dumper $best_params;
    #my $D_in_ms = $best_params->{S};
    
    
    # /!\ Set only the first value => 1 tier hardcoding
    # TODO manage DB in order to save n tiers configuration
    
    $self->{data_manager}->setClusterModelParameters( 
         cluster_id   => $cluster_id,
         service_time => $best_params->{S}[0], #service_time => $args{service_time}[0]
         delay        => $best_params->{D}[0], #service_time => $args{service_time}[0]
    );
    
    # /!\ Return the params until we manage the infra in DB !
    # TODO : DB infra vector
    return $best_params;
    #print Dumper $self->{data_manager}->getClusterModelParameters(cluster_id   => $cluster_id);
}
    
    
=head2 updateModelInternaParameters_old
    
    Class : Public
    
    Desc : Deprecated, use _updateModelInternaParameters instead
    
    
    Args :
        Cluster : The monitored cluster
    
    Return :
        HASHREF {latency=>float, abort_rate=>float (not implemented yet)); throughput=>(not implemented yet)}
=cut

sub _updateModelInternaParameters_old {
    my $self = shift;
    my %args = @_;
    
    my $cluster_id = $args{cluster_id}; #$args{cluster}->getAttr('name' => 'cluster_id');
    
    $log->debug("update parameters: D = " . (Dumper $args{delay}) . " ## S = " . (Dumper $args{service_time}) );
    
    # We update parameters for one cluster (considering only one tier for the moment, no infra entity yet)
    $self->{data_manager}->setClusterModelParameters( 
        cluster_id   => $cluster_id,
        delay        => $args{delay}[0],
        service_time => $args{service_time}[0]
    );
    }

=head2 preManageCluster
    
    Class : Public
    
    Desc : Get the needed datas and launch the Kica main algorithm 
    
    Args :
        Cluster : The monitored cluster
    
    Return : void

=cut

sub preManageCluster{
    my $self = shift;
    my %args = @_;

    General::checkParams args => \%args, required => ['cluster'];

    my $cluster      = $args{cluster};
    my $cluster_id   = $args{cluster}->getAttr('name' => 'cluster_id');
    my $cluster_name = $cluster->getAttr('name' => 'cluster_name');
        
    # Refresh qos constraints
    # TODO make one sub with these two instruction ($contraints not used elsewhere)
    # Perhaps Cap Planner can set contraints directly from DB when called ?
    
    my $constraints = $self->{data_manager}
                            ->getClusterQoSConstraints( 
                                cluster_id => $cluster_id 
    );
    $self->{_cap_plan}->setConstraints(constraints => $constraints );
    
    
    $log->info("Qos constraints: Max abort rate = $constraints->{max_abort_rate}, Max latency = $constraints->{max_latency}");
     
    # TODO Study where to get this information (need real study)
    my $nb_tiers = 1; 
    
    #Get all data before launching ManageCluster
    
    # [Format] workload: {workload_amount, workload_class}
    # [Format] workload_class: {visit_ratio, service_time, delay, think_time}
    my $workload     = $self->getWorkload( cluster => $cluster);
    
    $log->info("Monitored workload amount $workload->{workload_amount}");
    $log->info("Monitored workload_class 
        visit_ratio = @{$workload->{workload_class}->{visit_ratio}};
        service_time = @{$workload->{workload_class}->{service_time}};
        delay = @{$workload->{workload_class}->{delay}}; 
        think_time = $workload->{workload_class}->{think_time}"
     );
    
    # [Format] curr_perf: {throughput, latency, abort_rate}
    
    my $time_laps = 1200; # Monitored windows in ms
    my $curr_perf    = $self->getMonitoredPerfMetrics( cluster => $cluster);
    my $mean_perf    = $self->getMonitoredPerfMetrics( 
                                cluster   => $cluster,
                                time_laps => $time_laps,
                              );
                              
    my $cluster_conf = $self->getClusterConf( cluster => $cluster);
    
    
    $log->info("$cluster_name : Monitored latency (ha_proxy)         = $curr_perf->{latency}"); 
    $log->info("$cluster_name : Monitored latency (ha_proxy, ".($time_laps/60)."min)  = $mean_perf->{latency}"); 
    $log->info("$cluster_name : Monitored throughput (apache)        = $curr_perf->{throughput}"); 
    $log->info("$cluster_name : Monitored throughput (apache, ".($time_laps/60)."min) = $mean_perf->{throughput}");
    
    $log->info("Monitored abort_rate = $curr_perf->{abort_rate} (not implemented yet)");
    

    # latency => $cluster_data_aggreg->{Tt},
    # abort_rate => 0,
    # throughput => 0,

    # TODO Study where to get this information (need real study)
    my $infra_conf   = {
        M        => $nb_tiers,
        AC       => [$cluster_conf->{nb_nodes}],
        LC       => [$cluster_conf->{mpl}],
    };
    
    # TODO just use cluster_id instead of $cluster_params, since only cluster_id is used
    my $cluster_params = {
                    cluster_id => $cluster->getAttr('name' => 'cluster_id'),
    };

    # TODO Study where to get this information from (need real study)
    my @search_space = (); 
    for (0..$nb_tiers)
    {
       push @search_space, 
        {
            min_node => $cluster->getAttr(name => 'cluster_min_node'), 
            max_node => $cluster->getAttr(name => 'cluster_max_node'),
            min_mpl  => $cluster_conf->{mpl},
            max_mpl  => $cluster_conf->{mpl},
        };
    }
    
    # Launch the algorithm with all the data
    my $optim_params = $self->manageCluster( 
        cluster_params => $cluster_params, 
        workload       => $workload, 
        curr_perf      => $curr_perf, 
        infra_conf     => $infra_conf,
        search_space   => \@search_space,
    );
    

    # Store and graph results for futur consultation
    # $self->_validateModel( workload => $workload, cluster_conf => $cluster_conf, cluster => $cluster );

    # Apply optimal configuration
    # TODO This method signature should be changed to handle infra in a better way
    
    $self->{_actuator}->changeInfraConf(
                        infra => [ { cluster => $cluster, conf => $cluster_conf } ],
                        target_conf => $optim_params,
    );
    
}

=head2 manageCluster
    
    Class : Public
    
    Desc : Main Kica algorithm
    
    Args :
        cluster_params: Currently only {cluster_id} in order to save best params 
        Di/Si
        workload: {workload_amount, workload_class} 
        curr_perf: {throughput, latency, abort_rate} Monitored performance
        infra_conf: {M, AC, LC} current infrastructure configuration
        search_space: @search_space. For each tier : {min_node, max_node, 
            min_mpl, max_mpl}. Use to set the capacity planning algorithm
        
    Return : $optim_params optimal infrastructure to feed actuators

=cut

sub manageCluster {

    my $self = shift;
    my %args = @_;

    General::checkParams args => \%args, required => ['cluster_params','workload','curr_perf', 'infra_conf', 'search_space'];

    my $cluster_params = $args{cluster_params};
    my $workload       = $args{workload};
    my $curr_perf      = $args{curr_perf};
    my $infra_conf     = $args{infra_conf};
    my $search_space   = $args{search_space};
    
    # [Format] workload:       {workload_amount, workload_class}
    # [Format] workload_class: {visit_ratio, service_time, delay, think_time}
    # [Format] curr_perf:      {throughput, latency, abort_rate} 
    # [Format] infra_conf:     {M, AC, LC} 
    # [Format] search_space
    
    # Refresh qos constraints => Now done in preManager
    # my $constraints = $self->{data_manager}->getClusterQoSConstraints( cluster_id => $cluster_id );
    # $self->{_cap_plan}->setConstraints(constraints => $constraints );    

    
    # Capacity planning settings 
    # TODO one setting sub 
    $self->{_cap_plan}->setSearchSpaceForTiers(search_spaces => $search_space);
    $self->{_cap_plan}->setNbTiers( tiers => $infra_conf->{M});

    #my $mpl = $infra_conf->{LC}->[0];
    #    $self->{_cap_plan}->setSearchSpaceForTiers( search_spaces =>     [ 
    #                {   
    #                    #min_node => $cluster->getAttr(name => 'cluster_min_node'), 
    #                    #max_node => $cluster->getAttr(name => 'cluster_max_node'),
    #                    min_node => $cluster_params->{cluster_min_node}, 
    #                    max_node => $cluster_params->{cluster_max_node},
    #                    min_mpl  => $mpl,
    #                    max_mpl  => $mpl,}
    #                ]
    #    );
    
    # TODO Manage DB in order to store the algo configuration instead of hardcoding    
    my $algo_conf   = {
        nb_steps            => 40,
        init_step_size      => 5,
        init_point_position => 1,
    };
    
    # Autotune Model and set model parameters (Si and Di)
    # /!\ Output $best_params only used until infra not managed in DB
    # TODO Modify DB in order to store params (need real study)
    my $best_params = 
        $self->_autoTuneAndUpdateModelInternalParameters(
        algo_conf    => $algo_conf,
        workload     => $workload,
        infra_conf   => $infra_conf,
        cluster_id   => $cluster_params->{cluster_id},
        curr_perf    => $curr_perf,
    );

    # Get actual internal model parameters (Si and Di)
    # Get from DB (theoreticaly updated by _updateModelInternalParameters() sub)
    my $cluster_workload_class = $self->{data_manager}
                                      ->getClusterModelParameters(
                                            cluster_id =>$cluster_params->{cluster_id} 
                                       );
                                       
    #  /!\ Useful while DB INFRA NOT MANAGED ! /!\ 
    # Need to update here for the moment
    $cluster_workload_class -> {service_time} = $best_params -> {S};
    $cluster_workload_class -> {delay} = $best_params -> {D};
    
    # Feed capacity planning with computed Si/Di
    $workload->{workload_class}->{service_time} = $cluster_workload_class->{service_time}; 
    $workload->{workload_class}->{delay}        = $cluster_workload_class->{delay};
    
    # $workload->{workload_class}->{service_time} = $best_params->{S};
    # $workload->{workload_class}->{delay}        = $best_params->{D};
    $log->info("Computed params Si = @{$workload->{workload_class}->{service_time}} ; Di = @{$workload->{workload_class}->{delay}}\n");
    

    
    # Calculate optimal configuration
    my $optim_params = $self->{_cap_plan}->calculate(
        workload_amount => $workload->{workload_amount},
        workload_class  => $workload->{workload_class}
    );
    
    $log->info("Computed optimal configuration : AC = @{$optim_params->{AC}}, LC = @{$optim_params->{LC}} \n");
    
    # All the end of the algo is the new perf computation only useful for [DEBUG]
    
    my $optim_conf = {
        M  => $infra_conf->{M},
        AC => $optim_params->{AC},
        LC => $optim_params->{LC},
    };
    
    
        
    my %model_optim_params = (
        configuration   => $optim_conf,
        workload_amount => $workload->{workload_amount},
        workload_class  => $workload->{workload_class}
    );
    
    #print Dumper \%model_optim_params;
    

    my %new_perf = $self->{_model}->calculate(%model_optim_params);
    $log->info(sprintf("New theoretical perf : throughput = %.2f, latency = %.3f, abort_rate = %.2f\n",$new_perf{throughput},$new_perf{latency},$new_perf{abort_rate}));
     
    return $optim_params;
    
    #$self->{_actuator}->changeClusterConf( cluster => $cluster, current_conf => $cluster_conf, target_conf => $optim_conf,);
}

=head2 modelTuning

    Desc : compute model internal parmaters (Si, Di) according to simulated output and measured output
    
    Args :

    Return :
    
=cut

sub modelTuning {
    
    my $self = shift;
    my %args = @_;
    
    my $algo_conf  = $args{algo_conf};
    my $infra_conf = $args{infra_conf};
    my $workload   = $args{workload};
    
    
    my $NB_STEPS            = $algo_conf->{nb_steps}; #15;
    my $INIT_STEP_SIZE      = $algo_conf->{init_step_size}; #5;
    my $INIT_POINT_POSITION = $algo_conf->{init_point_position}; #1;
    
    my $M      = $infra_conf->{M};
    my @best_S = ($INIT_POINT_POSITION) x $M;
    my @best_D = ($INIT_POINT_POSITION) x $M;
    $best_D[0] = 0.;
    my $best_gain = -10000;
    my $dim_best_gain = 0;
    my $evo_best_gain = 0;
    
    my $evo_step = $INIT_STEP_SIZE;
    
    my $curr_perf = $args{curr_perf};
    
    #print Dumper $curr_perf;
    
    for my $step (0..($NB_STEPS-1)) {
        #print "Step $step / $NB_STEPS\n";
        $best_gain = -10000;
        $dim_best_gain = 0;
        $evo_best_gain = 0;
        
        #print "Step $step\n";
        # For each space dimension (internal parameters except D1)
        for my $dim (0..(2*$M-1-1)) { # -1 for D1 and -1 because we start at 0
            # print " Dim $dim\n";
            # Evolution direction for this dimension
            EVO:
            for (my $evo = -$evo_step; $evo <= $evo_step; $evo += 2*$evo_step ) {
                
                my @S = @best_S;
                my @D = @best_D;
                
                
                if ($dim < $M) { #S proceeding when dim in (0..$M-1) ($M values)
                    $S[$dim] += $evo;
                    next EVO if ($S[$dim] <= 0); # Prevent null or negative Si
                } else {       #D proceeding when dim in ($M 2*$M-2) ($M - 1 values)
                    $D[$dim - $M + 1] += $evo;
                    next EVO if ($D[$dim - $M + 1] < 0); # Null delay allowed
                }
                
                 
                #print "evo = $evo ; [@S] ; [@best_S] ; [@D] ; [@best_D]\n";
                
    
                my %model_params = (
                        configuration => $infra_conf,
                        workload_amount => $workload->{workload_amount},
                        workload_class => {
                                            visit_ratio => $workload->{workload_class}{visit_ratio},
                                            think_time  => $workload->{workload_class}{think_time},
                                            service_time => \@S,
                                            delay => \@D,
                                           }
                );
              
                
                
                
                #print Dumper \%model_params;
                
                my %new_out = $self->{_model}->calculate( %model_params );
                
                #print "## NEW out ##\n";
                #print Dumper \%new_out;
                
                $model_params{workload_class}{service_time} = \@best_S;
                $model_params{workload_class}{delay} = \@best_D;
                
                # TODO optimize algo by keeping best output
                
                #print Dumper \%model_params;
                my %best_out = $self->{_model}->calculate( %model_params );
                
                #print "## BEST out ##\n";
                #print Dumper \%best_out;
                
                my $pDBest = $self->_computeDiff( model_output => \%best_out, monitored_perf => $curr_perf );
                my $pDNew  = $self->_computeDiff( model_output => \%new_out, monitored_perf => $curr_perf );
                my $gain   = $pDBest - $pDNew;
                
                
                #print "pDBest = $pDBest ; pDNew = $pDNew ; gain = $gain ; best_gain = $best_gain\n";
                if ($gain > $best_gain) {
                    $best_gain     = $gain;
                    $dim_best_gain = $dim;
                    $evo_best_gain = $evo;
                }
                
            } # end evo
        } #end dim
        
        if ($dim_best_gain < $M) {
            $best_S[$dim_best_gain] += $evo_best_gain;
        } else {
            $best_D[$dim_best_gain - $M + 1] += $evo_best_gain;
        }
       
        # Avoid oscillations around optimal
        if ($best_gain <= 0) {
            $evo_step /= 2;
        }
    } # end step
    
    return { D => \@best_D, S => \@best_S };
}

=head2 _computeDiff
    
    Class : Private
    
    Desc : Compute 1-norm weighted distance between monitored performance and model output
    
    Args :
        monitored_perf : Monitored performance
        model_output   : Model output
        
    Return :
        1-norm weighted distance between monitored performance and model output (double)
        
=cut

sub _computeDiff {
    my $self = shift;
    my %args = @_;
    
    my $curr_perf = $args{monitored_perf};
    my $model_perf = $args{model_output};
    
    # weight of each parameters
    my %weights = ( latency => 1, abort_rate => 1, throughput => 1);

    my %deviations  = ( latency => 0, abort_rate => 0, throughput => 0);
    
    my $weight = 0;
    for my $metric ('latency', 'abort_rate', 'throughput') {
        if ($curr_perf->{$metric} > 0) {
            $deviations{$metric} = abs( $model_perf->{$metric} - $curr_perf->{$metric} ) * 100 / $curr_perf->{$metric}; 
            $weight += $weights{$metric};
        }
    }
    
    # Here MOKA process a sqrt(pow(dev,2)). Seems useless.
    
    my $dev = 0;
    for my $metric ('latency', 'abort_rate', 'throughput') {
        $dev += $deviations{$metric} * $weights{$metric}; 
    }
    $dev /= $weight if ($weight > 0);
    
    #$log->debug("* Deviation * " . (Dumper \%deviations));
    #$log->debug("==> $dev");
    
    return $dev;
}

sub _validateModel {
    
    my $self = shift;
    my %args = @_;
    
    my $workload = $args{workload};
    my $cluster_conf = $args{cluster_conf};
    
    
    my %perf = $self->{_model}->calculate(  configuration => {  M => 1,
                                                                AC => [$cluster_conf->{nb_nodes}],
                                                                LC => [$cluster_conf->{mpl}]
                                                                },
                                            workload_class => $workload->{workload_class},
                                            workload_amount => $workload->{workload_amount}
                                            );
    
    
    # Store model output
    my $rrd = $self->getControllerRRD( cluster => $args{cluster} );
    $rrd->update( time => time(), values => [   $workload->{workload_amount},
                                                $perf{latency} * 1000,
                                                $perf{abort_rate},
                                                $perf{throughput},
                                            ] );
    
    # Update graph
    $self->genGraph( cluster => $args{cluster} );
}

sub genGraph {
    my $self = shift;
    my %args = @_;
    
    my $rrd = $self->getControllerRRD( cluster => $args{cluster} );
    
    my $cluster_id = $args{cluster}->getAttr('name' => 'cluster_id');
    my $graph_file_prefix = "cluster$cluster_id" . "_controller_server_";
    
    # Quick trick to display in the same graph the modelised metric and the measurement (temporary)
    my %profil_latency_draw = ();
    my %profil_throughput_draw = ();
    my $cluster_public_ips = $args{cluster}->getPublicIps();
    if (defined $cluster_public_ips->[0]) {
        my $profil_rrd_name = "perf_" . $cluster_public_ips->[0]{address} . ".rrd";
        if ( -e "/tmp/$profil_rrd_name") {
            %profil_latency_draw = ( draw => {  type => 'line', color => '0000FF',
                                                dsname  => "latency", legend => "latency(profil)",
                                                file => "/tmp/$profil_rrd_name" } );
            %profil_throughput_draw = ( draw => {   type => 'line', color => '0000FF',
                                                    dsname  => "throughput", legend => "throughput(profil)",
                                                    file => "/tmp/$profil_rrd_name" } );    
        }
    }
        
    # LOAD
    $rrd->graph(
      image          => "/tmp/" . $graph_file_prefix . "load.png",
      vertical_label => 'req',
      start => time() - 3600,
      title => "Load",
      draw    => {
            type    => 'line',
            color   => 'FF0000',
            dsname  => "workload_amount",
            legend  => "load amount (concurrent connections)"
        },
    );
    
    
    # LATENCY
    
    $rrd->graph(
      image          => "/tmp/" . $graph_file_prefix . "latency.png",
      vertical_label => 'ms',
      start => time() - 3600,
      title => "Latency",
      draw  => {
            type    => 'line',
            color   => '00FF00', 
            dsname  => "latency",
            legend  => "latency"
        },
      %profil_latency_draw,
    );
    
    $rrd->graph(
      image          => "/tmp/" . $graph_file_prefix . "abortrate.png",
      vertical_label => 'rate',
      start => time() - 3600,
      title => "Abort rate",
      draw  => {
        type    => 'area',
        color   => '00FF00', 
        dsname  => "abort_rate",
        legend  => "abortRate"},
    );

    $rrd->graph(
      image          => "/tmp/" . $graph_file_prefix . "throughput.png",
      vertical_label => 'req/sec',
      start => time() - 3600,
      title => "Throughput",
      draw  => {
        type    => 'area',
        color   => '00FF00', 
        dsname  => "throughput",
        legend  => "throughput"
      },
      %profil_throughput_draw,
    );
        
}

sub update {
    my $self = shift;
    my %args = @_;

    my @clusters = Entity::Cluster->getClusters( hash => { cluster_state => {-like => 'up:%'} } );
    
    
    for my $cluster (@clusters) {        
        my $cluster_name = $cluster->getAttr('name' => 'cluster_name');
        $log->info( "***********************************");
        $log->info( "* CLUSTER: " . $cluster_name . "\n ");
        $log->info( "***********************************");
        #if($cluster->getAttr('name' => 'active')) 
        {
            # TODO get controller/orchestration conf for this cluster and init this controller
            # $cluster->getCapPlan(); $cluster->getModel()
            eval {
                $self->preManageCluster( cluster => $cluster );
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
            $log->warn("update duration > update time step (conf)");
        } else {
            sleep( $self->{_time_step} - $update_duration );
        }

    }
    
    #$self->{_admin}->addMessage(from => 'Orchestrator', level => 'warning', content => "Kanopya Orchestrator stopped");
}


1;