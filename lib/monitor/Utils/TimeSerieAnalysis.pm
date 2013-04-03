#    Copyright © 2013 Hedera Technology SAS
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

=pod

=begin classdoc

Utility class providing several utils method for analyzing time series.

=end classdoc

=cut

package Utils::TimeSerieAnalysis;

use strict;
use warnings;
use General;
use Statistics::R;
use Utils::R;
use Data::Dumper;
use List::MoreUtils qw(firstidx);

# logger
use Log::Log4perl "get_logger";
my $log = get_logger("");


=pod

=begin classdoc

Measure the accuracy of a theorical dataset compared to real/experimental values (so they must be known),
using different kinds of measures.

@param theorical_data_ref A reference to the theorical dataset (must be stored in an array).
@param real_data_ref A reference to the real dataset (must be stored in an array).

@return A ref to a hash containing several accuracy measures ('me', 'mae', 'mse', 'rmse').

=end classdoc

=cut

sub accuracy {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['theorical_data_ref', 'real_data_ref']);

    my $datasets_length = $self->_checkLength(theorical_data_ref => $args{theorical_data_ref},
                                              real_data_ref      => $args{real_data_ref});

    my @theorical = @{$args{theorical_data_ref}};
    my @real      = @{$args{real_data_ref}};

    my $e_total  = 0;
    my $ae_total = 0;
    my $se_total = 0;

    for my $i (0..$#theorical) {
        my $e = $real[$i] - $theorical[$i];
        $e_total  += $e;
        $ae_total += abs($e);
        $se_total += $e ** 2;
    }

    my $me   = $e_total / $datasets_length;
    my $mae  = $ae_total / $datasets_length;
    my $mse  = $se_total / $datasets_length;
    my $rmse = sqrt($mse);

    my %measures = (
        me   => $me,
        mae  => $mae,
        mse  => $mse,
        rmse => $rmse,
    );
    return \%measures;
}

=pod

=begin classdoc

Ensure that a theorical dataset and a experimental one have the same length (otherwise the accuracy of the
theorical one cannot be measured). If they do, returns this length, else throws an exception.

@param theorical_data_ref A reference to the theorical dataset (must be stored in an array).
@param real_data_ref A reference to the real dataset (must be stored in an array).

@return The datasets length, if it is the same.

=end classdoc

=cut

sub _checkLength {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['theorical_data_ref', 'real_data_ref'],
                         );

    my $theorical_length    = scalar(@{$args{theorical_data_ref}});
    my $experimental_length = scalar(@{$args{real_data_ref}});

    if ($theorical_length != $experimental_length) {
        throw Kanopya::Exception(error => 'Accuracy : trying to compare two different-sized dataset.');
    }
    else {
        return $theorical_length;
    }
}

=pod

=begin classdoc

Take a time serie and generate a fixed one from it. Remove the undef values at the beginning or the end and
replace those at the middle by the average of the total time serie.

@param data A hash containing the data ('timestamp' => value).

@return a fixed version of the data.

=end classdoc

=cut

sub fixTimeSerie {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['timeserie'],
    );

    # Split and sort the data
    my @timestamps = sort {$a <=> $b} keys(%{$args{timeserie}});
    my @values;
    for my $key (@timestamps) {
        push (@values, $args{timeserie}->{$key});
    }

    # Fix the undef first values
    my $isInside = 0;
    my $i        = 0;
    my $begin;
    while ( !$isInside && ($i <= $#timestamps) ) {
        if (defined($values[$i])) {
            $isInside = 1;
            $begin    = $i;
        }
        $i++;
    }

    # Fix the undef last values
    $isInside = 0;
    $i        = $#timestamps;
    my $end;
    while ( !$isInside && ($i >= 0) ) {
        if (defined($values[$i])) {
            $isInside = 1;
            $end      = $i;
        }
        $i--;
    }

    @timestamps = @timestamps[$begin..$end];
    @values     = @values[$begin..$end];

    # Compute the average of the time serie
    my $average = $self->computeAverage('values' => \@values);

    # Fix the undef inside values
    for my $j (0..$#timestamps) {
        if (!defined($values[$j])) {
            $values[$j] = $average;
        }
    }

    my %hash;
    for my $j (0..$#timestamps) {
        $hash{$timestamps[$j]} = $values[$j];
    }

    return {%hash};
}

=pod

=begin classdoc

Compute the average of a time serie, ignore the undef values.

@param values An array containing the values of the time serie.

@return a fixed version of the data.

=end classdoc

=cut

sub computeAverage {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['values'],
    );

    my @values = @{$args{values}};
    my $average = 0;
    for my $value (@values) {
        $average += $value;
    }

    return $average / scalar(@values);
}

=pod

=begin classdoc

Computes the autocorrelation by making a call to R (Project for Statistical Computing).

@param data_values the values of the historical data
@param lag defines the maximum lag for which the acf is computed

@return an array reference which contains the values of the autocorrelation (acf)

=end classdoc

=cut

sub computeACF {
    my ($class,%args) = @_;

    General::checkParams(args     => \%args,
                         required => ['data_values','lag']
                         );

    my $data_values = $args{'data_values'};
    my $lag         = $args{'lag'};

    my $loadvect = "vect <- c (". join(",", @{$data_values}).")" ;
    # Define an R session
    my $R = Statistics::R->new();

    # Open an R session
    $R->startR();
    # Send the instructions to R
    $R->send(
                qq`
                $loadvect
                r<-acf(vect,$lag,plot = FALSE)
                \n print(r)`
            );

    # Get the results (acf) by using the method of Utils::R
    my $output_value = $R->get('r$acf');
    my $acf = Utils::R->convertRacf('R_acf_ref' => $output_value);
    # Close the R session
    $R->stopR();

    return $acf;
}

=pod

=begin classdoc

Computes the value IC of the confidence interval [-IC,+IC] for a confidence of 95%.

@param data_values the values of the historical data

@return the value of the confidence interval

=end classdoc

=cut

sub confidenceAutocorrelation {
    my ($class,%args) = @_;

    General::checkParams(args     => \%args,
                         required => ['data_values']
                        );

    my $data_values = $args{'data_values'};

    #The formula is 2/square root(cardinality of data_values)
    my $IC = 2/sqrt($#{$data_values}+1);
    return $IC;
}

=pod

=begin classdoc

Detects the peaks of the values given in an array by taking only the concave ones for which
the value is higher than the value of the confidence interval.

@param IC the value for the confidence interval [-IC,+IC]
@param tab the values for which the peaks are detected

@return an array reference of the positions (array index) of the peaks

=end classdoc

=cut

sub detectPeaks {
    my ($class,%args) = @_;
    General::checkParams(args     => \%args,
                         required => ['IC','tab']
                         );

    my $IC  = $args{'IC'};
    my $tab = $args{'tab'};

    my $data_count    = $#{$tab}+1;
    my $previous_slope = 0;
    my @peaks;

    #For each value of the array $tab
    for (my $i = 1; $i < $data_count; $i++) {
        my $slope = $tab->[$i] - $tab->[$i-1];

        #Take the peaks of the array :the greatest positive values or the smallest negative values
        #If slope*previous_slope < 0 it means there is a peak, in our case we take only the concave ones
        #for which the values are > $IC
        if ( ($slope*$previous_slope < 0) && ($tab->[$i-1] > $tab->[$i]) && ($tab->[$i-1] > $IC) ) {
            push @peaks, ($i-1);
        }
        $previous_slope = $slope;
    }

    $log->debug("Peaks @peaks \n");

    return \@peaks;
}

=pod

=begin classdoc

Searches if there is also a peak for multiple values of a given peak. This method accepts a given
offset when searching the periodic peaks.

@param pos the position (array index) of peaks array for which the periodicity is computed
@param acf an array containing the values of the autocorrelation
@param peaks the positions of the peaks of the acf array

@return the maximum number of periodicity and the estimated value of the seasonality

=end classdoc

=cut


sub detectPeriodicity {
    my ($class,%args) = @_;

    General::checkParams(args     => \%args,
                         required => ['pos','acf','peaks']
                        );

    my $pos     = $args{'pos'};
    my $acf     = $args{'acf'};
    my $peaks   = $args{'peaks'};

    #Will contain the approximated value of the seasonality with its frequency
    my %value_peak;
    $value_peak {$peaks->[$pos]+1} = 1;

    my $multiple = 2;

    #Possible offset when searching periodicity of the peak
    my $offset  = int( ($#{$acf} + 1) * 0.04);

    for (my $i = $pos+1; $i < $#{$peaks}+1; $i++) {
        #Search for the multiple value of lag given by $peak->[$pos]+1
        if ( (($peaks->[$i] + 1) <= ($multiple * ($peaks->[$pos] + 1) + $offset)) &&
             (($peaks->[$i] + 1) >= ($multiple * ($peaks->[$pos] + 1) - $offset)) ) {

            #Estimates the seasonality
            my $round = int ((($peaks->[$i] + 1) / $multiple) + 0.5);

            if ( exists( $value_peak{$round} ) ) {
                $value_peak{$round}++;
            }
            else {
                $value_peak{$round} = 1;
            }

            $multiple++;
        }

        #Out if the current element is higher than what expecting
        else {
            last if ($peaks->[$i]+1 > $multiple*($peaks->[$pos]+1)+$offset);
       }
    }

    #Computes the seasonality that has a maximal frequency
    my $mode_value_peak = $peaks->[$pos]+1;

    while ( my ($k,$v) = each(%value_peak) ) {
        if ($value_peak{$k} > $value_peak{$mode_value_peak}) {
            $mode_value_peak = $k;
        }
    }

    $log->debug("Multiple ". $pos ." -> ". $multiple." \n");
    return ($multiple-1, $mode_value_peak);
}

=pod

=begin classdoc

Computes the seasonality by using spectral density.

@param data_values the values of the historical data

@return the seasonality value (if equal to one, it means that there is no seasonality)

=end classdoc

=cut


sub findSeasonalityDSP {
    my ($class,%args) = @_;

    General::checkParams(args     => \%args,
                         required => ['data_values']
                        );

    my $data_values = $args{'data_values'};

    # Define the R session
    my $R = Statistics::R->new();

    # Open the R session
    $R->startR();

    # Introduces , into the series (R format)
    my $loadvect = "vect <- c (". join(",", @{$data_values}) .")" ;

    #Get find.freq function to be sent to R
    my $nameFile = "/opt/kanopya/scripts/R/findFreq.R";
    open (FILE,"<$nameFile") or die "open: $!";
    my @find_freq = <FILE>;
    my $find_freq = join("",@find_freq);
    close FILE;

    $R->send(
                qq`
                $find_freq
                $loadvect
                r<-find.freq(vect)
                \n print(r)`
            );

    my $saisonal = $R->get('r');

    # Close the R session
    $R->stopR();

    $log->debug('Approach 1 : DSP (if 1 it means no seasonality) '.$saisonal." points \n");

    return $saisonal;
}

=pod

=begin classdoc

Computes the possible seasonalities based on the autocorrelation (acf).

@param data_values the values of the historical data

@return the number of relevant seasonalities and an array reference of the seasonality values

=end classdoc

=cut

sub findSeasonalityACF {
    my ($class, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['data_values']
                        );
    #relevant seasonalities
    my $relevant_season = 1;
    my $data_values = $args{'data_values'};

    #Contains the possible seasonalities obtained by acf
    my @season;

    #Contains the autocorrelation values for each seasonality
    my @max_acf;

    #A choice : contains the lag for autocorrelation
    my $lag = int( ($#{$data_values}+1)/2 + 1 );

    #Returns the ACF of the data values with the specific lag
    my $acf = $class->computeACF('data_values' => $data_values, 'lag' => $lag);

    #Computes the value of the acf for a confidence of 95%
    my $IC = $class->confidenceAutocorrelation('data_values' => $data_values);

    #Approach 2 :ACF
    $log->debug("Approach 2 : ACF");

    #Computes the peaks of the acf
    my $peaks = $class->detectPeaks('IC' => $IC,'tab' => $acf);

    #A call to the detectPeriodicity with each position of the @peaks array
    for (my $pos = 0; $pos < $#{$peaks}+1; $pos++) {
        my ($multiple, $mode_value_peak) =
            $class->detectPeriodicity('pos' => $pos, 'acf' => $acf, 'peaks' => $peaks);

        #If we have as many multiple as necessary for $lag,
        #put seasonality into @season and save the corresponding acf
        my $nb_period = int($lag / $mode_value_peak);
        my $err       = int($nb_period * 0.6);

        if ( ($multiple >= $nb_period - $err) && ((grep {$_ == $mode_value_peak} @season) == 0) ) {
            push @season, $mode_value_peak;
            push @max_acf, $acf->[$peaks->[$pos]];
        }
    }

    my @sorted_season;

    if (scalar @season != 0) {
        $log->debug('The seasonalities and corresponding min autocorrelations found are:');
        $log->debug("points @season \n");
        $log->debug("values acf @max_acf \n");

        #Sort the values of the seasonalities following the values of the acf
        my %h = map { $season[$_] => $max_acf[$_]} (0..$#season);
        @sorted_season = sort { ($h{$b} <=> $h{$a}) || ($a <=> $b)} keys %h;
        if ( (scalar @sorted_season > 2)                                                        &&
             ($sorted_season[1] > $sorted_season[0])                                            &&
             ($season[(firstidx { $_ ==  $sorted_season[0]} @season) + 1] != $sorted_season[1])    ) {

            $relevant_season = 2;
            }
        $log->debug("ordered seasons @sorted_season \n");
    }

    return ($relevant_season,\@sorted_season);
}


=pod

=begin classdoc

Computes the possible values of the seasonality by using the acf and spectral density approaches.

@param data the historical data (array of values)
@return an array reference of the values of the seasonalities

=end classdoc

=cut


#Call the approaches to find the seasonalities
sub findSeasonality {
    #Get the time serie in the form of a hashTable
    my ($class, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['data']
                        );

    #Get the data values of the time serie in an array
    my $data_values = $args{'data'};
    my @season;
    my $seasonal_DSP = $class->findSeasonalityDSP('data_values' => $data_values);
    my ($relevant_season, $season_ACF)   = $class->findSeasonalityACF('data_values' => $data_values);
    $log->debug($relevant_season);
    if ( ($#$season_ACF+1 != 0) ) {
        for (my $i = 0; $i < $relevant_season; $i++) {
            push @season, $season_ACF->[$i];
        }
    }

    if ( $seasonal_DSP != 1  && ((grep {$_ == $seasonal_DSP} @season) == 0) ) {
        push @season, $seasonal_DSP;
    }

    $log->debug("The seasonalities @season \n");

    return \@season;
}

=pod

=begin classdoc

Splits the data into two arrays, one for the times and one for the corresponding values.

@param data the historical data

@return an array reference containing all the times and an array reference of the data values

=end classdoc

=cut

sub splitData {
    my ($class,%args) = @_;

    General::checkParams(args     => \%args,
                         required => ['data']
                         );

    #Split data hashtable in two time-sorted arrays
    my @time_keys            = keys( %{$args{'data'}} );
    my @sorted_all_time_keys = sort {$a <=> $b} @time_keys;

    my @sorted_data_values;

    #Keep data in order
    for my $key (@sorted_all_time_keys) {
        push @sorted_data_values, $args{data}->{$key};
    }

    return {
        timestamps_ref => \@sorted_all_time_keys,
        values_ref     => \@sorted_data_values,
    };
}

=pod

=begin classdoc

Compute the granularity of the timeserie and the preduct times in points (predict_start and predict_end).

@param timestamps A reference to the timestamps of the time serie.
@param predict_start_tstamps The starting point wished for the prediction, in timestamps.
@param predict_end_tstamps The ending point wished for the prediction, in timestamps.

@return the granularity of the timeserie and the predicts times (in points) in a hash ('granularity' && 
        'predict_start' && 'predict_end').

=end classdoc

=cut

sub computePredictPointsAndGranularity {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['timestamps', 'predict_start_tstamps', 'predict_end_tstamps']);

    # Compute the granularity
    my $granularity = ($args{timestamps}[-1] - $args{timestamps}[0]) / (@{$args{timestamps}} - 1);

    # Compute the horizons
    my $start = ($args{predict_start_tstamps} - $args{timestamps}[0]);
    my $predict_start  = ($start % $granularity) == 0 ? $start / $granularity
                       :                                int($start / $granularity) + 1
                       ;

    my $end = ($args{predict_end_tstamps} - $args{timestamps}[0]);
    my $predict_end  = ($end % $granularity) == 0 ? $end / $granularity
                     :                              int($end / $granularity) + 1
                     ;

    return {
        granularity   => $granularity,
        predict_start => $predict_start,
        predict_end   => $predict_end,
    };

}

1;
