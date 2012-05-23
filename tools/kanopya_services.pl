#!/usr/bin/perl

# Call all kanopya init script with given param

my @services = qw(executor collector grapher orchestrator front);

my $cmd = $ARGV[0] or die "Need param start/stop/restart/status";

for my $srv (@services) {
    system "invoke-rc.d kanopya-$srv $cmd";
}
