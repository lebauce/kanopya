#!/usr/bin/perl

use lib "/workspace/mcs/Monitor/Lib";

use strict;
use warnings;
use Monitor::Retriever;
use Data::Dumper;
use Proc::PID::File;

my $cmd = shift;

# If already running, then exit
if( Proc::PID::File->running()) {
    print STDERR "Try to launch $0 but an instance is already running => exit\n";
    #$log->warn("$0 already running ; don't start another process");
    exit(1);
}

my $start_time = time();

print "#### monitoring ######\n";
my $retriever = Monitor::Retriever->new();

# MAIN
if ( $cmd eq "fetch" ) {
	$retriever->fetch( rrd_name => shift );
}
elsif ( $cmd eq "--generate-graph" || $cmd eq "-gg" ) {
	my %files = $retriever->graphFromConf();
	#print Dumper \%files;
	print "# generate graph time => ", time() - $start_time, "\n";
}
elsif ( $cmd eq "graph" ) {
	my $set = shift;
	my $var = shift;
	my $files = $retriever->graphNode( time_laps => 600, required_set => $set, required_indicator => $var );
	print Dumper $files;
}
elsif ( $cmd eq "graphcluster" ) {
	my $cluster = shift;
	my $set = shift;
	my $var = shift;
	my ($dir, $file) = $retriever->graphCluster( time_laps => 600, cluster => $cluster, set_name => $set, ds_name => $var );
	`eog $dir/$file`;
}
elsif ( $cmd eq "get" ) {
	#$retriever->getData( rrd_name => "mem_localhost", time_laps => 100, required_ds => ["memAvail", "memTotal"] );
	$retriever->getData( rrd_name => "cpu_localhost", time_laps => 100, percent => 'ok' );
}
elsif ( $cmd eq "rebuild" ) {
	$retriever->rebuild( set_label => shift );
}
elsif ( $cmd eq "clusters" ) {
    my %clusters = $retriever->retrieveHostsByCluster();
    print Dumper \%clusters;
}
elsif ( $cmd eq "hostsip" ) {
    print "===> ", join( ", ", $retriever->retrieveHostsIp()), "\n";
}
elsif ( $cmd eq "test" ) {
	#$retriever->retrieveHosts(); 
	my @a = ({ p1 => 1, p2 => 2, p3 => 10 }, 
			 { p1 => 3, p2 => 10, p3 => 10 } );
	my %res = $retriever->aggregate( hash_list => \@a, f => 'mean' );
	print Dumper \%res;
}
elsif ( $cmd eq "nodes" ) {
	my $cluster = shift;
    my $graph_path = $retriever->graphNodeCount( cluster => $cluster );
    print "open $graph_path\n";
    my $tmp =  `eog /tmp/$graph_path`;
} 
elsif ( $cmd eq 'clusters_data' ) {
	my $set_name = shift || "cpu";
	my $percent = shift;
	my $clusters_data_detailed = $retriever->getClustersData( set => $set_name, time_laps => 100, percent => $percent);
	print "################### DETAILED ####################\n", Dumper $clusters_data_detailed;
	
	my $clusters_data_aggreg = $retriever->getClustersData( set => $set_name, time_laps => 100, aggregate => "mean", percent => $percent);
	print "################### AGGREGATE ####################\n", Dumper $clusters_data_aggreg;
}
elsif ( $cmd eq 'cluster_data' ) {
	my $cluster_name = shift;
	my $set_name = shift || "cpu";
	my $percent = shift;
	my $cluster_data_detailed = $retriever->getClusterData( cluster => $cluster_name, set => $set_name, time_laps => 100, percent => $percent);
	print "################### DETAILED ####################\n", Dumper $cluster_data_detailed;
	
	my $cluster_data_aggreg = $retriever->getClusterData( cluster => $cluster_name, set => $set_name, time_laps => 100, aggregate => "mean", percent => $percent);
	print "################### AGGREGATE ####################\n", Dumper $cluster_data_aggreg;	
}
