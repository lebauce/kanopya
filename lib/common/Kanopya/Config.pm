package Kanopya::Config;
use strict;
use warnings;
use XML::Simple;
use Storable 'dclone';
use Path::Class;

my $config;
my $kanopya_dir;

BEGIN {
    #get Kanopya base directory
    my $base_dir = file($0)->absolute->dir;
    my @kanopya  = split 'kanopya', $base_dir;
    $kanopya_dir = $kanopya[0];

    $config = {
        executor          => XMLin($kanopya_dir.'/kanopya/conf/executor.conf'),
        executor_path     => $kanopya_dir.'/kanopya/conf/executor.conf',
        monitor           => XMLin($kanopya_dir.'/kanopya/conf/monitor.conf'), 
        monitor_path      => $kanopya_dir.'/kanopya/conf/monitor.conf',
        libkanopya        => XMLin($kanopya_dir.'/kanopya/conf/libkanopya.conf'),
        libkanopya_path   => $kanopya_dir.'/kanopya/conf/libkanopya.conf',
        orchestrator      => XMLin($kanopya_dir.'kanopya/conf/monitor.conf'), 
        orchestrator_path => $kanopya_dir.'/kanopya/conf/monitor.conf',
        aggregator        => XMLin($kanopya_dir.'/kanopya/conf/aggregator.conf'),
        aggregator_path   => $kanopya_dir.'/kanopya/conf/aggregator.conf',
    }
}

sub getKanopyaDir {
    return $kanopya_dir;
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
