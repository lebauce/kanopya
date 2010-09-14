package Monitor::Collector;

use strict;
use warnings;
use threads;
#use threads::shared;
use Net::Ping;

use Data::Dumper;

use base "Monitor";

# Constructor

sub new {
    my $class = shift;
    my %args = @_;
	
	my $self = $class->SUPER::new( %args );
    return $self;
}

sub manageReachableHost {
	my $self = shift;
	my %args = @_;
	
	my $adm = $self->{_admin};
	my $host = $args{host};
	
	
}

#TODO gérer les hosts starting, stopping, broken, up, down
sub manageUnreachableHost {
	my $self = shift;
	my %args = @_;
	
	my $STARTING_MAX_TIME = 300;
	my $STOPPING_MAX_TIME = 300;
	
	my $adm = $self->{_admin};
	
	my $host = $args{host};
	$host = "127.0.0.1"; ############ TEMP #######""
	
	eval {
		my @mb_res = $adm->getEntities( type => "Motherboard", hash => { motherboard_internal_ip => $host } );
			
		my $mb = shift @mb_res;
		my $mb_state = $mb->getAttr( name => "motherboard_state" );
		my $state = "something";
		my $state_time = 666;
		
		if ( 	$state eq "up"
			|| 	( $state eq "starting" && $state_time > $STARTING_MAX_TIME )
			||	( $state eq "stopping" && $state_time > $STOPPING_MAX_TIME ) )
		{
			$mb->setAttr( name => "motherboard_state", value => "broken" );
			$mb->save();
		} elsif ( $state eq "stopping" ) {
			# we check if host is really stopped (unpingable)
			my $p = Net::Ping->new();
			my $reachable = $p->ping($host);
			$p->close();
			if ( not $reachable ) {
				$mb->setAttr( name => "motherboard_state", value => "down" );
				$mb->save();
			}
		}
	};
	if ($@) {
		my $error = $@;
		print "===> $error";
	}
}

=head2 updateHostData
	
	Class : Public
	
	Desc : For a host, retrieve value of all monitored data (snmp var defined in conf) and store them in corresponding rrd
	
	Args :
		host : the host name

=cut

sub updateHostData {
	my $self = shift;
	my %args = @_;

	my $host = $args{host};
	#my $session = $self->createSNMPSession( host => $host );
	my $host_state;
	
	print "\n###############   ", $host, "   ##########\n";
	
	eval {
		#For each set of var defined in conf file
		foreach my $set ( @{ $self->{_monitored_data} } ) {

			###################################################
			# Build the required var map: ( var_name => oid ) #
			###################################################
			my %var_map = map { $_->{label} => $_->{oid} } @{ General::getAsArrayRef( data => $set, tag => 'ds') };
			
			#################################
			# Get the specific DataProvider #
			#################################
			# TODO vérifier que c'est pas trop moche (possibilité plusieurs fois le même require,...)
			my $provider_class = $set->{'data_provider'} || "SnmpProvider";
			require "DataProvider/$provider_class.pm";
			my $data_provider = $provider_class->new( host => $host );
			
			################################################################################
			# Retrieve the map ref { var_name => value } corresponding to required var_map #
			################################################################################
			my ($time, $update_values);
			eval {
				($time, $update_values) = $data_provider->retrieveData( var_map => \%var_map );
			};
			if ($@) {
				my $error = $@;
				print  "Error collecting data set  ===> $error";
				if ( "$error" =~ "No response" ) {
					$host_state = $self->hostState( host => $host, reachable => 0 );
					last; # we stop collecting data sets
				}
				next; # continue collecting the other data sets
			}
			
			# DEBUG print values
			print "[", threads->tid(), "]$time : ", join( " | ", map { "$_: $update_values->{$_}" } keys %$update_values ), "\n";
	
			#############################################
			# Store new values in the corresponding RRD #
			#############################################
			my $rrd_name = $self->rrdName( set_name => $set->{label}, host_name => $host );
			$self->updateRRD( rrd_name => $rrd_name, ds_type => $set->{ds_type}, time => $time, data => $update_values );
		}
		# Set host state if no unreachable host error happened
		if (not defined $host_state) {$host_state = $self->hostState( host => $host, reachable => 1 ) };
	};
	if ($@) {
		my $error = $@;
		print "===> $error";
		
		#TODO gérer $host_state dans ce cas (error)
		
	}
	
	
	return $host_state;
	
}

sub hostState {
	my $self = shift;
	my %args = @_;
	
	my $STARTING_MAX_TIME = 300;
	my $STOPPING_MAX_TIME = 300;
	
	my $adm = $self->{_admin};
	
	my $reachable = $args{reachable};
	
	if ( $reachable ) {
		return "up";
	}
	
	my $host = $args{host};
	$host = "10.0.0.1"; ############ TEMP #######""
	
	my $state;
	eval {
		my @mb_res = $adm->getEntities( type => "Motherboard", hash => { motherboard_internal_ip => $host } );
			
		my $mb = shift @mb_res;
		my $mb_state = $mb->getAttr( name => "motherboard_state" );
		$state = "something";
		my $state_time = 666;
		
		if ( 	$state eq "up"
			|| 	( $state eq "starting" && $state_time > $STARTING_MAX_TIME )
			||	( $state eq "stopping" && $state_time > $STOPPING_MAX_TIME ) )
		{
			return 'broken';
		} elsif ( $state eq "stopping" ) {
			# we check if host is really stopped (unpingable)
			my $p = Net::Ping->new();
			my $pingable = $p->ping($host);
			$p->close();
			if ( not $pingable ) {
				return 'down';
			}
		}
	};
	if ($@) {
		my $error = $@;
		print "===> $error";
		return 'unk';
	}
	return $state;
}

# TEST
sub thread_test {
	my $self = shift;
	my %args = @_;
		
	my $adm = $self->{_admin};
	
	my $tid = threads->tid();
	
	#while (1) {
	for (1..10) {
		$self->{_num} = $self->{_num} + 1; 
		print "($tid) : ", $self->{_num}, "\n";
		
		my $mb = $adm->getEntity( type => "Motherboard", id => 1 );
		my $mb_state = $mb->getAttr( name => "motherboard_state" );
		
		print "State : $mb_state\n";
		
		#my $new_state = $mb_state . $tid;
		$mb->setAttr( name => "motherboard_state", value => "pouet" );
		
		print "save...\n";
		#$mb->save();

		sleep(2 - $tid);
	}
	print "($tid) : bye\n";
	return $tid;
}

# TEST
sub update_test {
	my $self = shift;
	
	$self->{_num} = 2;
	
	{#for (1..2) { 
		print "create thread\n";
		my $thr = threads->create('thread_test', $self);
		my $thr2 = threads->create('thread_test', $self);
		my $tid = $thr->join();
		print "============> $tid\n";
		$tid = $thr2->join();
		print "============> $tid\n";
	}
	
	while (threads->list(threads::running) > 0) {
		my $count =threads->list(threads::running);
		print "count: $count\n";
		sleep(1);
	}
	
	print "THREADS: ", threads->list(threads::running), "\n";
	#while (1) {
	#	sleep(60);
	#}
}

=head2 udpate
	
	Class : Public
	
	Desc : Create a thread to update data for every monitored host
	
=cut

sub update {
	my $self = shift;
	
	#$self->{_admin} = Administrator->new( login =>'thom', password => 'pass' );
	
	#my @hosts = $self->retrieveHostsIp();
	my %hosts_by_cluster = $self->retrieveHostsByCluster();
	my @all_hosts_info = map { values %$_ } values %hosts_by_cluster;
	
	#############################
	# Update data for each host #
	#############################
	my %threads = ();
	for my $host_info (@all_hosts_info) {
		# We create a thread for each host to don't block update if a host is unreachable
		#TODO vérifier les perfs et l'utilisation memoire (duplication des données pour chaque thread), comparer avec fork
		my $thr = threads->create('updateHostData', $self, host => $host_info->{ip});
		$threads{$host_info->{ip}} = $thr;
	}
	
	#############################################################
	# Wait end of all threads and get return value (host state) #
	#############################################################
	my %hosts_state = ();
	while ( my ($host_ip, $thr) = each %threads ) {
		$hosts_state{ $host_ip } = $thr->join();
	}
	
	################################
	# update hosts state if needed #
	################################
#	my $adm = $self->{_admin};
#	for my $host_info (@all_hosts_info) {
#		my $host_state = $hosts_state{ $host_info->{ip} };
#		if ( $host_info->{state} ne $host_state ) {
#				my @mb_res = $adm->getEntities( type => "Motherboard", hash => { motherboard_internal_ip => $host_info->{ip} } );
#				my $mb = shift @mb_res;
#				if ( defined $mb ) {
#					$mb->setAttr( name => "motherboard_state", value => $host_state );
#					$mb->save();
#				} else {
#					print "===> Error: can't find motherboard in DB : ip = $host_info->{ip}\n";
#				}
#		}
#	}
	
}

=head2 run
	
	Class : Public
	
	Desc : Launch an update every time_step (configuration)
	
=cut

#TODO with threading we have a "Scalars leaked: 1" printed, harmless, don't worry 
sub run {
	my $self = shift;
	
	while ( 1 ) {
		my $thr = threads->create('update', $self);
		$thr->detach();
		#$self->update();
		
		$self->{_t} += 0.1;
		sleep( $self->{_time_step} );
	}
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut