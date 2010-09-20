#!/usr/bin/perl

use lib "../Lib"; #TODO replace by absolute path

use strict;
use warnings;
use Orchestrator;

my $orchestrator = Orchestrator->new();

# MAIN
my $sub = shift;
if ( $sub eq "run" ) {
	$orchestrator->run();
} elsif ( $sub eq "graph" ) {
	my $cluster = shift;
	my $file = $orchestrator->graph( cluster => $cluster );
	`eog /tmp/graph_orchestrator_$cluster.png`;
} elsif ( $sub eq "testtime") {
	$orchestrator->_storeTime( cluster => "clusTest", time => '123', op_type => "op_one");
	$orchestrator->_storeTime( cluster => "clusTest", time => '222', op_type => "op_one");
	$orchestrator->_storeTime( cluster => "clusTest", time => '345', op_type => "op_two");
	$orchestrator->_storeTime( cluster => "clusTest", time => '333', op_type => "op_one");
	$orchestrator->_storeTime( cluster => "clusTest", time => '444', op_type => "op_two");
	$orchestrator->_storeTime( cluster => "clusTest", time => '111', op_type => "op_two");
	
	my $file = $orchestrator->_timeFile( cluster => "clusTest"  );
	print "FILE : $file\n";
	print `more $file`, "\n";
	
	my @times = $orchestrator->_getTimes( cluster => "clusTest", op_type => "op_one" );
	print "op one times : @times\n";
	@times = $orchestrator->_getTimes( cluster => "clusTest", op_type => "op_two" );
	print "op two times : @times\n";
	
	`rm $file`;
}