#!/usr/bin/perl

use strict;
use warnings;

my $cluster_name = 'CLUSTY';


sub balance {
	my %args = @_;
	
	my $load = $args{load};
	
	print "LOAD: $load\n";
	
	my @res_nodes = ();
	open CLUST, "</tmp/virtual_cluster_" . $cluster_name . ".adm" || die "cluster file for $cluster_name not found";
	my @clust_nodes = <CLUST>;
	close CLUST;
	
	my @up_nodes = grep { my ($ip, $state) = split " ", $_; $state =~ 'up' } @clust_nodes;
	
	my $load_avg = $load / scalar @up_nodes;
	
	my @all_nodes = ();
	foreach my $line ( @up_nodes ) {
		chomp($line);
				
		my ($ip) = split " ", $line;

		$line = "$ip virt_var1:$load_avg";
		
		print " => $line\n";
		
		push @all_nodes, $line;
	}
	close CLUST;
	
	
	open NODES, ">/tmp/virtual_nodes.adm";
	print NODES join( "\n", @all_nodes);
	close NODES;
	
}

my $time_unit = 60;
my $y_factor = 10;
my $start = 10;
my $rand_max = 10;

my @steps = (
				{ y => 30, period => 2},
				{ y => 60, period => 0.5},
				{ y => 80, period => 2},
				{ y => 50, period => 1},
				{ y => 45, period => 1},
				{ y => 100, period => 2},
				{ y => 100, period => 3},
				{ y => 70, period => 1},
				{ y => 65, period => 1},
				{ y => 20, period => 4},
		 	);

sub generateLoad {
	
	my $load = 0;

my $start_time = time();

	while (1) {
		
		my $x = time() - $start_time;
	
		my $end = 1; 
		my $t = 0;
		my $y_start = $start * $y_factor;
		for my $step (@steps) {
			my $period = $step->{period} * $time_unit;
			$t += $period;
			if ( $x <= $t ) {
				$x -= ($t - $period);
				$load = f( x => $x, period => $period, y_start => $y_start, y_end => $step->{y} * $y_factor );
				$end = 0;
				last;
			}
			$y_start = $step->{y} * $y_factor;
		}
		
		$start_time = time() if ( $end == 1 );
		
		$load += rand() * $rand_max;
	
#	my $rand = rand() * 20 - 10;
#	$load += $rand;
#	$load = 0 if $load < 0;

		balance( load => $load );
			
		sleep(1);
	}
}

# start at $y_start and reach $y_end in $period seconds
sub f {
	my %args = @_;
	
	#my $rad = (($args{x} % 1200) / 1200) * 2 * 3.1415;
	
	# we scale x in [0, pi/2]
	my $rad = ( $args{x} * 3.1415 ) / ( 2 * $args{period} );
	
	my $relative_height = $args{y_end} - $args{y_start};
	
	my $min = $relative_height > 0 ? $args{y_start} : $args{y_end};
	my $max = $relative_height > 0 ? $args{y_end} : $args{y_start};
	
	$rad += 3.1415 / 2 if ( $relative_height < 0 );
	
	my $sin = ( sin $rad );
	my $res =  $sin > 0 ? $sin : 0;
	$res *= abs $relative_height;
	$res += $min;
		
	return $res;
	
	#return exp $x/1000;
}


generateLoad();
