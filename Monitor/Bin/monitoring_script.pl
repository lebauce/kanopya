#!/usr/bin/perl

use lib "../Lib"; #TODO replace by absolute path

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
	$monitor->makeGraph( );
} elsif ( $sub eq "get" ) {
	$monitor->getData( set_label => shift, nb => 10, ds_name => shift, percent => 'ok' );
} elsif ( $sub eq "rebuild" ) {
	$monitor->rebuild( set_label => shift );
}