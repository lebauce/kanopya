#!/usr/bin/perl

use warnings;
use strict;


my $file_path = shift;

my @skip_logs = ("init.php", "/srv/www/bank/images/subdir");

open FILE, "<", $file_path;

my $time_sum = 0;
my $line_count = 0;

LINE:
while (<FILE>) {
    my $line = $_;
    
#    for $m ("server-status", "php", "bank/images") {
#	if ($line =~ $m) {
#	    $count{$m} += 1;
#	}
#    }

    next LINE if ($line =~ "server-status"); # skip monitoring requests
    if (grep { $line =~ $_ } @skip_logs) {
	print "SKIP: $line\n";
	next LINE;
    }
#    print $line;
    my @raw = split ' ';
    my $timers = $raw[-1]; # format: "sec/microsec"
    my $time = (split '/', $timers)[-1];
    #print "$time | ";
    $time_sum += $time;
    $line_count++;
}

my $time_mean = $time_sum / $line_count;

print "=> line count: $line_count\n";
print "=> mean time (microsec): $time_mean\n";
