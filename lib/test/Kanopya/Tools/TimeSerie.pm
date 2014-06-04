# Copyright © 2012 Hedera Technology SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

=pod

=begin classdoc

Kanopya time series generation, manipulation (print, graph, rrd storage) and linking to metrics (mocking)

@see gen_data script (kanopya/tools) for a command line interface of this module

=end classdoc

=cut

package Kanopya::Tools::TimeSerie;

use strict;
use warnings;

use Text::CSV;
use RRDTool::OO;

=pod

=begin classdoc

Instanciate a new TimeSerie

=end classdoc

=cut

sub new {
    my $class = shift;
    my %args = @_;

    my $self = {};
    bless $self, $class;

    return $self;
}

=pod

=begin classdoc

Generate a time serie according to a function

@param func The generation function. Can use vars 'X|Y|Z', 'T' (time) and 'N' (row num)

@optional rows Number of data point to generate. Default 100
@optional precision Hash ref of precision for each func vars ('X','Y','Z'). Default 1 for each
@optional season Saisonality in second (reset all func vars each saison)
@optional srand Seed for the rand
@optional time End time for the series (seconds since Epoch). Default now
@optional step Step in second between two points
@optional noneg Replace generated negative values by 0

=end classdoc

=cut

sub generate {
    my ($self, %args) = @_;

    my ($rows, $func, $prec, $step, $srand, $season) = (
        $args{rows}         || 100,
        $args{func}         || 'rand(X)',
        $args{'precision'}  || {},
        $args{step}         || 1,
        $args{'srand'},
        $args{season}       || {},
    );
    my %precision = %$prec;

    $self->{func} = $func;
    my @func_vars;
    for ('X', 'Y', 'Z') {
        if ($func =~ s/$_/\$vars{$_}/g) {
            push @func_vars, $_;
        }
    }
    $func =~ s/T/\$time/g;
    $func =~ s/N/\$n/g;

    srand $srand if ($srand);

    my $end_time = $args{'time'} || time();
    $end_time -= $end_time % 10; # round time to avoid rrd extrapolation

    my $start_time = $end_time - $step * $rows;

    # Default vars precision
    map { $precision{$_} ||= 1 } @func_vars;

    $self->{precision} = \%precision;

    # Default vars init value
    my %vars = map {$_ => 0} @func_vars;

    my $time = $start_time + $step;

    $season = $args{season}->{'X'};
    # Fill rrd with generated data
    my @serie;
    for my $n (1..$rows) {
        my $value = eval($func);

        $value = (defined $args{noneg} && $value < 0) ? 0 : $value;
        push @serie, $value;

        for my $var (@func_vars) {
            $time += $step;
            $vars{$var} += $precision{$var};
            if (defined $args{season}->{$var} && ($time % $args{season}->{$var}) == 0) {
                $vars{$var} = 0;
            }
        }
    }

    $self->{start_time} = $start_time;
    $self->{end_time}   = $time;
    $self->{step}       = $step;
    $self->{serie}      = \@serie;
    $self->{season}     = $args{season};
}

=pod

=begin classdoc

Store the time serie in rrd

@optional file Output rrd file name
=end classdoc

=cut

sub store {
    my ($self, %args) = @_;

    my $filename = $args{file} || "/tmp/out.rrd";

    my $rows = scalar @{$self->{serie}};

    my $rrd = RRDTool::OO->new( file => $filename );
    $rrd->create(
        start       => $self->{start_time},
        step        => $self->{step},
        data_source => {
            name      => "aggregate",
            type      => "GAUGE"
        },
        archive     => {
            rows      => $rows,
            cfunc     => 'LAST'
        }
    );

    my $time = $self->{start_time} ;
    for (1..$rows) {
        $time += $self->{step};
        my $value = $self->{serie}[$_-1];
        $rrd->update(time => $time, value => $value) if defined $value;
    }

    $self->{rrd} = $rrd;
}

=pod

=begin classdoc

Graph the stored time serie from rrd

=end classdoc

=cut

sub graph {
    my ($self, %args) = @_;

    if (not defined $self->{rrd}) {
        print "time serie must be stored before graphed";
        return;
    }

    my $img_file = "out.png";

    my @prec_info;
    for my $v ('X', 'Y', 'Z') {
        if (defined $self->{precision}{$v}) {
            push @prec_info, ($v . '\:' . $self->{precision}{$v});
        }
    }
    my $prec_string = join  ', ', @prec_info;

    my @comment = ('\n', 'Precision '.$prec_string);
    if (defined $self->{season}) {
        push @comment, ('\n', 'Season ' . $self->{season});
    }

    $self->{rrd}->graph(
        image          => $img_file,
        start          => $self->{start_time},
        end            => $self->{end_time},
        draw           => {
            type   => "line",
            color  => '0000FF',
            legend => $self->{func},
        },
        comment => \@comment,
    );
}

=pod

=begin classdoc

Print the time serie on standard output in specified format

@optional format Format of the output. First term will be replaced by timestamp, second by value

=end classdoc

=cut

sub display {
    my ($self, %args) = @_;

    my $format = $args{format} || '%i %f';

    my $rows = scalar @{$self->{serie}};

    my $time = $self->{start_time} ;
    for (1..$rows) {
        $time += $self->{step};
        my $line = sprintf $format, $time, $self->{serie}[$_-1];
        print $line, "\n";
    }
}

=pod

=begin classdoc

Link the time serie to the specified metric.
Allow mocking historical values of a metric.

@param metric Metric object (Clustermetric)

=end classdoc

=cut

sub linkToMetric {
    my ($self, %args) = @_;

    my $db_name;

    if (defined $args{metric}) {
        $db_name = $args{metric}->id;
    }

    if (defined $args{node} && defined $args{indicator}) {
        $db_name = $args{indicator}->id . '_' . $args{node}->node_hostname;
    }
    $self->_copyRRD(metric_uid => $db_name);
}

=pod

=begin classdoc

Link the time serie to the specified collector indicator for a node.
Allow mocking historical values of a metric.

@param metric Metric object (CollectorIndicator)
@param node Node object

=end classdoc

=cut

sub linkToCollectorIndicator {
    my ($self, %args) = @_;

    my $metric_uid = $args{metric}->indicator_id . '_' . $args{node}->node_hostname;

    $self->_copyRRD(metric_uid => $metric_uid);
}

=pod

=begin classdoc

Copy the time serie rrd to replace existing data for a metric (Aggregator/DataCache)

@param metric_uid uid to identify metric in Aggregator/DataCache system

=end classdoc

=cut

sub _copyRRD {
    my ($self, %args) = @_;

    my $metric_rrd_filename = 'timeDB_' . $args{metric_uid} . '.rrd';
    my $rrd_file = $self->{rrd}->info()->{filename};

    #TODO get from TimeDB the name and path of rrd file
    my $metric_rrd_path     = '/var/cache/kanopya/monitor';

    `cp $rrd_file $metric_rrd_path/$metric_rrd_filename`;
}

=pod

=begin classdoc

Read the data from a CSV file. The CSV contains two columns with headers,
one for the times corresponding to the keys and the other for the values.

@param file File name

@param sep Char separator

@return a hash reference of the historical data

=end classdoc

=cut


sub getTimeserieDatafromCSV {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['file','sep']
                        );
    my %data;

    my $file = $args{'file'};
    my $sep  = $args{'sep'};

    #sep_char used is ';'
    my $csv = Text::CSV->new ({sep_char => $sep});
    open my $io, "<", $file or die "$file: $!";

    LINE:
    while (my $row = $csv->getline($io)) {
        next LINE if ($. == 1);
        die("Exception file : first column not a key") if ( exists $data{$row->[0]} );
        $data{$row->[0]} = $row->[1];
    }
    close $io;

    return \%data;
}

=pod

=begin classdoc

Generate data with generator and link them to a clustermetric (through a RRD database)

@param clustermetric instance to which datas will be linked

=end classdoc

=cut

sub generatemetric {
    my ($self, %args) = @_;
    General::checkParams(args     => \%args);


    $self->generate(func      => $args{'func'},
                    srand     => $args{'srand'},
                    rows      => $args{'rows'},
                    step      => $args{'step'},
                    precision => $args{'precision'},
                    season    => $args{'season'},
                    'time'    => $args{'time'});

    $self->store();
    $self->linkToMetric(%args);
    return;
}


=pod

=begin classdoc

Read the data values from a CSV file. The CSV contains one column with header

@param file File name

@param sep Char separator

@return an array reference of the data values

=end classdoc

=cut

sub getValuesfromCSV {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['file']
                        );
    my @data;

    my $file = $args{'file'};

    #sep_char used is ;
    my $csv = Text::CSV->new();
    open my $io, "<", $file or die "$file: $!";

    my $index= 0;

    LINE:
    while (my $row = $csv->getline($io)) {
        next LINE if ($. == 1);
        $data[$index] = $row->[0];
        $index++;
    }
    close $io;

    return \@data;
}

sub addPeak {
    my ($class, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['func','row'],
                         optional => {height => 1, width => 100});

    my $start = $args{row} - $args{width};
    my $stop  = $args{row} + $args{width};

    my $peak = "(X < $start     ) ? 0 :"
               ."(X < $args{row} ) ? $args{height} * (X - $start) / $args{width} :"
               ."(X < $stop      ) ? $args{height} * ($stop -  X) / $args{width} :"
               .'0';

    return "($peak)+($args{func})";
}
1;
