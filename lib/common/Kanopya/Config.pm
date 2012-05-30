package Kanopya::Config;
use strict;
use warnings;
use XML::Simple;
use Storable 'dclone';

my $config;

BEGIN {

    $config = {
        executor     => XMLin('/opt/kanopya/conf/executor.conf'),
        monitor      => XMLin('/opt/kanopya/conf/monitor.conf'), 
        libkanopya   => XMLin('/opt/kanopya/conf/libkanopya.conf'),
        orchestrator => XMLin('/opt/kanopya/conf/monitor.conf'), 
    }
}

sub get {
    my ($subsystem) = @_;
    # use a copy of the structure to avoid accidental global modifications 
    my $copy = dclone($config);
    if(defined $subsystem && exists $copy->{$subsystem}) {
        return $copy->{$subsystem};
    } else {
        return $copy;
    }
}

1;
