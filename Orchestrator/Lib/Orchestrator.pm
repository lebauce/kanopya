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
	
	# Get Administrator
	#$self->{_admin} = Administrator->new( login =>'thom', password => 'pass' );
	$self->{_monitor} = Monitor::Retriever->new( );

	
	open FILE, ">/tmp/ochestrator.time";
	close FILE;
	
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
	
	# TODO load from conf
	my @traps = (  { 	
						set_name => 'mem',
						percent => 1, 
						time_laps => 60,
						thresholds => [ { var => "memAvail", min => '60' },
										{ var => "memCached", max => '80' }  ],
					}, 
					{ 	
						set_name => 'cpu',
						percent => 1,
						time_laps => 100,
						thresholds => [ { var => "rawIdleCPU", min => '90' } ]
					},
					{
						set_name => 'apache_stat',
						time_laps => 100,
						thresholds => [ { var => "BytesPerSec", max => '70' },
										{ var => "IdleWorkers", max => '40' } ]
					}
				);
	
	
	my @all_clusters_name = $monitor->getClustersName();
	my @skip_clusters = ();
	for my $cluster (@all_clusters_name) {
		print "# CLUSTER: $cluster\n";
		my $cluster_trapped = 0;
		for my $trap_def ( @traps ) {
			if ($cluster_trapped) {
				print " ==> skip\n";
				last;
			}
			print "	# TRAP: $trap_def->{set_name} (laps: $trap_def->{time_laps})\n";
			my $cluster_data_aggreg = $monitor->getClusterData( 	cluster => $cluster,
																	set => $trap_def->{set_name},
																	time_laps => $trap_def->{time_laps},
																	percent => $trap_def->{percent},
																	aggregate => "mean");
		
			foreach my $threshold ( @{ $trap_def->{thresholds} }) {
				my $value = $cluster_data_aggreg->{ $threshold->{var} };
				if (not defined $value) {
					print "Warning: no value for var '$threshold->{var}' in cluster '$cluster'. Trap ignored.\n";
					next;
				}
				
				# TEMPORARY
				if ( $cluster eq "cluster_1" && $threshold->{var} eq "rawIdleCPU") {
					my $rrd = RRDTool::OO->new( file =>  "/tmp/orchestrator.rrd" );
					$rrd->update( time => time(), values =>  { "rawIdleCPU" => $value });
				}
				
				print "		# THRESHOLD  : $threshold->{var} ", defined $threshold->{max}?"max=$threshold->{max}":"min=$threshold->{min}", " value=$value\n";
				if ( 	( defined $threshold->{max} && $value > $threshold->{max} )
					|| 	( defined $threshold->{min} && $value < $threshold->{min} ) ) {
					print "				======> TRAP!  ($cluster: $threshold->{var} = $value ", defined $threshold->{max}?"> $threshold->{max}":"< $threshold->{min}" ," )\n";
					$self->requireAddNode( cluster => $cluster );
					push @skip_clusters, $cluster;
					$cluster_trapped = 1;
					last;		
				}
			}
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
    my $monitor = $self->{_monitor};
    my $cluster_info = $monitor->getClusterHostsInfo( cluster => $cluster );
    
    #print Dumper $cluster_info;
    
    my $host_starting = 0;
    foreach my $host (values %$cluster_info) {
    	if ($host->{state} eq "starting") {
    		$host_starting = 1;
    		last;
    	}
    }
    
    #return if ($host_starting);
    
    #TODO  Check if there is a corresponding add node operation in operation queue!
    
    #TODO  Select a node
    
    #TODO  Add node
    
    print "====> add node in $cluster\n";
    
    open FILE, ">>/tmp/ochestrator.time";
    print FILE ":".time();
    close FILE;
    
}

sub requireRemoveNode {
	
}

sub createRRD {
	my $self = shift;
	my %args = @_;

	my $var_list = ['rawIdleCPU'];

	my $rrd = RRDTool::OO->new( file =>  "/tmp/orchestrator.rrd" );

	#my $raws = $self->{_period} / $self->{_time_step};
	my $raws = 100;

	my @rrd_params = ( 	'step', $self->{_time_step},
						'archive', { rows	=> $raws }
					 );
	for my $name ( @$var_list ) {
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

	my $graph_filename = "graph_orchestrator.png";

	#my ($set_def) = grep { $_->{label} eq $set_name} @{ $self->{_monitored_data} };
	#my $ds_list = General::getAsArrayRef( data => $set_def, tag => 'ds');


	# get rrd     
	my $rrd = RRDTool::OO->new( file => "/tmp/orchestrator.rrd" );

	my @graph_params = (
							'image' => "/tmp/$graph_filename",
							#'vertical_label', 'ticks',
							'start' => time() - 1000,
							color => { back => "#69B033" },
						
							vrule => { time => time()-200, },
							
							 hrule => { value => 60,
                 						color => "#0000ff",
						                legend => "threshold"
						               },
						);

	#for my $addquery_time ( @{ $self->{_addquery_times} } ) {
	#	push @graph_params, (
	#							vrule => { time => $addquery_time, }
	#						);
	#}

	
	my $var_list = ['rawIdleCPU'];
	
	foreach my $ds (@$var_list) {
		push @graph_params, (
								draw   => {
									#type   => $first == 1 ? "stack" : "stack",
									type => 'line',
									dsname => $ds,# . "_P",
									color => "FF0000",
									legend => $ds,
	  							}	
							);
	}

	# Draw a graph in a PNG image
	$rrd->graph( @graph_params );
	
	#return $graph_filename;
}

=head2 run
	
	Class : Public
	
	Desc : Do the job (check mc state and manage clusters) every time_step (configuration)
	
=cut

sub run {
	my $self = shift;

	$self->createRRD();
	
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