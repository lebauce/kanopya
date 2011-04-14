#!/usr/bin/perl -w

# Script for retrieve qos metrics from a cluster
# wip

use RRDTool::OO;

my $cluster_public_ip = "192.168.0.150";

my $time_step = 10;

my $rrd_file = "/tmp/perf_$cluster_public_ip.rrd";
my $rrd = RRDTool::OO->new( file =>  $rrd_file );

# RRD definition
$rrd->create(
    step        => $time_step,  # interval

    data_source => { name  => "latency",
		     type => "GAUGE" },                

    data_source => { name=> "throughput",
		     type => "GAUGE" },

    archive     => { rows  => 500 }
    );

# Main loop
while (1) {

    my $start_time = time();
    
    # Collect info
    my $ab_output = `ab -n 1 $cluster_public_ip/index.html`;


    $ab_output =~ /Time per request: *(.*) \[/;
    my $latency = $1;
    $ab_output =~ /Requests per second: *(.*) \[/;
    my $throughput = $1;

    # update RRD
    $rrd->update(time => time(), values => [$latency, $throughput]);

    print "Time per request ==> |$latency|\n";
    print "Throughput ==> |$throughput|\n";

    print "####################\n";
  
    sleep ( $time_step - ( time() - $start_time ) );

}
