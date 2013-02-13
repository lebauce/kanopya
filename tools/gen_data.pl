#!/usr/bin/perl -w

# Command line interface to Kanopya::Tools::TimeSerie module

use strict;
use warnings;

use Getopt::Long;

use Administrator;
use Entity;
use Kanopya::Tools::TimeSerie;

# ex:
# -func 'z+sin(x)+sin(y)' -r 10000 -p x=0.01 -p y=0.02 -p z=0.001  ==> trend + seasonnality

my %options = ();
my ($display, $format);
my $output_rrd;
my $linkto;
my $help;

my @options_def = (
    ['func=s'       , \$options{func}       , "Generation function (can use vars 'X|Y|Z', 'T' (time), 'N' (row))"],
    ['rows=i'       , \$options{rows}       , 'Number of data point to generate'],
    ['season=i'     , \$options{season}     , 'Saisonnality in second (reset func var each season)'],
    ['srand=i'      , \$options{'srand'}    , 'Rand seed'],
    ['precision=f%' , \$options{'precision'}, 'Precision for each func var (e.g -p X=01 -p Y=2)'],
    ['noneg'        , \$options{noneg}      , 'Replace all generated negative values by 0'],
    ['time=i'       , \$options{'time'}     , 'Start time (second since epoch)'],
    ['rrd'          , \$output_rrd          , 'Output rrd path and name'],
    ['display'      , \$display             , 'Print time serie on stdout (see --format)'],
    ['format=s'     , \$format              , "Format of display (default '%i %f')"],
    ['linkto=i'     , \$linkto              , "ID of the clustermetric to link to time serie"],
    ['help'         , \$help                , 'Display this help'],
);

my %getOptions_def = map { $_->[0] => $_->[1] } @options_def;
my $opt_ok = GetOptions(%getOptions_def);

if ($help) {
    print "Time serie generation, storage (rrd), display and linking to metric\n";
    print "Command line interface to Kanopya::Tools::TimeSerie module\n\n";
    print "OPTIONS:\n";
    for my $opt (@options_def) {
        print "\t--" . $opt->[0] . "\n\t\t" . $opt->[2] . "\n";
    }
    exit;
}

exit if ($opt_ok != 1);

my $time_serie = Kanopya::Tools::TimeSerie->new();
$time_serie->generate( %options );
$time_serie->store(file => $output_rrd);
$time_serie->graph();
$time_serie->display(format => $format) if $display;

if (defined $linkto) {
    Administrator::authenticate(login => 'admin', password => 'K4n0pY4');
    my $metric = Entity->get( id => $linkto );
    $time_serie->linkToMetric( metric => $metric );
}
