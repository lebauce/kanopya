#!/usr/bin/perl

use lib qw(/workspace/mcs/Common/Lib);

#use strict;
use warnings;
use XML::Simple;
use General;

sub start {
	my @args = @_;
	
	print "\n###############   ", "Stop current monitoring and clean waiting processes", "   ##########\n";
	stop();
	print "\n###############   ", "Clean data", "   ##########\n";
	clean();
	print "\n###############   ", "Start monitoring", "   ##########\n";
	generate_cronfile( @args );
}

sub stop {
	
	# Remove mcs cron file
	`rm /etc/cron.d/mcs`;
	
	# Kill processes
	my @psaux = `ps aux`;
	for my $ps (@psaux) {
		if ( 	$ps =~ /root[ \t]+([\d]+).*\d:\d{2} (.*collector_script.*)/ ||
				$ps =~ /root[ \t]+([\d]+).*\d:\d{2} (.*retriever_script.*)/ )
		{
			my $pid = $1;
			print "KILL $1 ($2)\n";
			`kill $pid`;
		}
	}
	
}

sub clean {
	
	# rm monitoring directories
	# TODO get directory path from conf (warning: if we change conf then we clean -> problem!)
	print "RM /var/cache/mcs/monitor\n";
	`rm -r /var/cache/mcs/monitor`;
	
	print "RM /tmp/monitor\n";
	`rm -r /tmp/monitor`; 
}


sub generate_cronfile {
	my %args = @_;
	my $opts = $args{opts};
	my $opt = shift @$opts;
	 
	if ( defined $opt && $opt eq 'custom') {
		$env = "MCS_ADMIN_WRAPPER=CustomAdmin";
	}
	
	my $config      = XMLin("/workspace/mcs/Monitor/Conf/monitor.conf");
	my $all_conf    = General::getAsArrayRef( data => $config, tag => 'conf' );
	my @conf        = grep { $_->{label} eq $config->{use_conf} } @$all_conf;
	my $conf        = shift @conf;
	my $monit_delay = $conf->{time_step};
	
	my $graph_conf      = $conf->{generate_graph};
	my $gen_graph_delay = $graph_conf->{time_step};
	
	print "=> update monitoring every $monit_delay seconds\n";
	print "=> generate graph every $gen_graph_delay seconds\n";
	
	open FILE, ">/tmp/mcs.cron.tmp";
	
	my $cmd = cronCmd( 	time_step => $gen_graph_delay,
						env => $env,
						cmd => "perl /workspace/mcs/Monitor/Bin/retriever_script.pl --generate-graph > /tmp/gengraph_cron.out 2> /tmp/gengraph_cron.error");
	print $cmd;
	print FILE $cmd;
	
	$cmd = cronCmd( 	time_step => $monit_delay,
						env => $env,
						cmd => "perl /workspace/mcs/Monitor/Bin/collector_script.pl --update > /tmp/monitoring_cron.out 2> /tmp/monitoring_cron.error",);
	print $cmd;
	print FILE $cmd;
	
	close FILE;
	
	
	`cp /tmp/mcs.cron.tmp /etc/cron.d/mcs`;
	
	print " => generated '/etc/cron.d/mcs'\n";
}

sub cronCmd {
	my %args = @_;	

	my $cmd = $args{cmd};
	my $step = $args{time_step};
	my $env = defined $args{env} ? "env $args{env}" : "";

	die "Time step too small, risk of time error with cron" if ( $step < 10 );
	
	my $period = $step;
	my $it = 1;
	while ($period % 60 != 0) {
		++$it;
		$period += $step;
	}	
	
	my $minute_step = $period / 60;
	
	die "Hours not implemented" if ($minute_step >= 60);
	
	my $user = "root";
	my $cron = "*/$minute_step * * * * $user $env $cmd\n";
	for ( my $sleep = $step; $sleep != $period; $sleep += $step ) {
		$cron .= "*/$minute_step * * * * $user sleep " . $sleep . "; $env $cmd\n";
	} 
	
	return $cron;
}

# MAIN
my $cmd = shift;
my @options = @ARGV;

if ( $ENV{USER} ne 'root') {
	print "ERROR: ";
	print "Only root can launch this script. (sudo monitoring.pl ...)\n";
	exit;
}

$cmd->( opts => \@options);