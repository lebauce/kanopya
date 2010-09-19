# Orchestrator.pm - Object class of Orchestrator

# Copyright (C) 2009, 2010, 2011, 2012, 2013
#   Free Software Foundation, Inc.

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; see the file COPYING.  If not, write to the
# Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
# Boston, MA 02110-1301 USA.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.
# Created 1 september 2010

=head1 NAME

Orchestrator - Orchestrator object

=head1 SYNOPSIS


=head1 DESCRIPTION

Orchestrator is the main object for mc management politic. 

=head1 METHODS

=cut

package Orchestrator;

use lib qw(/workspace/mcs/Monitor/Lib);

use strict;
use warnings;
use Monitor::Retriever;
use XML::Simple;
use General;

use Data::Dumper;

				
=head2 new
	
	Class : Public
	
	Desc : Instanciate Orchestrator object
	
	Return : Orchestrator instance
	
=cut

sub new {
    my $class = shift;
    my %args = @_;

	my $self = {};
	bless $self, $class;

	# Load conf
	my $conf = XMLin("/workspace/mcs/Orchestrator/Conf/orchestrator.conf");
	$self->{_time_step} = $conf->{time_step};
	$self->{_traps} = General::getAsArrayRef( data => $conf, tag => 'traps' );
	
	# Get Administrator
	#$self->{_admin} = Administrator->new( login =>'thom', password => 'pass' );
	$self->{_monitor} = Monitor::Retriever->new( );
	
    return $self;
}

=head2 manage
	
	Class : Public
	
	Desc : check mc state and manage clusters
	
=cut

sub manage {
	my $self = shift;
	
	print "Manage\n";
	
	my $monitor = $self->{_monitor};

	
	my @all_clusters_name = $monitor->getClustersName();
	my @skip_clusters = ();
	for my $cluster (@all_clusters_name) {
		print "# CLUSTER: $cluster\n";
		my %values = ();
		my $cluster_trapped = 0;
		for my $trap_def ( @{ $self->{_traps} } ) {
			if ($cluster_trapped) {
				print " ==> skip\n";
				last;
			}
			print "	# TRAP: $trap_def->{set} (laps: $trap_def->{time_laps})\n";
			my $cluster_data_aggreg;
			eval {
				$cluster_data_aggreg = $monitor->getClusterData( 	cluster => $cluster,
																		set => $trap_def->{set},
																		time_laps => $trap_def->{time_laps},
																		percent => $trap_def->{percent},
																		aggregate => "mean");
			};
			if ($@) {
				my $error = $@;
				print "=> Error getting data (set '$trap_def->{set}' for cluster '$cluster') : $error\n";
				next;
			}
			foreach my $threshold ( @{ General::getAsArrayRef( data => $trap_def, tag => 'threshold' ) }) {
				
				my $value = $cluster_data_aggreg->{ $threshold->{var} };
				if (not defined $value) {
					print "Warning: no value for var '$threshold->{var}' in cluster '$cluster'. Trap ignored.\n";
					next;
				}
				
				$values{  $threshold->{var} . "_" . $trap_def->{time_laps} } = $value;
				
				print "		# THRESHOLD  : $threshold->{var} ", defined $threshold->{max}?"max=$threshold->{max}":"min=$threshold->{min}", " value=$value\n";
				if ( 	( defined $threshold->{max} && $value > $threshold->{max} )
					|| 	( defined $threshold->{min} && $value < $threshold->{min} ) ) {
					print "				======> TRAP!  ($cluster: $threshold->{var} = $value ", defined $threshold->{max}?"> $threshold->{max}":"< $threshold->{min}" ," )\n";
					$self->requireAddNode( cluster => $cluster );
					push @skip_clusters, $cluster;
					#$cluster_trapped = 1;
					#last;		
				}
			}
		}
		# Store values
		if ( scalar keys %values ) {
			my $rrd = $self->getRRD( cluster => $cluster );
			$rrd->update( time => time(), values => \%values );
		}
	}
	
#TODO à la place de boucler sur trap_set -> cluster -> threshold faire mieux (genre par cluster). attention a l'optim et au nombre de requête au monitor
#	my @skip_clusters = ();
#	for my $trap_def ( @traps ) {
#		print "# Set : $trap_def->{set_name}\n";
#		my $clusters_data_aggreg = $monitor->getClustersData( 	set => $trap_def->{set_name},
#																time_laps => $trap_def->{time_laps},
#																percent => $trap_def->{percent},
#																aggregate => "mean");
#		while (my ($cluster, $cluster_data) = each %$clusters_data_aggreg ) {
#			print "## Cluster : $cluster\n";
#			if ( 0 < grep { $_ eq $cluster } @skip_clusters ) {
#				print "		=> skip\n";
#				next;
#			}
#			foreach my $threshold ( @{ $trap_def->{thresholds} }) {
#				my $value = $cluster_data->{ $threshold->{var} };
#				if (not defined $value) {
#					print "Warning: no value for var '$threshold->{var}' in cluster '$cluster'. Trap ignored.\n";
#					next;
#				}
#				print "### Threshold  : $threshold->{var} ", defined $threshold->{max}?"max=$threshold->{max}":"min=$threshold->{min}", " value=$value\n";
#				if ( 	( defined $threshold->{max} && $value > $threshold->{max} )
#					|| 	( defined $threshold->{min} && $value < $threshold->{min} ) ) {
#					print "======> TRAP!  ($cluster: $threshold->{var} = $value ", defined $threshold->{max}?"> $threshold->{max}":"< $threshold->{min}" ," )\n";
#					$self->requireAddNode( cluster => $cluster );
#					push @skip_clusters, $cluster;
#					last;		
#				}
#			}
#		}
#	}
	
	print "\n###############   CLUSTERS DETAILED   ##########\n";
	#my $clusters_data_detailed = $monitor->getClustersData( set => "cpu", time_laps => 100, percent => 1);
	#print Dumper $clusters_data_detailed;
	
	print "\n###############   CLUSTER DETAILED   ##########\n";
	#my $cluster_data_detailed = $monitor->getClusterData( cluster => "cluster_1", set => "cpu", time_laps => 100, percent => 1);
	#print Dumper $cluster_data_detailed;
	
	print "\n###############   CLUSTERS AGGREG   ##########\n";
	#my $clusters_data_aggreg = $monitor->getClustersData( set => "cpu", time_laps => 100, aggregate => "mean", percent => 1);
	#print Dumper $clusters_data_aggreg;

	print "\n###############   CLUSTER AGGREG   ##########\n";
	my $cluster_data_aggreg = $monitor->getClusterData( cluster => "cluster_1", set => "mem", time_laps => 100, aggregate => "mean", percent => 1);
	print Dumper $cluster_data_aggreg;
	
}

sub requireAddNode { 
	my $self = shift;
    my %args = @_;
    
    my $cluster = $args{cluster};
    
    print "Node required in cluster '$cluster'\n";
    
    ############################################################
    # Check if there is already a node starting in the cluster #
    ############################################################
    my $monitor = $self->{_monitor};
    my $cluster_info = $monitor->getClusterHostsInfo( cluster => $cluster );
    foreach my $host (values %$cluster_info) {
    	if ($host->{state} eq "starting") {
    		print " => A node is alredy starting in cluster '$cluster'\n";
    		return;
    	}
    }
    
    ############################################################################
    # Check if there is a corresponding add node operation in operation queue! #
    ############################################################################
    my $adm = $self->{_admin};
    foreach my $op ( @{ $adm->getOperations() } ) {
    	if ($op->{'TYPE'} eq 'AddMotherboardInCluster') {
    		foreach my $param ( @{ $op->{'PARAMETERS'} } ) {
    			if ( ($param->{'PARAMNAME'} eq 'cluster') && ($param->{'VAL'} eq $cluster) ) {
    				print " => An operation to add node in cluster '$cluster' is already in queue\n";
    				return;
    			}
    		}	
    	}
    }
    
    ############
    # Add node #
    ############
    $self->addNode( cluster => $cluster );
    
    #########################################################
    # Store the time in a file, keeping only last 11 values #
    #########################################################

    
}

=head2 _storeAddTime
	
	Class : Private
	
	Desc : 	Store in a file the time of adding a node in a cluster.
			Keep only the last $NUMBER_TO_KEEP values.
	
	Args :
		time: time in second (since epoch) to store
		cluster: name of the cluster in which we added a node
	
	Return :
	
=cut

sub _storeAddTime {
	my $self = shift;
    my %args = @_;
    
    my $NUMBER_TO_KEEP = 10;
    
    my $cluster = $args{cluster};
    
    open FILE, "</tmp/orchestrator_$cluster.time";
    my $times = <FILE>;
    close FILE;
    my @times = $times ? split( /:/, $times ) : ();
    my @last_times = scalar @times > $NUMBER_TO_KEEP ? @times[$#times + 1 - $NUMBER_TO_KEEP .. $#times] : @times;
    push @last_times, $args{time};
    open FILE, ">/tmp/orchestrator_$cluster.time";
    print FILE join(":", @last_times);
    close FILE;
}

sub addNode {
	my $self = shift;
    my %args = @_;
    
    print "====> add node in $args{cluster_name}\n";
       
    #my $adm = $args{adm};
    my $adm = $self->{_admin};
    
    my $priority = 1000;
    
    my @cluster =  $adm->getEntities(type => 'Cluster', hash => { cluster_name => $args{cluster_name} } );
    my $cluster = pop @cluster;
    
	my @free_motherboards = $adm->getEntities(type => 'Motherboard', hash => { active => 1, motherboard_state => 'down'});
	
	if ( scalar @free_motherboards > 0 ) {
		#TODO  Select the best node ?
		my $motherboard = pop @free_motherboards;
		$adm->newOp(type => 'AddMotherboardInCluster',
					priority => $priority,
					params => {
						cluster_id => $cluster->getAttr(name => "cluster_id"),
						motherboard_id => $motherboard->getAttr(name => 'motherboard_id')
					}
		);
		$self->_storeAddTime( time => time(), cluster => $cluster );
	}
	else {
		print "Warning: No free motherboard to add in cluster '$cluster'";
	}

}

sub requireRemoveNode {
	
}

sub getRRD {
	my $self = shift;
	my %args = @_;
	
	my $cluster = $args{cluster};
	my $rrd_file = "/tmp/orchestrator_$cluster.rrd";
	
	my $rrd;
	if ( -e $rrd_file ) {
		$rrd = RRDTool::OO->new( file =>  $rrd_file );
	} else {
		print "info: create orchestrator rrd for cluster '$cluster'\n";
		$rrd = $self->createRRD( file => $rrd_file );
	}
	return $rrd;
}

sub createRRD {
	my $self = shift;
	my %args = @_;

	# Build list of var to store (all traps var)
	my @var_list = ();
	for my $trap_def ( @{ $self->{_traps} } ) {
		foreach my $threshold ( @{ General::getAsArrayRef( data => $trap_def, tag => 'threshold' ) }) {
			push @var_list, $threshold->{var} . "_" . $trap_def->{time_laps};
		}
	}
	

	my $rrd = RRDTool::OO->new( file =>  $args{file} );

	#my $raws = $self->{_period} / $self->{_time_step};
	my $raws = 100;

	my @rrd_params = ( 	'step', $self->{_time_step},
						'archive', { rows	=> $raws }
					 );
					 
	for my $name ( @var_list ) {
		push @rrd_params, 	(
								'data_source' => { 	name      => $name,
			     	         						type      => 'GAUGE' },			
							);
	}

	# Create a round-robin database
	$rrd->create( @rrd_params );
	
	return $rrd;
}


sub graph {
	my $self = shift;
	my %args = @_;

#    use Log::Log4perl qw(:easy);
#    Log::Log4perl->easy_init({
#        level    => $DEBUG
#    }); 
    
    my $cluster = $args{cluster};
    
	my $graph_filename = "graph_orchestrator_$cluster.png";

	#my ($set_def) = grep { $_->{label} eq $set_name} @{ $self->{_monitored_data} };
	#my $ds_list = General::getAsArrayRef( data => $set_def, tag => 'ds');


	# get rrd     
	my $rrd = RRDTool::OO->new( file => "/tmp/orchestrator_$cluster.rrd" );

	my @graph_params = (
							'image' => "/tmp/$graph_filename",
							#'vertical_label', 'ticks',
							'start' => time() - 1000,
							color => { back => "#69B033" },
							
							lower_limit => 0,
							upper_limit => 100,
							
							#width => 500,
							#height => 500,
							
							#comment => "YEAH !"
							
						);

	# Add vertical lines corresponding to add query times
	open FILE, "</tmp/orchestrator_$cluster.time" || die "Can't open orchestrator time file for cluster '$cluster'";
	my $times = <FILE>;
	close FILE;
	my @addquery_times = split( /:/, $times );
	
	for my $addquery_time ( @addquery_times ) {
		push @graph_params, (
								vrule => { time => $addquery_time },	
							);
	}
	
	for my $trap_def ( @{ $self->{_traps} } ) {
		foreach my $threshold ( @{ General::getAsArrayRef( data => $trap_def, tag => 'threshold' ) }) {
			push @graph_params, (
									draw   => {
										type => 'line',
										dsname => $threshold->{var} . "_" . $trap_def->{time_laps},
										color => $threshold->{color},
										legend => sprintf( "%-25s|", $threshold->{var} . "(" . $trap_def->{time_laps} . ")" ),
		  							},
		  
		  							hrule => {
		  							 	value => $threshold->{min} || $threshold->{max},
                 						color => '#' . $threshold->{color},
						                #legend => $threshold->{var}
						               },
						              
								);
		}
	}

	# Draw the graph in a PNG image
	$rrd->graph( @graph_params );
	
	#return $graph_filename;
}

=head2 run
	
	Class : Public
	
	Desc : Do the job (check mc state and manage clusters) every time_step (configuration)
	
=cut

sub run {
	my $self = shift;
	
	# TEMPORARY
	#$self->createRRD();
	
	while ( 1 ) {
		$self->manage();
		sleep( $self->{_time_step} );
	}
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut