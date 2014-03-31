#!/usr/bin/perl

# Call all kanopya init script with given param

my @services = qw(aggregator collector executor front rulesengine state-manager);

my $cmd = $ARGV[0] or die "Need param start/stop/restart/status";

for my $srv (@services) {
    system "service kanopya-$srv $cmd";
}
