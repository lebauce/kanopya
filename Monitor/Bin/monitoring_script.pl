#!/usr/bin/perl

use lib "../Lib"; #TODO replace by absolute path

use strict;
use warnings;
use Monitor;
use Data::Dumper;

print "#### monitoring ######\n";
my $monitor = Monitor->new();

# MAIN
my $sub = shift;
if ( $sub eq "run" ) {
	$monitor->run();
} elsif ( $sub eq "fetch" ) {
	$monitor->fetch( rrd_name => shift );
} elsif ( $sub eq "graph" ) {
	print Dumper $monitor->makeGraph( time_laps => 600);
} elsif ( $sub eq "get" ) {
	#$monitor->getData( rrd_name => "mem_localhost", time_laps => 100, required_ds => ["memAvail", "memTotal"] );
	$monitor->getData( rrd_name => "cpu_localhost", time_laps => 100, percent => 'ok' );
} elsif ( $sub eq "rebuild" ) {
	$monitor->rebuild( set_label => shift );
} elsif ( $sub eq "test" ) {
	#$monitor->retrieveHosts();
	
	
	my @a = ({ p1 => 1, p2 => 2, p3 => 10 }, 
			 { p1 => 3, p2 => 10, p3 => 10 } );
	my %res = $monitor->aggregate( hash_list => \@a, mean => 1 );
	print Dumper \%res;
}