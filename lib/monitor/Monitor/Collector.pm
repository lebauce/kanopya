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
package Monitor::Collector;

use strict;
use warnings;
use threads;
#use threads::shared;
use Net::Ping;
use Entity::Host;
use Data::Dumper;
use Message;
use base "Monitor";

# logger
use Log::Log4perl "get_logger";
my $log = get_logger("collector");

# Constructor

sub new {
    my $class = shift;
    my %args = @_;
    
    my $self = $class->SUPER::new( %args );
    return $self;
}


=head2 updateHostData
    
    Class : Public
    
    Desc : For a host, retrieve value of all monitored data (var defined in conf) and store them in corresponding rrd
    
    Args :
        host_ip : the host ip adress
        components : array ref of components name on this host.
        host_state : current state of the host

=cut

sub updateHostData {
    my $self = shift;
    my %args = @_;



    my $start_time = time();

    my $host = $args{host_ip};

    my %all_values = ();
    my $host_reachable = 1;
    my $error_happened = 0;
    my %providers = ();
    eval {
        #For each required set of indicators
        SET:
        foreach my $set ( @{ $args{sets} } ) {

            #############################################################
            # Skip this set if associated component is not on this host #
            #############################################################
            if (defined $set->{'component'} && $set->{'component'} ne 'base' &&    
                #0 == grep { $_ eq $set->{'component'} } @{$args{components}} 
                ! exists $args{components}->{ $set->{'component'} }
                ) {
                $log->info("[$host] No component '$set->{'component'}' to monitor on this host");
                next SET;
            }

			# Skip set if collect is done by an external process
			next SET if ($set->{'data_provider'} eq 'extern');

            ###################################################
            # Build the required var map: ( var_name => oid ) #
            ###################################################
            my %var_map = map { $_->{label} => $_->{oid} } @{ General::getAsArrayRef( data => $set, tag => 'ds') };
            

            my ($time, $update_values);
            my $retrieve_set_time;
            my $provider_class;
            eval {
                #################################
                # Get the specific DataProvider #
                #################################
                $provider_class = $set->{'data_provider'} || "SnmpProvider";
                my $data_provider = $providers{$provider_class};
                if (not defined $data_provider) {
                    require "DataProvider/$provider_class.pm";
                    $data_provider = $provider_class->new( host => $host, component =>  $args{'components'}->{ $set->{'component'} } );
                    $providers{$provider_class} = $data_provider;
                }
                
                ############################################################################################################
                # Retrieve the map ref { index => { var_name => value } } corresponding to required var_map for each entry #
                ############################################################################################################
                my $retrieve_set_start_time = time();
                if ( defined $set->{table_oid} ) {
                    ($time, $update_values) = $data_provider->retrieveTableData( table_oid => $set->{table_oid}, index_oid => $set->{index_oid}, var_map => \%var_map );
                } else {
                    ($time, $update_values->{"0"}) = $data_provider->retrieveData( var_map => \%var_map );
                }
                #$log->info("[$host] ##### Collect '$set->{label}' time : " .  (time() - $retrieve_time));
                $retrieve_set_time = time() - $retrieve_set_start_time;
            };
            if ($@) {
                #####################
                # Handle exceptions #
                #####################
                my $error = $@;
                $log->warn( "[" . threads->tid() . "][$host] Collecting data set '$set->{label}' => $provider_class : $error" );
                #TODO find a better way to detect unreachable host (grep error string is not very safe)
                if ( "$error" =~ "No response" || "$error" =~ "Can't connect") {
                    $provider_class =~ /(.*)Provider/;
                    my $comp = $1;
                    my $mess = "Can not reach component '$comp' on $host";
                    if ( $args{host_state} =~ "up" ) {
                        $log->info( "Unreachable host '$host' (component '$comp') => we stop collecting data.");
                        Message->send(from => 'Monitor', level => "warning", content => $mess );
                    }
                    $host_reachable = 0;
                    last SET; # we stop collecting data sets
                } else {
                    my $mess = "[$host] Error while collecting data set '$set->{label}' => $error";
                    $log->warn($mess);
                    Message->send(from => 'Monitor', level => "warning", content => $mess );
                    $error_happened = 1;
                }
                next SET; # continue collecting the other data sets
            }

            #############################################
            # Store new values in the corresponding RRD #
            #############################################
            # we loop because updates_values can be rows of table
            while ( my ($index, $values) = each %$update_values) { 
                # Log value of indicators
                $log->debug( "[" . threads->tid() . "][$host](" . $retrieve_set_time . "s) '$set->{label}' => "
                             . join( " | ", map { "$_" . ($index eq "0" ? "" : ".$index") . ":$values->{$_}" } keys %$values )
                           );
                
                my $set_name = $set->{label} . ( $index eq "0" ? "" : ".$index" );
                my $rrd_name = $self->rrdName( set_name => $set_name, host_name => $host );
                my %stored_values = $self->updateRRD( rrd_name => $rrd_name, set_name => $set_name, ds_type => $set->{ds_type}, time => $time, data => $values );
                
                $all_values{ $set_name } = \%stored_values;
            }
            
        } #END FOREACH SET
        
        # Update host state
        #$self->_manageHostState( host => $host, reachable => $host_reachable );
    };
    if ($@) {
        my $error = $@;
        $log->error( $error );
        $error_happened = 1;
        #TODO manage $host_state in this case (error)
        
    }
    
    $log->warn("[$host] => some errors happened collecting data") if ($error_happened);
    
    $log->info("[$host] Collect time : " . (time() - $start_time));
    
    return \%all_values;
}

=head2 updateClusterNodeCount
    
    Class : Private
    
    Desc : Store current node count of each state ('up', 'down',...) for a cluster
    
    Args : 
        cluster_name
        nodes_state: array ref of states

=cut

sub updateClusterNodeCount {
    my $self = shift;
    my %args = @_;
    
    my ($cluster_name, $nodes_state, $hosts_state) = ($args{cluster_name}, $args{nodes_state}, $args{hosts_state});
    
    # RRD for node count
    my $rrd_file = "$self->{_rrd_base_dir}/nodes_$cluster_name.rrd";
    my $rrd = RRDTool::OO->new( file =>  $rrd_file );
    if ( not -e $rrd_file ) {    
        $log->info("Info: create nodes rrd for '$cluster_name'");
        $rrd->create(     'step' => $self->{_time_step},
                        'archive' => { rows => $self->{_period} / $self->{_time_step} },
                        'archive' => {     rows => $self->{_period} / $self->{_time_step},
                                        cpoints => 10,
                                        cfunc => "AVERAGE" },
                        # nodes
                        'data_source' => {     name => 'up', type => 'GAUGE' },
                        'data_source' => {     name => 'starting', type => 'GAUGE' },
                        'data_source' => {     name => 'stopping', type => 'GAUGE' },
                        'data_source' => {     name => 'broken', type => 'GAUGE' },
                        
                        # hosts
#                        'data_source' => {     name => 'host_up', type => 'GAUGE' },
#                        'data_source' => {     name => 'host_starting', type => 'GAUGE' },
#                        'data_source' => {     name => 'host_stopping', type => 'GAUGE' },
#                        'data_source' => {     name => 'host_broken', type => 'GAUGE' },
                    );
        
    }
    
    my %count;
    
    # Nodes
    $count{up} = scalar grep { $_ =~ '^in' } @$nodes_state;
    $count{starting} = scalar grep { $_ =~ 'goingin' } @$nodes_state;
    $count{stopping} = scalar grep { $_ =~ 'goingout' } @$nodes_state;
    $count{broken} = scalar grep { $_ =~ 'broken' } @$nodes_state;

    # hosts
#    $count{host_up} = scalar grep { $_ =~ '^up' } @$hosts_state;
#    $count{host_starting} = scalar grep { $_ =~ 'starting' } @$hosts_state;
#    $count{host_stopping} = scalar grep { $_ =~ 'stopping' } @$hosts_state;
#    $count{host_broken} = scalar grep { $_ =~ 'broken' } @$hosts_state;

    # we want update the rrd at time multiple of time_step (to avoid rrd extrapolation)
    my $time = time();
    my $mod_time = $time % $self->{_time_step};
    $time += ($mod_time > $self->{_time_step} / 2) ? $self->{_time_step} - $mod_time : -$mod_time; 
    eval {
        $rrd->update( time => $time, values => \%count );
    };
    if ($@) {
        my $error = $@;
        if ($error =~ "illegal attempt to update using time") {
            $log->warn("=> same nodecount update time.");
        }
        else {
            die $error;
        }
    }
}

=head2 updateClusterData
    
    Class : Private
    
    Desc : Aggregate and store indicators values for each set for a cluster
    
    Args :
        cluster : Entity::ServiceProvider::Inside::Cluster
        hosts_values : hash ref : indicators values of each set for each hosts
        collect_time : seconds since Epoch when hosts data have been collected 
    
=cut

sub updateClusterData{
    my $self = shift;
    my %args = @_;
    
    my ($cluster, $hosts_values, $collect_time ) = ($args{cluster}, $args{hosts_values}, $args{collect_time});
    my $cluster_name = $cluster->getAttr( name => "cluster_name" );
    
    my @mbs = values %{ $cluster->getHosts( ) };
    my @in_node_mb = grep { $_->getNodeState() =~ '^in' } @mbs; 
    
    
    # Group indicators values by set
    my %sets;
    foreach my $mb (@in_node_mb) {
        my $host_ip = $mb->getInternalIP()->{ipv4_internal_address};
        my @sets_name = keys %{ $hosts_values->{ $host_ip } };
        foreach my $set_name ( @sets_name ) {    
            push @{$sets{$set_name}}, $hosts_values->{ $host_ip }{$set_name};
        }
    }
    
    # For each sets, aggregate values and store 
    SET:
    while ( my ($set_name, $sets_list) = each %sets ) {
                
        if ( scalar @in_node_mb != scalar @$sets_list ) {
            $log->warn("During aggregation => missing set '$set_name' for one node of cluster '$cluster_name'. Cluster aggregated values for this set as considered undef.");
            next SET;
        }
                    
        my %aggreg_mean = $self->aggregate( hash_list => $sets_list, f => 'mean' );
        my %aggreg_sum = $self->aggregate( hash_list => $sets_list, f => 'sum' );
    
        next SET if ( scalar grep { not defined $_ } values %aggreg_sum );
                
        my $base_rrd_name = $self->rrdName( set_name => $set_name, host_name => $cluster_name );
        my $mean_rrd_name = $base_rrd_name . "_avg";
        my $sum_rrd_name = $base_rrd_name . "_total";
        eval {
            $self->updateRRD( rrd_name => $mean_rrd_name, set_name => $set_name, ds_type => 'GAUGE', time => $collect_time, data => \%aggreg_mean);
            $self->updateRRD( rrd_name => $sum_rrd_name, set_name => $set_name, ds_type => 'GAUGE', time => $collect_time, data => \%aggreg_sum);
        };
        if ($@){
            my $error = $@;
            $log->error("Update cluster rrd error => $error");
        }
    }
    
    # log cluster nodes state
    my @state_log = map {     $_->getInternalIP()->{ipv4_internal_address} .
                            " (" . $_->getAttr( name => "host_state" ) .
                            ", node:" .  $_->getNodeState() . ")"
                        } @mbs;
    $log->debug( "# '$cluster_name' nodes : " . join " | ", @state_log );
    
    # update cluster node count
    my @hosts_state = map { $_->getState() } @mbs;
    my @nodes_state = map { $_->getNodeState() } @mbs;
    $self->updateClusterNodeCount( cluster_name => $cluster_name, nodes_state => \@nodes_state, hosts_state => \@hosts_state )    
}

=head2 udpate
    
    Class : Public
    
    Desc :  Update data for every monitored host and then update clusters data
    
=cut

sub update {
    my $self = shift;
    
    # Flag to switch between threaded mode or not.
    # Threaded mode: allow to manage simultaneously each host and so speed up the entire update
    #                 but some memory leaks happen and collector can seg fault (TODO make it work properly)
    my $THREADED = 0;
    
    my $start_time = time();
    
    eval {

        my $monitor_manager = $self->{_admin}->{manager}{monitor};

        ############################
        # Update data for each host #
        #############################
        my %hosts_values = ();
        my %threads = ();
        my @clusters = Entity::ServiceProvider::Inside::Cluster->getClusters( hash => { } );
        foreach my $cluster (@clusters) {
            $log->info("# Update nodes data of cluster " . $cluster->getAttr( name => "cluster_name"));
            # Get set to monitor for this cluster
            my $monitored_sets = $monitor_manager->getCollectedSets( cluster_id => $cluster->getAttr( name => "cluster_id") );
            # Get components of this cluster
            my $components = $cluster->getComponents(category => 'all');
            #my @components_name = map { $_->getComponentAttr()->{component_name} } values %$components;
            my %components_by_name = map { $_->getComponentAttr()->{component_name} => $_ } values %$components;
            # Collect data for nodes in the cluster
            foreach my $mb ( values %{ $cluster->getHosts( ) } ) {
                if ( $mb->getNodeState() =~ '^in' ) {
                    my $host_ip = $mb->getInternalIP()->{ipv4_internal_address};
                    my %params = (
                        host_ip => $host_ip,
                        host_state => $mb->getAttr( name => "host_state" ),
                        components => \%components_by_name,
                        sets => $monitored_sets,
                    );
                    if ($THREADED) {
                        my $thr = threads->create( 'updateHostData', $self, %params    );
                        $threads{$host_ip} = $thr;
                    } else {
                        my $ret = $self->updateHostData( %params );
                        $hosts_values{ $host_ip } = $ret;
                    }
                }
            }
        }
        
        #############################
        # Wait end of all threads  #
        ############################
        if ($THREADED) {
            while ( my ($host_ip, $thr) = each %threads ) {
                my $ret = $thr->join();
                $hosts_values{ $host_ip } = $ret;
            }
        }
        
        #################################################################
        # update clusters databases (nodes count and aggregated values) #
        #################################################################    
        my $time = time();
        foreach my $cluster (@clusters) {
                $self->updateClusterData(     
                                            cluster => $cluster,
                                              hosts_values => \%hosts_values,
                                              collect_time => $start_time, 
                                          );
        }
        
        # Update total consumption
        $self->updateConsumption();
    };
    if ($@) {
        my $error = $@;
        $log->error( $error );
        if ($error->can('trace')) {
            $log->error( $error->trace->as_string );
        }
    }

    #find_cycle($self);    
}


sub updateConsumption {
    my $self = shift;
    
    # RRD for microcluster consumption
    my $rrd_file = "$self->{_rrd_base_dir}/total_consumption.rrd";
    my $rrd = RRDTool::OO->new( file =>  $rrd_file );
    if ( not -e $rrd_file ) {    
        $log->info("Info: create total consumption rrd");
        $rrd->create(     'step' => $self->{_time_step},
                        'archive' => { rows => $self->{_period} / $self->{_time_step} },
                        'archive' => {     rows => $self->{_period} / $self->{_time_step},
                                        cpoints => 10,
                                        cfunc => "AVERAGE" },
                        'data_source' => {     name => 'consumption', type => 'GAUGE' },
                    );
    }
    
    my $consumption = 0;
    my @up_hosts = Entity::Host->getHosts( hash => { host_state => { -like => 'up:%'}} );
    for (@up_hosts) {
        my %model = $_->getModel();
        $consumption += $model{hostmodel_consumption};
    }
    
    $rrd->update( time => time(), values => { 'consumption' => $consumption } );
}

=head2 run
    
    Class : Public
    
    Desc : Launch an update every time_step (configuration)
    
=cut

#TODO with threading we have a "Scalars leaked: 1" printed, supposed harmless 
sub run_threaded {
    my $self = shift;
    
    while ( 1 ) {
        my $thr = threads->create('update', $self);
        $thr->detach();
        #$self->update();

        sleep( $self->{_time_step} );
    }
}

=head2 run
    
    Class : Public
    
    Desc : Launch an update every time_step (configuration)
    
=cut
 
sub run {
    my $self = shift;
    my $running = shift;
    
    my $adm = $self->{_admin};
    Message->send(from => 'Monitor', level => 'info', content => "Kanopya Collector started.");
    
    while ( $$running ) {

        my $start_time = time();

        $self->update();

        my $update_duration = time() - $start_time;
        $log->info( "Update duration : $update_duration seconds" );
        if ( $update_duration > $self->{_time_step} ) {
            $log->warn("update duration > collector time step (conf)");
        } else {
            sleep( $self->{_time_step} - $update_duration );
        }
        
        # Restart this service (bad trick for avoid memory growth (due to leaks))
        #`/etc/init.d/kanopya-collector restart`;
    }
    
    Message->send(from => 'Monitor', level => 'warning', content => "Kanopya Collector stopped");
}

sub getMem {
    
    my $process_name = "kanopya-collector";
    
    my $process = `ps aux | grep $process_name | grep -v grep`;
    #$log->debug("PROCESS: $process");
    if ( $process =~ /root[\s\t]+[\d\.]+[\s\t]+[\d\.]+[\s\t]+[\d\.]+[\s\t]+([\d\.]+)[\s\t]+([\d\.]+)[\s\t]+[a-zA-Z\?\s\t]+[\s\t]+[\d: ]+[\s\t]+(.*)/ )
    {
        #$log->debug("####### VSZ: $1 ### RSS: $2 ########## $3");
        return ($1, $2)
    }
    return;
}

sub logMemBefore {
    my $self = shift;
    my $id = shift;

    my ($vsz, $rss) = getMem();
    $log->debug("BEFORE $id #### VSZ: $vsz ### RSS: $rss");
    $self->{$id}{vsz} = $vsz;
    $self->{$id}{rss} = $rss;
}

sub logMemAfter {
    my $self = shift;
    my $id = shift;

    my ($vsz, $rss) = getMem();
    my $vsz_diff = $vsz - $self->{$id}{vsz};
    my $rss_diff = $rss - $self->{$id}{rss};
    $log->debug("AFTER $id #### VSZ: $vsz ($vsz_diff) ### RSS: $rss ($rss_diff)");
}


1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut