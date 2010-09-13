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
	$orchestrator->graph();
	my $tmp =  `eog /tmp/graph_orchestrator.png`;
}