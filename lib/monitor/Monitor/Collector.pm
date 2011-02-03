package Monitor::Collector;

use strict;
use warnings;
use threads;
#use threads::shared;
use Net::Ping;
use Entity::Motherboard;
use Data::Dumper;

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

sub onStateChanged {
	my $self = shift;
	my %args = @_;	
	my ($mb, $last_state, $new_state) = ($args{mb}, $args{last_state}, $args{new_state});
	my $adm = $self->{_admin};
	
	if ( $last_state eq 'starting' && $new_state eq 'up') {
		$adm->newOp(
				type => "UpdateClusterNodeStarted", priority => '500',
				params => {
					motherboard_id => $mb->getAttr(name => 'motherboard_id'),
					cluster_id => $mb->getClusterId()
				});
	} elsif ( $last_state eq 'stopping' && $new_state eq 'down') {
		$adm->newOp(
				type => 'RemoveMotherboardFromCluster', priority => 100, 
				params => {
					motherboard_id => $mb->getAttr(name => 'motherboard_id'),
					cluster_id => $mb->getClusterId()
				});
	}

}

=head2 _manageHostState
	
	Class : Private
	
	Desc : update the state of host in db if necessary (depending if this host is reachable or not and on the state time)
	
	Args :
		host: ip of the host
		reachable: 0 (false) or 1 (true): tell if we have succeeded in retrieving information from this host (i.e reachable or not)

=cut

sub _manageHostState {
	my $self = shift;
	my %args = @_;
	
	my $starting_max_time = $self->{_node_states}{starting_max_time};
	my $stopping_max_time = $self->{_node_states}{stopping_max_time};
	my $adm = $self->{_admin};
	my $reachable = $args{reachable};
	my $host_ip = $args{host};

	eval {
		# Retrieve motherboard
		# TODO keep the motherboard ID and get it with this id! (ip can be not unique)
		my @mb_res = Entity::Motherboard->getMotherboards( hash => { motherboard_internal_ip => $host_ip } );
		die "Several motherboards with ip '$host_ip', can not determine the wanted one" if (1 < @mb_res); # this die must desappear when we'll get mb by id
		my $mb = shift @mb_res;
		die "motherboard '$host_ip' no more in DB" if (not defined $mb);

		# Retrieve mb state and state time
		my ($state, $state_time) = $self->_mbState( state_info => $mb->getAttr( name => "motherboard_state" ) );
		my $new_state = $state;
		
		# Manage new state
		if ( $reachable && $state ne "stopping") {	# if reachable, node is now 'up', except if node is stopping
			$new_state = "up";
		} elsif ( $state eq "up" ) {				# if unreachable and last state was 'up', node is considered 'broken'
				$new_state = 'broken';
		} else {									# else we check if node is not 'starting/stopping' for too long, if it is, node is 'broken'
			
			# Check if stopping node is pingable
			if ($state eq "stopping"){
				my $host_ip = $mb->getAttr( name => 'motherboard_internal_ip' );
				my $p = Net::Ping->new();
				my $pingable = $p->ping($host_ip);
				$p->close();
				if ( not $pingable ) {
					$new_state = 'down';
				} 
			}
			
			# Check if node is not starting/stopping for too long
			my $diff_time = 0;
			if ($state_time) {
				$diff_time = time() - $state_time;	
			}
			if ( 	(( $state eq "starting" ) && ( $diff_time > $starting_max_time )) ||
					(( $state eq "stopping" ) && ( $diff_time > $stopping_max_time ) && ( $new_state ne 'down') ) ) {
				$new_state = 'broken';
				my $mess = "'$host_ip' is in state '$state' for $diff_time seconds, it's too long (see monitor conf), considered as broken."; 
				$log->warn($mess);
				$adm->addMessage(from => 'Monitor', level => "warning", content => $mess );
			}
		}
		
		# Update state in DB if changed
		if ( $state ne $new_state ) {
			$mb->setAttr( name => "motherboard_state", value => $new_state );
			$mb->save();
			$log->info("=> ($host_ip) last state : $state  =>  new state : $new_state");
			$adm->addMessage(from => 'Monitor', level => "info", content => "[$host_ip] State changed : $state => $new_state" );
			
			$self->onStateChanged( mb => $mb, last_state => $state, new_state => $new_state );
		}
	};
	if ($@) {
		my $error = $@;
		$log->error( $error );
	}
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
				0 == grep { $_ eq $set->{'component'} } @{$args{components}} ) {
				$log->info("[$host] No component '$set->{'component'}' to monitor on this host");
				next SET;
			}

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
					$data_provider = $provider_class->new( host => $host );
					$providers{$provider_class} = $data_provider;
				}
				
				############################################################################################################
				# Retrieve the map ref { index => { var_name => value } } corresponding to required var_map for each entry #
				############################################################################################################
				my $retrieve_set_start_time = time();
				if ( exists $set->{table_oid} ) {
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
						$self->{_admin}->addMessage(from => 'Monitor', level => "warning", content => $mess );
					}
					$host_reachable = 0;
					last SET; # we stop collecting data sets
				} else {
					my $mess = "[$host] Error while collecting data set '$set->{label}' => $error";
					$log->warn($mess);
					$self->{_admin}->addMessage(from => 'Monitor', level => "warning", content => $mess );
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
			
		}
		# Update host state
		$self->_manageHostState( host => $host, reachable => $host_reachable );
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
	
	my ($cluster_name, $nodes_state) = ($args{cluster_name}, $args{nodes_state});
	
	# RRD for node count
	my $rrd_file = "$self->{_rrd_base_dir}/nodes_$cluster_name.rrd";
	my $rrd = RRDTool::OO->new( file =>  $rrd_file );
	if ( not -e $rrd_file ) {	
		$log->info("Info: create nodes rrd for '$cluster_name'");
		$rrd->create( 	'step' => $self->{_time_step},
						'archive' => { rows => $self->{_period} / $self->{_time_step} },
						'archive' => { 	rows => $self->{_period} / $self->{_time_step},
										cpoints => 10,
										cfunc => "AVERAGE" },
						'data_source' => { 	name => 'up', type => 'GAUGE' },
						'data_source' => { 	name => 'starting', type => 'GAUGE' },
						'data_source' => { 	name => 'stopping', type => 'GAUGE' },
						'data_source' => { 	name => 'broken', type => 'GAUGE' },
					);
		
	}
		
	my $up_count = scalar grep { $_ =~ 'up' } @$nodes_state;
	my $starting_count = scalar grep { $_ =~ 'starting' } @$nodes_state;
	my $stopping_count = scalar grep { $_ =~ 'stopping' } @$nodes_state;
	my $broken_count = scalar grep { $_ =~ 'broken' } @$nodes_state;

	# we want update the rrd at time multiple of time_step (to avoid rrd extrapolation)
	my $time = time();
	my $mod_time = $time % $self->{_time_step};
	$time += ($mod_time > $self->{_time_step} / 2) ? $self->{_time_step} - $mod_time : -$mod_time; 
	eval {
		$rrd->update( time => $time, values => { 	'up' => $up_count, 'starting' => $starting_count,
													'stopping' => $stopping_count, 'broken' => $broken_count } );
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
		cluster_name
		cluster_info : hash ref : node info for each node of the cluster
		hosts_values : hash ref : indicators values of each set for each hosts
		collect_time : seconds since Epoch when hosts data have been collected 
	
=cut

sub updateClusterData {
	my $self = shift;
	my %args = @_;
	
	my ($cluster_name, $cluster_info, $hosts_values, $collect_time ) = ($args{cluster_name}, $args{cluster_info}, $args{hosts_values}, $args{collect_time});
	
	# Build list of up nodes
	my @up_nodes = grep { $_->{state} =~ 'up' } values %$cluster_info;
	my @nodes_ip = map { $_->{ip} } @up_nodes;
	my $nb_up = scalar @up_nodes;
	
	# Group indicators values by set
	my %sets;
	foreach my $host_ip (@nodes_ip) {
		my @sets_name = keys %{ $hosts_values->{ $host_ip } };
		foreach my $set_name ( @sets_name ) {	
			push @{$sets{$set_name}}, $hosts_values->{ $host_ip }{$set_name};
		}
	}
			
	# For each sets, aggregate values and store 
	SET:
	while ( my ($set_name, $sets_list) = each %sets ) {
				
		if ( $nb_up != scalar @$sets_list ) {
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
	my @state_log = map { "$_->{ip} ($_->{state})" } values %$cluster_info;
	$log->debug( "# '$cluster_name' nodes : " . join " | ", @state_log );
	
	# update cluster node count
	my @nodes_state = map { $_->{state} } values %$cluster_info;
	$self->updateClusterNodeCount( cluster_name => $cluster_name, nodes_state => \@nodes_state )	
			
}

=head2 udpate
	
	Class : Public
	
	Desc : Create a thread to update data for every monitored host
	
=cut

sub update {
	my $self = shift;
	
	my $start_time = time();
	
	eval {

		my %hosts_by_cluster = $self->retrieveHostsByCluster();
		
		if ( 0 == scalar keys %hosts_by_cluster ) {
			$log->info(" # No cluster to monitor => quit\n");
			return;
		}
		
		my $monitor_manager = $self->{_admin}->{manager}{monitor};
		
		#############################
		# Update data for each host #
		#############################
		my %threads = ();
		while ( my ($cluster_name, $cluster_nodes) = each %hosts_by_cluster ) {
			#TODO keep cluster id from the beginning (get by name is not really good)
			my $cluster_id = Entity::Cluster->getCluster( hash => { cluster_name => $cluster_name } )->getAttr( name => "cluster_id");
			my $monitored_sets = $monitor_manager->getCollectedSets( cluster_id => $cluster_id );
			for my $host_info (values %$cluster_nodes) {
				# We create a thread for each host to don't block update if a host is unreachable
				#TODO vérifier les perfs et l'utilisation memoire (duplication des données pour chaque thread), comparer avec fork
				my $thr = threads->create( 	'updateHostData',
											$self,
											host_ip => $host_info->{ip},
											host_state => $host_info->{state},
											components => $host_info->{components},
											sets => $monitored_sets );
				$threads{$host_info->{ip}} = $thr;
			}
		}		

		############################
		# Wait end of all threads  #
		############################
		my %hosts_values = ();

		while ( my ($host_ip, $thr) = each %threads ) {
			my $ret = $thr->join();
			$hosts_values{ $host_ip } = $ret;
		}
		
		#################################################################
		# update clusters databases (nodes count and aggregated values) #
		#################################################################
		# Retrieve clusters info again to be up to date (nodes state may change during update)	
		%hosts_by_cluster = $self->retrieveHostsByCluster();
		while ( my ($cluster_name, $cluster_info) = each %hosts_by_cluster ) {
			
			$self->updateClusterData( cluster_name => $cluster_name,
									  cluster_info => $cluster_info,
									  hosts_values => \%hosts_values,
									  collect_time => $start_time, 
									  );
		}
			
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
	$adm->addMessage(from => 'Monitor', level => 'info', content => "Kanopia Collector started.");
	
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
	
	$adm->addMessage(from => 'Monitor', level => 'warning', content => "Kanopia Collector stopped");
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