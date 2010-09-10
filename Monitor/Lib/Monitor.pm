# Monitor.pm - Object class of Monitor

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
# Created 20 august 2010

=head1 NAME

Monitor - Monitor object

=head1 SYNOPSIS

    use Monitor;
    
    # Creates monitor
    my $monitor = Monitor->new();

=head1 DESCRIPTION

Monitor is the main object used to collect, store and provide hosts informations. 

=head1 METHODS

=cut

package Monitor;

#TODO Modulariser: Collector, DataProvider (snmp, generator,...), DataStorage (rrd, ...), DataManipulator, Grapher, ...
#TODO use Mcs::Exception
#TODO remplacer les prints par des logs

use lib qw(/workspace/mcs/Administrator/Lib /workspace/mcs/Common/Lib);

use strict;
use warnings;
use RRDTool::OO;
use XML::Simple;
use Administrator;
use General;
use Log::Log4perl "get_logger";

use Data::Dumper;


#use enum qw( :STATE_ UP DOWN STARTING STOPPING BROKEN );

# logger
Log::Log4perl->init('/workspace/mcs/Monitor/Conf/log.conf');
my $log = get_logger("monitor");

=head2 new
	
	Class : Public
	
	Desc : Instanciate Monitor object
	
	Return : Monitor instance
	
=cut

sub new {
    my $class = shift;
    my %args = @_;

	my $self = {};
	bless $self, $class;

	$log->info("NEW");

	# Load conf
	my $conf = XMLin("/workspace/mcs/Monitor/Conf/monitor.conf");
	$self->{_time_step} = $conf->{time_step};
	$self->{_period} = $conf->{period};
	$self->{_rrd_base_dir} = $conf->{rrd_base_dir} || '/tmp';
	$self->{_graph_dir} = $conf->{graph_dir} || '/tmp';
	$self->{_monitored_data} = General::getAsArrayRef( data => $conf, tag => 'set' );

	# Get Administrator
	print "get ADMIN\n";
	#$self->{_admin} = Administrator->new( login =>'thom', password => 'pass' );
	print " => ok\n";

	# test (data generator)
	$self->{_t} = 0;
	
    return $self;
}

=head2 retrieveHostsByCluster
	
	Class : Public
	
	Desc : Retrieve the list of monitored hosts
	
	Return : Hash with key the cluster name and value an array ref of host ip address for this cluster
	
=cut

sub retrieveHostsByCluster {
	my $self = shift;

	my $adm = $self->{_admin};
	my @clusters = $adm->getEntities( type => "Cluster", hash => { } );
	my %hosts_by_cluster;
	foreach my $cluster (@clusters) {
		#my @mb_ip;
		my %mb_info;
		foreach my $mb ( values %{ $cluster->getMotherboards( administrator => $adm) } ) {
			#push @mb_ip, $mb->getAttr( name => "motherboard_internal_ip" );
			
			my $mb_name = $mb->getAttr( name => "motherboard_hostname" );
			my $mb_ip = $mb->getAttr( name => "motherboard_internal_ip" );
			my $mb_state_info = $mb->getAttr( name => "motherboard_state" );
			my ($mb_state, $mb_state_time);
			if ($mb_state_info =~ /([a-zA-Z]+):?([\d]*)/) {
				($mb_state, $mb_state_time) = ($1, $2);
			} else {
				print "Error: bad motherboard state format.\n";
				$log->error("Bad motherboard state format.");
				($mb_state, $mb_state_time) = ("unknown", 0);
			}
			
			$mb_info{ $mb_name } = { ip => $mb_ip, state => $mb_state, state_time => $mb_state_time };
		}
		#$hosts_by_cluster{ $cluster->getAttr( name => "cluster_name" ) } = \@mb_ip;
		$hosts_by_cluster{ $cluster->getAttr( name => "cluster_name" ) } = \%mb_info;
	}	
	
	#print Dumper \%hosts_by_cluster;
	
	# TEMPORARY !!
	%hosts_by_cluster = ( 	"cluster_1" => { 	
												'node001' => { ip => 'localhost', state => 'up', state_time => time() },
												'node002' => { ip => '127.0.0.1', state => 'starting', state_time => time() - 600 }
											},
							"cluster_2" => {	
												'node003' => { ip => '192.168.0.123', state => 'down', state_time => time() }
											} 
							);
	
	return %hosts_by_cluster;
}

sub getClustersName {
	my $self = shift;

	my $adm = $self->{_admin};
	my @clusters = $adm->getEntities( type => "Cluster", hash => { } );
	my @clustersName = map { $_->getAttr( name => "cluster_name" ) } @clusters;

	# TEMPORARY !!
	@clustersName = ("cluster_1", "cluster_2");
	
	return @clustersName;
}

=head2 retrieveHosts DEPRECATED
	
	Class : Public
	
	Desc : Retrieve the list of monitored hosts
	
	Return : Array of host ip address
	
=cut

sub retrieveHosts {
	my $self = shift;
	
	my %hosts_by_cluster = $self->retrieveHostsByCluster();
	my @hosts = map { @$_ } values( %hosts_by_cluster );
	
	return @hosts;
}

=head2 retrieveHostsIp
	
	Class : Public
	
	Desc : Retrieve the list of monitored hosts
	
	Return : Array of host ip address
	
=cut

sub retrieveHostsIp {
	my $self = shift;
	
	my @hosts;
	my %hosts_by_cluster = $self->retrieveHostsByCluster();
	foreach my $cluster (values %hosts_by_cluster) {
		foreach my $host (values %$cluster) {
			push @hosts, $host->{'ip'};
		}
	}
	
	return @hosts;
}

sub getClusterHostsInfo {
	my $self = shift;
	my %args = @_;
	
	my $cluster = $args{cluster};
	
	#TODO ne as récupérer tous les clusters mais ajouter un paramètre optionnel à retrieveHostsByCluster pour ne récupérer que certains clusters
	my %hosts_by_cluster = $self->retrieveHostsByCluster();
	return $hosts_by_cluster{ $cluster };
}



############ TEST #################
sub gaussData {
	my $self = shift;
	my %args = @_;
	
	my $var_map = $args{var_map};
	
	my $time = time();
	print "$time : ";
	my %values = ();
	for my $var_name (keys %$var_map) {
		$values{ $var_name } = sin $self->{_t}; 
		print " $var_name : ", $values{ $var_name }, ", ";
	}
	print "\n";
	
	return ($time, \%values);
}


=head2 rrdName
	
	Class : Public
	
	Desc : build the rrd name uniformly.
	
	Args :
		set_name: string: name of the data set stored in the rrd
		host_name: string: name of the host providing the data
	
	Return :
	
=cut

sub rrdName {
	my $self = shift;
	my %args = @_;
	return $args{set_name} . "_" . $args{host_name};
}

=head2 getRRD
	
	Class : Public
	
	Desc : Instanciate a RRDTool object to manipulate the required rrd
	
	Args :
		file : string : the name of the rrd file
	
	Return : The RRDTool object
	
=cut

sub getRRD {
	my $self = shift;
	my %args = @_;

	my $RRDFile = $args{file};
	# rrd constructor (doesn't create file if not exists)
	my $rrd = RRDTool::OO->new( file =>  $self->{_rrd_base_dir} . "/". $RRDFile );

	return $rrd;
}

=head2 createRRD
	
	Class : Public
	
	Desc : Instanciate a RRDTool object and create a rrd
	
	Args :
		dsname_list : the list of var name to store in the rrd
		ds_type : the type of var ( GAUGE, COUNTER, DERIVE, ABSOLUTE )
		file : the name of the rrd file to create
	
	Return : The RRDTool object
	
=cut

sub createRRD {
	my $self = shift;
	my %args = @_;

	my $dsname_list = $args{dsname_list};

	my $rrd = $self->getRRD( file => $args{file} );

	my $raws = $self->{_period} / $self->{_time_step};

	my @rrd_params = ( 	'step', $self->{_time_step},
						'archive', { rows	=> $raws }
					 );
	for my $name ( @$dsname_list ) {
		push @rrd_params, 	(
								'data_source' => { 	name      => $name,
			     	         						type      => $args{ds_type} },			
							);
	}

	# Create a round-robin database
	$rrd->create( @rrd_params );
	
	return $rrd;
}

=head2 rebuild
	
	Class : Public
	
	Desc : Recreate a rrd for all monitored host, all stored data will be lost. Use when configuration (set definition) changes.
	
	Args :
		set_label: the name of the set who changed (corresponding to set label in conf)

=cut

sub rebuild {
	my $self = shift;
	my %args = @_;

	my $set_label = $args{set_label}; 
	
	my ($set_def) = grep { $_->{label} eq $set_label} @{ $self->{_monitored_data} };
	my @dsname_list = map { $_->{label} } @{ General::getAsArrayRef( data => $set_def, tag => 'ds') };
	
	my @hosts = $self->retrieveHostsIp();
	for my $host (@hosts) {
		my $rrd_name = $self->rrdName( set_name => $set_label, host_name => $host );
		$self->createRRD( file => "$rrd_name.rrd", dsname_list => \@dsname_list, ds_type => $set_def->{ds_type} );
	}
}

=head2 updateRRD
	
	Class : Public
	
	Desc : Store values in rrd
	
	Args :
		time: the time associated with values retrieving
		rrd_name: the name of the rrd
		values: hash ref { var_name => value }
		ds_type: the type of data sources (vars)
	
=cut

sub updateRRD {
	my $self = shift;
	my %args = @_;
	
	my $time = $args{time};
	my $rrdfile_name = "$args{rrd_name}.rrd";
	my $rrd = $self->getRRD( file => $rrdfile_name );

	eval {
		$rrd->update( time => $time, values =>  $args{data} );
	};
	# we catch error to handle unexisting file or configuration change.
	# if happens then we create the rrd file. All stored data will be lost.
	if ($@) {
		my $error = $@;
		#print "==> $error\n";
		print "=> Info: update : unexisting RRD file or set definition changed in conf => we (re)create it ($rrdfile_name).\n";
		my @dsname_list = keys %{ $args{data} };
		$rrd = $self->createRRD( file => $rrdfile_name, dsname_list => \@dsname_list, ds_type => $args{ds_type} );
		$rrd->update( time => $time, values =>  $args{data} );
		
		#print "Warning : unexisting RRD file or set definition changed in conf => nothing will be done until you rebuild the corresponding set ($rrdfile_name).\n";
	} 

}



sub logArgs {
	my $sub_name = shift;
	my %args = @_;
	
	$log->debug( "$sub_name( ".join(', ', map( { "$_ => $args{$_}" if defined $args{$_} } keys(%args) )). ");" );
	
}

sub logRet {
	my %args = @_;
	
	$log->debug( "		=> ( ".join(', ', map( { "$_ => $args{$_}" } keys(%args) )). ");" );
}



