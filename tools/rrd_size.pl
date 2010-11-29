#!/usr/bin/perl

# This script estimates the size of rrd files according to the current monitoring configuration

use lib qw(/workspace/mcs/Common/Lib);

use strict;
use warnings;
use XML::Simple;
use General;

my $BASE_BYTES = 232;
my $DS_DEFAULT_BYTES = 312;
my $VALUE_BYTES = 8;

my $config      = XMLin("/workspace/mcs/Monitor/Conf/monitor.conf");
my $all_conf    = General::getAsArrayRef( data => $config, tag => 'conf' );
my $sets_def 	= General::getAsHashRef( data => $config, tag => 'set', key => 'label' );
my @conf        = grep { $_->{label} eq $config->{use_conf} } @$all_conf;
my $conf        = shift @conf;
my $monit_sets	= General::getAsArrayRef( data => $conf, tag => 'monitor' );
	
my $nb_raws = $conf->{period} / $conf->{time_step}; 

print "################################################\n";
my $total_KB = 0;
foreach my $monit (@$monit_sets) {
	my $set_def = $sets_def->{$monit->{set}};
	my $nb_ds =  scalar @{ General::getAsArrayRef( data => $set_def, tag => 'ds') };
	
	my $nb_bytes = $BASE_BYTES + ( ( $DS_DEFAULT_BYTES + ( $nb_raws * $VALUE_BYTES ) ) * $nb_ds );
	my $nb_KB = int( $nb_bytes / 1024 ) + 1;
	print "$monit->{set}	: $nb_KB"."K" . (defined $set_def->{table_oid} ? " / entry" : "") . "\n";
	
	$total_KB += $nb_KB;
}
my $cluster_KB = $total_KB * 2; # we store total and avg for each set
print "------------------------------------------------\n";
print "min size : $cluster_KB" . "K/cluster + $total_KB" . "K/node\n";
print "################################################\n";
