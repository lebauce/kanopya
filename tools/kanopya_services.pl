#!/usr/bin/perl

# Call all kanopya init script with given param

my @services = qw(aggregator collector front executor mail-notifier openstack-sync rulesengine state-manager);

my $cmd = $ARGV[0] or die "Need param start/stop/restart/status";

for my $srv (@services) {
    system "service kanopya-$srv $cmd";
}
