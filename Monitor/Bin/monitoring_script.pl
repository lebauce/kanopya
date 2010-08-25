#!/usr/bin/perl

use strict;
use warnings;
use Monitor;

my $monitor = Monitor->new();

# MAIN
my $sub = shift;
if ( $sub eq "run" ) {
	$monitor->run();
} elsif ( $sub eq "fetch" ) {
	$monitor->fetch( rrd_name => shift );
} elsif ( $sub eq "graph" ) {
	$monitor->graph( rrd_name => shift );
} elsif ( $sub eq "get" ) {
	$monitor->getData( rrd_name => shift, nb => 10, ds_name => shift, percent => 'ok' );
}
