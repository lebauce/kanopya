#!/usr/bin/perl

# Automate bench launch, logs retrieving and stats

# WARNING:
# To run this script you need ssh key authentication on all remote machines (specweb clients, besim, admin) 
# > ssh-copy-id root@ip

# ASSERT specweb conf USE_GUI=0

use strict;
use warnings;
use Template;
use Data::Dumper;

use OpenOffice::OODoc; # libopenoffice-oodoc-perl

my $SPECWEB_DIR = "/web2005-1.31";

my @frontend_nodes  = ("10.1.2.2");
my @backend_nodes   = ("10.1.2.253");
my @nodes = (@frontend_nodes, @backend_nodes);
my @tiers = ("ServerBench", "BeSim");
my $ADMIN_IP        = "10.1.2.1";

my $frontend_log_path   = "/tmp/apache_access.log";
my $backend_log_path    = "/var/log/apache2/access.log";

my @sessions_evo = (50,100,150,200,250,300,350,400,450,500,550,600,650,700);

# Copy <src_path> from <ip> to <dest_path> on localhost
sub scp {
    my %args = @_;
    my $cmd =  'scp root@' . "$args{ip}:$args{src_path} $args{dest_path}";
    `$cmd`;
}

# ssh on <ip> and execute <cmd>
sub ssh {
    my %args = @_;
    my $cmd = 'ssh root@' .  "$args{ip} '$args{cmd}'";
    `$cmd`;
}

# Clear apache log file content on nodes
sub clearApacheLogs {
    my %logs = ($frontend_log_path => \@frontend_nodes, $backend_log_path => \@backend_nodes);
    while (my ($log_path, $ips) = each %logs) {
        for my $ip (@$ips) {
            #ssh( ip => $ip, cmd => "> $log_path");
            ssh( ip => $ADMIN_IP, cmd => 'ssh -i /root/.ssh/kanopya_rsa root@' . $ip . " \"> $log_path\""); 
        }
    }
}

sub getApacheLogs {
    my %args = @_;
    my $dest_dir = $args{dest_dir};

    my %logs = ($frontend_log_path => \@frontend_nodes, $backend_log_path => \@backend_nodes);
    while (my ($log_path, $ips) = each %logs) {
        for my $ip (@$ips) {
            my $tmp_path = "/tmp/$ip" . "_access.log";

            # Get log from node to admin    
            ssh( ip => $ADMIN_IP, cmd => 'scp -i /root/.ssh/kanopya_rsa root@' . $ip . ':' . $log_path . " $tmp_path" );

	        # Get apache log file from admin
	        #scp( ip => $ip, src_path => $log_path, dest_path =>  "$dest_dir/$ip" . "_access.log");
	        scp( ip => $ADMIN_IP, src_path => $tmp_path, dest_path =>  "$dest_dir/$ip" . "_access.log");
        }
    }
}

sub getOrchestratorLogs {
    my %args = @_;
    my $dest_dir = $args{dest_dir};

    my $ip = $ADMIN_IP;
    my $orchestrator_log_file = "/var/log/kanopya/orchestrator.log";
    my $grep_regexp = '": Monitored"';
    
    #my $lookback_minute = 60;
    #my $tail_lines = $lookback_minute * 4; # 2 lines (latency and throughput) for 2 tiers;
    
    # Extract useful lines from logs on admin
    ssh( ip => $ip, cmd => "grep $grep_regexp $orchestrator_log_file > /tmp/orchestrator.log");
    
    # Get this file
    scp( ip => $ip, src_path => "/tmp/orchestrator.log", dest_path => "$dest_dir/orchestrator.log" );
}

sub getSpecWebResult {
    my %args = @_;
    my $dest_dir = $args{dest_dir};

    my $dir = "$SPECWEB_DIR/Prime_Client/results";
    
    my $cmd = "find $dir/* -cmin -5"; # Find files modified during last x minutes
    my $cmd_res = `$cmd`;
    my @files = split "\n", $cmd_res;
    for my $file (@files) {
	`cp $file $dest_dir/`;
    }
}

sub getLogs {
    my %args = @_;
    getSpecWebResult(%args);
    getApacheLogs(%args);
    clearApacheLogs();
    getOrchestratorLogs(%args);
}

sub launchBench {
    #system( "perl specweb_clients.pl bench" );
    `perl specweb_clients.pl bench > specweb.out 2> specweb.err`;
}

sub extractInfo {
    my %args = @_;
    my $dir = $args{dir};

    my %info = ( dir => $dir);

    # Info from apache logs
    for my $ip (@frontend_nodes, @backend_nodes) {
        # Gloups TODO do func call instead of perl script exec in a perl script and stdout parse...
        my $cmd = "./parse_apache_log.pl $dir/$ip" . "_access.log";
        my $out = `$cmd`;
        $out =~ '=> line count: ([0-9]*)';
        $info{$ip}{apache}{line_count} = $1;
        $out =~ '=> mean time.*: ([0-9.]*)';
        $info{$ip}{apache}{latency} = $1;
    }

    # Info from SpecWeb res
    my $res = (split "\n", `grep "Iteration 1" $dir/SPECweb_Banking*txt`)[0];
    for my $field ('sessions', 'requests', 'reqs/sec/session', 'errors') {
        $res =~ "([0-9.]*) $field";
        $info{spec}{$field} = $1;
    }
    my $totals = (split "\n", `grep TOTAL $dir/SPECweb_Banking*txt`)[-1];
    my $avg_resp = (split " ", $totals)[7];
    $info{spec}{avg_resp_time} = $avg_resp;

    # Info from orchestrator logs
    my $log_offset = 2; # control wich logs set we want (last, last-1, last-2..) => 1 = last
    my $cmd = "tail -" . (8*$log_offset) . " $dir/orchestrator.log | tac | tail -8 | grep ', [0-9]*min'";
    my @logs = split "\n", `$cmd`;
    print Dumper @logs;
    for my $log (@logs) {
        my $value = (split ' ', $log)[-1];
        for my $tier (@tiers) {
            if ($log =~ $tier) {
                my %fields = ('apache' => 'throughput', 'Haproxy' => 'latency');
                while (my ($comp, $metric) = each (%fields)) {
                    if ($log =~ $metric) {
                        $info{$tier}{$comp}{$metric} = $value;
                    }
                }
            }        
        }
    }

#    print Dumper \%info;

    return \%info;
}

my @spec_fields = ('sessions', 'requests', 'reqs/sec/session', 'errors', 'avg_resp_time');
my @node_fields = ({name =>'apache', fields => ['latency', 'line_count'] });
my @tier_fields = ({name => 'apache', fields => ['throughput'] }, {name => 'Haproxy', fields => ['latency'] });

my $table_name = "RESULTS";


# Add head in spreadsheet
sub addHead {
    my %args = @_;

    my ($sheet) = ($args{sheet});

    my $row = 0;

    $sheet->cellValue($table_name, $row++, 0, "dir");

    for my $field (@spec_fields) {
         $sheet->cellValue($table_name, $row++, 0, "spec.$field");
    }
    
    for my $data (  { entities => \@nodes, fields => \@node_fields },
                    { entities => \@tiers, fields => \@tier_fields }) {
        for my $entity (@{$data->{entities}}) {
            for my $comp (@{$data->{fields}}) {
                for my $field (@{ $comp->{fields} }) {
                    $sheet->cellValue($table_name, $row++, 0, "$entity.$comp->{name}.$field");  
                }
            }        
        }   
    }
#    for my $node (@frontend_nodes, @backend_nodes) {
#        for my $comp (@node_fields) {
#            for my $field (@{ $comp->{fields} }) {
#                $sheet->cellValue($table_name, $row++, 0, "$node.$comp->{name}.$field");  
#            }
#        }
#    }


}

# Add info of a bench in spreadsheet
sub addInfo {
    my %args = @_;

    my ($sheet, $info, $col) = ($args{sheet}, $args{info}, $args{col});   
    my $row = 0;

    $sheet->cellValue($table_name, $row++, $col, $info->{dir});

    for my $field (@spec_fields) { 
        my $cell = $sheet->getCell($table_name, $row, $col);
        $sheet->cellValueType($cell, 'float');
        $sheet->cellValue($table_name, $row++, $col, $info->{spec}{$field});
    }
    
     for my $data (  { entities => \@nodes, fields => \@node_fields },
                    { entities => \@tiers, fields => \@tier_fields }) {
        for my $entity (@{$data->{entities}}) {
            for my $comp (@{$data->{fields}}) {
                for my $field (@{ $comp->{fields} }) {
                    my $cell = $sheet->getCell($table_name, $row, $col);
                    $sheet->cellValueType($cell, 'float');
                    $sheet->cellValue($table_name, $row++, $col, $info->{$entity}{$comp->{name}}{$field});
                }
            }
        }
    }    
}

sub configBench {
    my %args = @_;

    my $conf_file = "$SPECWEB_DIR/Prime_Client/Test.config";

    print "CONFIG: " . (Dumper \%args) . "\n";
    
    my $tt = Template->new({
        INCLUDE_PATH => '.',
    });

    $tt->process("Test.config.tt", \%args, $conf_file)
        || die "Template error: ", $tt->error(), "\n";
}

sub checkRequirements {
    # TODO check than needed scripts runs
    print "Haproxy log manager runs on admin? [enter]\n";
    <STDIN>;
}

sub run {
    mkdir "res" unless (-d "res");

    print "Check requirements\n";
    checkRequirements();

    print "Clear apache logs on nodes before bench...\n";
    clearApacheLogs();

    for my $sessions (@sessions_evo) {

        my $date = `date +%F_%R`; # format = yyyy-mm-dd_hh:mm
        chomp $date;
        my $dir = "res/$date";
        unless (-d $dir) {
            mkdir $dir or die $!;
        }

        print "#### CONFIGURE BENCH #####\n";
        configBench( simultaneous_sessions => $sessions );
        print "#### LAUNCH BENCH #####\n";
        launchBench();
        print "#### GET LOGS #####\n";
        getLogs( dest_dir => $dir);
        #print "#### EXTRACT INFO #####\n";
        #extractInfo( dir => $dir );
    }
}


# If <dir> is specified then stat this dir else stat and report all dirs under res/
sub stats {
    my %args = @_;
    
    my @dirs = defined $args{dir} ? ($args{dir}) : map { "res/$_" } (split ' ', `ls res`);
    
    my $sheet = odfDocument(file => 'res.ods', create => 'spreadsheet');
    $sheet->appendTable($table_name, 100, 100);

    #displayHeadInfo();
    addHead( sheet => $sheet );

    my $col = 1;
    for my $dir (@dirs) {
        print "$dir\n";
        my $info = extractInfo( dir => $dir );
        #displayRawInfo( info => $info);
        addInfo( sheet => $sheet, info => $info, col => $col++ );
    }

    $sheet->save;
}

## MAIN

my $mode = "";
$SIG{INT} = \&onKill;

my $opt = shift;
if ($opt eq "stat") {
    print "STAT\n";
    my $dir = shift;
    stats( dir => $dir );
} elsif ($opt eq "run") {
    print "RUN\n";
    $mode = "run";
    run();
} else {
    usage();
}

sub usage {
    print "./bench_script.pl stat|run [stat_dir]\n";
}

sub onKill {
    if ($mode eq "run") {
        print "\nKill clients\n";
        system( "perl specweb_clients.pl stop" );
    }
    exit;
}

