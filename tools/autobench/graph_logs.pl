#!/usr/bin/perl

use warnings;
use strict;
use Getopt::Std;
use DateTime::Format::Strptime;
use Chart::Gnuplot;

my %opts;
getopt('pf', \%opts);

my $file_path = $opts{f};
my $pattern = $opts{p} || ".*";
my $data_idx = shift;
my $time_idx = shift || 4;

my @skip_logs = ('/bank/images/');#("init.php", "/srv/www/bank/images/subdir");
my $date_analyser = DateTime::Format::Strptime->new( pattern => '%T' );

open FILE, "<", $file_path;

my (@x, @y);
#my @graph_data;
my $line_count = 0;

LINE:
while (<FILE>) {
    my $line = $_;

#    next LINE if ($line =~ "server-status"); # skip monitoring requests
#    if (grep { $line =~ $_ } @skip_logs) {
	#print STDERR "SKIP: $line\n";
#	next LINE;
#    }

    next if ($line !~ $pattern);

    print $line;
    my @raw = split ' ';
    
    # Data idx is a script option, if not defined then let the user select it
    if ( not defined $data_idx) {
	my $i = 0;
	map { print $i++, " : $_\n" } @raw;
	print "Time index: ";
	$time_idx = <STDIN>;
	print "Data index: ";
	$data_idx = <STDIN>;
    }

    my $data_raw = $raw[ $data_idx ]; # format: "sec/microsec"
    my $data = (split '/', $data_raw)[-1];
    #print "$time | ";
    #$data_sum += $data;
    $line_count++;

    #last if ($line_count == 1000);

    my $date_time = $raw[ $time_idx ];
    #$date_time =~ '[^:]*:(.*)';
    $date_time =~ '.*([0-9]{2}:[0-9]{2}:[0-9]{2})';
    #$date_time = substr($date_time, 1);
    my $time = $1;
    my $epoch = $date_analyser->parse_datetime( $time )->set_time_zone( 'local' )->epoch();
    
    print "$epoch : $data\n";
 #   push @graph_data, { time => $epoch, value => $data };

    push @x, $epoch;
    push @y, $data;
}

print STDERR "[$line_count] Gen graph...\n";

my $output = "graph.png";

    
    # Create chart object and specify the properties of the chart
    my $chart = Chart::Gnuplot->new(
        output => "$output",
        title  => "$file_path",
        xlabel => "epoch",
        ylabel => "$pattern",#."idx$data_idx",
	bg => "white",
   );
    
    # Create dataset object and specify the properties of the dataset
    my $dataSet = Chart::Gnuplot::DataSet->new(
        xdata => \@x,
        ydata => \@y,
        #title => "Plotting a line from Perl arrays",
        style => "points",
  
    );
    
    # Plot the data set on the chart
    $chart->plot2d($dataSet);


`eog $output`;
