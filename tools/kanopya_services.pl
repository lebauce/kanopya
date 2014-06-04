#!/usr/bin/perl

# Call all kanopya init script with given param

use Daemon;

my @services = qw(aggregator collector front executor mail-notifier openstack-sync rulesengine);
# NOT the state-manager

my $cmd = $ARGV[0] or die "Need param start/stop/restart/status";

my @services = @{ Daemon->daemonsToRun() };

foreach my $service (@services) {
    system "service $service $cmd";
}