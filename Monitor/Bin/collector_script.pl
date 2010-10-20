#!/usr/bin/perl

use lib "/workspace/mcs/Monitor/Lib";

Log::Log4perl->init('/workspace/mcs/Monitor/Conf/log.conf');

use strict;
use warnings;
use Monitor::Collector;
use Data::Dumper;

my $start_time = time();

print "\n########################\n";
print "##     monitoring     ##\n";
print "########################\n";
my $collector = Monitor::Collector->new();

# MAIN
my $cmd = shift;

if ( $cmd eq "--update" ) {
	$collector->update();
	print "# collector script update time => ", time() - $start_time, "\n";
		
} elsif ( $cmd eq "run" ) {
	$collector->run();
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
