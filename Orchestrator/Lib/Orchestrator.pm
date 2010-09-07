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
use Monitor;
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
	$self->{_monitor} = Monitor->new( );

	
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
	my $clusters_data = $monitor->getClustersData( set => "mem", time_laps => 100);
	print Dumper $clusters_data;
	
	$clusters_data = $monitor->getClustersData( set => "mem", time_laps => 100, aggregate => "mea");
	print Dumper $clusters_data;
	
	while (my ($cluster, $cluster_data) = each %$clusters_data ) {
		while ( my ($host, $host_data) = each %$cluster_data ) {
			
		}
	}
	
	
	
	
	
}

=head2 run
	
	Class : Public
	
	Desc : Do the job (check mc state and manage clusters) every time_step (configuration)
	
=cut

sub run {
	my $self = shift;
	
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