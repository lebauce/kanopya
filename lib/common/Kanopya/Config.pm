package Kanopya::Config;
use strict;
use warnings;
use XML::Simple;
use Storable 'dclone';
use Data::Dumper;
my $config;

BEGIN {

    $config = {
        executor          => XMLin('/opt/kanopya/conf/executor.conf'),
        executor_path     => '/opt/kanopya/conf/executor.conf',
        monitor           => XMLin('/opt/kanopya/conf/monitor.conf'), 
        monitor_path      => '/opt/kanopya/conf/monitor.conf',
        libkanopya        => XMLin('/opt/kanopya/conf/libkanopya.conf'),
        libkanopya_path   => '/opt/kanopya/conf/libkanopya.conf',
        orchestrator      => XMLin('/opt/kanopya/conf/monitor.conf'), 
        orchestrator_path => '/opt/kanopya/conf/monitor.conf',
        aggregator        => XMLin('/opt/kanopya/conf/aggregator.conf'),
        aggregator_path   => '/opt/kanopya/conf/aggregator.conf',
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

sub set {
    my (%args) = @_;
    if(defined $args{config} && exists $config->{$args{subsystem}}) {
        $config->{$args{subsystem}} = $args{config};
        open (my $FILE, ">", $config->{"$args{subsystem}_path"}) 
            or die 'error while loading '.qq[$config->{"$args{subsystem}_path"}: $!]; 
        print $FILE XMLout($config->{$args{subsystem}});
        close ($FILE);
    }
}

1;
