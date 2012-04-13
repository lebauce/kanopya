#!/usr/bin/perl -w

use strict;
use warnings;

open my $package_list,"<", "build_list" or die "open: $!";
chdir("/tmp/kanopya");
my $line;
while ($line = <$package_list>) {
    chomp($line);
    if(!length($line) || $line =~ /^#/) {
	next;
    }
    print "debrsign uploaders\@git.kanopya.org $line"."_*.changes\n";
    system("debrsign uploaders\@git.kanopya.org $line"."_*.changes");
    print "dupload -t kanopya $line"."_*.changes\n";
    system("dupload -t kanopya $line"."_*.changes");
}

close $package_list;
