#!/usr/bin/perl

use lib "../Lib"; #TODO replace by absolute path

use strict;
use warnings;
use Monitor::Retriever;
use Data::Dumper;

print "#### monitoring ######\n";
my $collector = Monitor::Retriever->new();

# MAIN
my $cmd = shift;
if ( $cmd eq "fetch" ) {
	$collector->fetch( rrd_name => shift );
} elsif ( $cmd eq "graph" ) {
	print Dumper $collector->makeGraph( time_laps => 600);
} elsif ( $cmd eq "get" ) {
	#$collector->getData( rrd_name => "mem_localhost", time_laps => 100, required_ds => ["memAvail", "memTotal"] );
	$collector->getData( rrd_name => "cpu_localhost", time_laps => 100, percent => 'ok' );
} elsif ( $cmd eq "rebuild" ) {
	$collector->rebuild( set_label => shift );
} elsif ( $cmd eq "hosts" ) {
    $collector->retrieveHostsByCluster();
} elsif ( $cmd eq "hostsip" ) {
    print "===> ", join( ", ", $collector->retrieveHostsIp()), "\n";
} elsif ( $cmd eq "test" ) {
	#$collector->retrieveHosts();
	
	
	my @a = ({ p1 => 1, p2 => 2, p3 => 10 }, 
			 { p1 => 3, p2 => 10, p3 => 10 } );
	my %res = $collector->aggregate( hash_list => \@a, mean => 1 );
	print Dumper \%res;
} elsif ( $cmd eq "thr" ) {
    $collector->update_test();
}
