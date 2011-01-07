package Monitor::Retriever;

use strict;
use warnings;
use List::Util qw(sum);
use XML::Simple;
#use General;

use Data::Dumper;

use base "Monitor";

# logger
use Log::Log4perl "get_logger";
my $log = get_logger("monitor");


# Constructor

sub new {
    my $class = shift;
    my %args = @_;
	
	my $self = $class->SUPER::new( %args );
	
    return $self;
}


=head2 getData
	
	Class : Public
	
	Desc : 	Retrieve from storage (rrd) values for required var (ds).
			For each ds can compute mean value on a time laps or percent value, using all values for the ds collected during the time laps.
	
	Args :
		rrd_name: string: the name of the rrd where data are stored.
		time_laps: int: time laps to consider.
		(optionnal) required_ds: array ref: list of ds name to retrieve. If not defined, get all ds. WARNING: don't use it if 'percent'.
		(optionnal) percent: if defined compute percent else compute mean for each ds. See 'max_def'.
		(optionnal) max_def: array: list of ds name to add to obtain max value (used to compute percent). If not defined, use all ds.
	
	Return : A hash ( ds_name => computed_value )
	
=cut

#TODO gérer le cas où les ds dans max_def ne sont pas toutes dans les required_ds
sub getData {
	my $self = shift;
	my %args = @_;
	
	Monitor::logArgs( "getData", %args );
	
	my $rrd_name = $args{rrd_name};

	# rrd constructor     
	my $rrd = $self->getRRD(file => "$rrd_name.rrd" );

	# Start fetching values
	$rrd->fetch_start( start => time() - $args{time_laps} );
	$rrd->fetch_skip_undef();

	# retrieve array of ds name ordered like in rrd (db column)	
	my $ds_names = $rrd->{fetch_ds_names};
	
	my @max_def = $args{max_def} ? @{ $args{max_def} } : @$ds_names; 
	my %res_data = ( "_MAX_" => [] );

	############################################# 
	# Build ds index map : (ds_name => rrd_idx) #
	#############################################
	
	my $required_ds = $args{required_ds} || $ds_names;
	my %required_ds_idx = ();
	my @max_idx = ();
	foreach my $ds_name (@$required_ds) {
		# find the index of required ds
		my $ds_idx = 0;
		++$ds_idx until ( ($ds_idx == scalar @$ds_names) or ($ds_names->[$ds_idx] eq $ds_name) );
		if ($ds_idx == scalar @$ds_names) {
			die "Invalid ds_name for this RRD : '$args{ds_name}'";	
		}
		$required_ds_idx{ $ds_name } = $ds_idx;
		$res_data{ $ds_name } = [];
		
		if ( 0 < grep { $_ eq $ds_name } @max_def ) {
			push @max_idx, $ds_idx;
		}
	} 
	
	# Check error in max definition
	if ( scalar @max_idx != scalar @max_def) {
		$log->warn("bad ds name in max definition: [ ", join(", ", @max_def), " ]"); 
	}

	################################################
	# Build res data : ( ds_name => [v1, v2, ..] ) #
	################################################
	
	while(my($time, @values) = $rrd->fetch_next()) {
		# compute max value for this row
		if (defined $values[0]) {
			my $max = 0;
			foreach my $idx (@max_idx) { $max += $values[$idx] };			
			push @{ $res_data{ "_MAX_"} }, $max;
		}
		# add values in res_data
		while ( my ($ds_name, $ds_idx) = each %required_ds_idx ) {
			if (defined $values[$ds_idx]) {
				push @{ $res_data{ $ds_name } }, $values[$ds_idx];
			}
		}
	}

	print "\n###############   ", "getData res data   # $args{rrd_name} #", "   ##########\n";
	print Dumper \%res_data;

	######################################################
	# Build resulting hash : ( ds_name => f(v1,v2,...) ) #
	######################################################
	
	my %res = ();
	my $max = sum @{ $res_data{"_MAX_"} };
	delete $res_data{"_MAX_"};
	while ( my ($ds_name, $values) = each %res_data ) {
		my $sum = sum( @$values ) || 0;
		eval {
			if (defined $args{percent}) {
				$res{ $ds_name } = defined $max ? $sum * 100 / $max : undef;
			}
			else { # mean
				$res{ $ds_name } = $sum / scalar @$values;
			}
		};
		if ($@) {
			$res{ $ds_name } = undef;
		}
	}

	# debug
	print "\n###############   ", "getData res", "   ##########\n";
	print Dumper \%res;
	
	Monitor::logRet( %res );
	
	return %res;
}


sub getHostData {
	my $self = shift;
	my %args = @_;
	
	Monitor::logArgs( "getHostData", %args );
	
	my $rrd_name = $self->rrdName( set_name => $args{set}, host_name => $args{host} );
	
	my $set_def = $self->getSetDesc(set_label => $args{set});
	my @max_def;
	if ( $set_def->{max} ) { @max_def = split( /\+/, $set_def->{max} ) };
	if (defined $args{percent} && 0 == scalar @max_def ) {
		$log->warn("No max definition to compute percent for '$args{set}'");
	}
	
	my %host_data = $self->getData( rrd_name => $rrd_name,
									time_laps => $args{time_laps},
									max_def => (scalar @max_def) ? \@max_def : undef,
									percent => $args{percent} );
	
	return \%host_data;
}

sub getClusterData {
	my $self = shift;
	my %args = @_;
	
	#Monitor::logArgs( "getClusterData", %args );
	
	my $rrd_name = $self->rrdName( set_name => $args{set}, host_name => $args{cluster} );
	
	$rrd_name .= "_avg";
	
	my $set_def = $self->getSetDesc(set_label => $args{set});
	my @max_def;
	if ( $set_def->{max} ) { @max_def = split( /\+/, $set_def->{max} ) };
	if (defined $args{percent} && 0 == scalar @max_def ) {
		$log->warn("No max definition to compute percent for '$args{set}'");
	}
	
	my %cluster_data = $self->getData( rrd_name => $rrd_name,
									time_laps => $args{time_laps},
									max_def => (scalar @max_def) ? \@max_def : undef,
									percent => $args{percent} );
	
	return \%cluster_data;
}

#TODO now we store cluster data, so retrieve this data from rrd
sub getClusterData_OLD {
	my $self = shift;
	my %args = @_;
	
	my $aggregate = $args{aggregate};
	
	my $res;
	my %hosts_data = ();
	my $hosts = $self->getClusterHostsInfo( cluster => $args{cluster} );
	
	print "\n###############   Get Cluster Data   #############\n";
	my $up;
	#foreach my $host (@$hosts) { 
	while ( my ($hostname, $host_info) = each %$hosts ) {
		if ( $host_info->{state} =~ "up" ) {
			my $host_data = $self->getHostData( host => $host_info->{ip}, set => $args{set}, time_laps => $args{time_laps}, percent => $args{percent} );
			$hosts_data{ $hostname } = $host_data;
			$up = 1;
		}
		else {
			$hosts_data{ $hostname } = $host_info->{state};
		}
	}
	
	print Dumper \%hosts_data;
	
	die "No node 'up' in cluster '$args{cluster}'" if ( not defined $up );
	
	if ( defined $aggregate ) {
		my @data_list = values %hosts_data;
		my %aggregate_data = $self->aggregate( hash_list => \@data_list, f => $aggregate );
		$res = \%aggregate_data;
	} else {
		$res = \%hosts_data;
	}
	
	print "\n###############   ", "res", "   ##########\n";
	print Dumper $res;
	
	return $res;
}

sub getClustersData {
	my $self = shift;
	my %args = @_;
	
	#$log->debug("##########################################################");
	Monitor::logArgs( "getClusterData", %args );
	
	my %clusters_data = ();
	my @clusters = $self->getClustersName();
	for my $cluster (@clusters) {
		$clusters_data{ $cluster } = $self->getClusterData( cluster => $cluster,
													 set => $args{set},
													 time_laps => $args{time_laps},
													 percent => $args{percent},
													 aggregate => $args{aggregate});
	}
	return \%clusters_data;
}


#TODO amélioration
sub fetch {
	my $self = shift;
	my %args = @_;

	my $rrd_name = $args{rrd_name};

	# rrd constructor     
	my $rrd = $self->getRRD(file => "$rrd_name.rrd" );

	# Start fetching values from one day back, 
	# but skip undefined ones first
	$rrd->fetch_start( start => time() - 60);
	$rrd->fetch_skip_undef();

	# Fetch stored values
	while(my($time, @values) = $rrd->fetch_next()) {
		print "$time: ", ( map { (defined $_ ? $_ : "[undef]") . " | " } @values ), "\n";
		print ("SUM = ", sum(@values), "\n") if defined $values[0];
	}
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut