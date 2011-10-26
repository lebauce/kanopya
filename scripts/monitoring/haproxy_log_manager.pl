use LogAnalyzer;
use Data::Dumper;
use XML::Simple;
use Administrator;
use Entity::Cluster;
use Monitor;

my $monitor = Monitor->new();

my $analyzer = LogAnalyzer->new();

my $rootlogdir = "/var/log/kanopya_nodes/requests";

my $time_step = 60;

#$| = 1;

run();

sub parseFile {
    my %args = @_;

    open FILE, "<", $args{file} or die "can't open $args{file}";

    $analyzer->reset();
    while (<FILE>) {
    $analyzer->parse( log => $_ );
    }
    my $stats = $analyzer->getStats();
    return $stats;
}

sub storeStats {
    my %args = @_;
    
    my $data = $args{stats}{'http-in'};

    return if (not defined $data); 

    for my $set ("timers", "conns") {
        my $set_name = "haproxy_$set";
        my $rrd_name = $monitor->rrdName( set_name => $set_name, host_name => $args{cluster_name} );
        $rrd_name .= "_avg";
        print Dumper $data->{$set};
    
        $monitor->updateRRD(
           rrd_name  => $rrd_name,
           set_name  => $set_name,
           ds_type   => 'GAUGE',
           time      => $args{time},
           data      => $data->{$set},
           time_step => $time_step, 
        );
    }

}

sub manageLog {
    my %args = @_;

    my $logdir = "$rootlogdir/$args{host}";
    if ( not -d $logdir ) {
        print "No log for $args{host}\n";
        return;
    }

    my $logfile_path = "$logdir/$args{file}";
    if (-f $logfile_path) {
        print "FILE: $logfile_path\n";
        my $stats = parseFile( file => $logfile_path );
        unlink $logfile_path;
        storeStats(
            stats => $stats,
            cluster_name => $args{cluster_name},
            time => $args{time},
        );
    } else {
        print "No file $logfile_path\n";
    }
}

sub update {
    my %args = @_;

    # Build expected log file name according to time 
    my $last_minute = $args{time} - 60;
    my ($sec,$min,$hour) = localtime($last_minute);
    $min = "0".$min if ( length($min) == 1 ); 
    my $logfile_name = "$hour:$min.log";

    # Browse clusters to parse corresponding log file
    my @clusters = Entity::Cluster->getClusters( hash => { } );
    foreach my $cluster (@clusters) {
        print "Cluster : ", $cluster->toString(), "\n";
        my $master_ip =  $cluster->getMasterNodeIp();
        if (defined $master_ip) {
            manageLog(
                host => $master_ip,
                file => $logfile_name,
                cluster_name => $cluster->toString(),
                time => $args{time},
            );
        }
    }
}

sub init {
    my $conf = XMLin("/opt/kanopya/conf/monitor.conf");
    Administrator::authenticate( login => $conf->{user}{name}, password => $conf->{user}{password} );
}

sub run {

    init();

    # Wait to start exactly at a minute (+1 sec to avoid concurrency with syslog)
    my $wait_sec = 61 - (time() % 60);
    print "waiting $wait_sec sec before start...\n";
    sleep ($wait_sec);

    while ( 1 ) {
        my $start_time = time();
        
        update( time => $start_time);
    
        my $update_duration = time() - $start_time;
        #$log->info( "Manage duration : $update_duration seconds" );
        if ( $update_duration > $time_step ) {
            #$log->warn("Log management duration > to $time_step");
        } else {
            sleep( $time_step - $update_duration );
        }
    }
}
