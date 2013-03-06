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

Base class to configure a model for the data of a combination.
Can be configured from a start time to a end time.
Once configured, the DatamModel stores the parameters which allow data forecasting

@since    2013-Feb-13
@instance hash
@self     $self

=end classdoc

=cut

package Entity::DataModel;

use base 'Entity';

use strict;
use warnings;

use Kanopya::Exceptions;
use Log::Log4perl "get_logger";
use Data::Dumper;
use List::Util;
use Statistics::R;

my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    combination_id => {
        pattern => '^\d+$',
        is_mandatory => 1,
        is_extended => 0
    },
    node_id => {
        pattern => '^\d+$',
        is_mandatory => 0,
        is_extended => 0
    },
    param_preset_id => {
        pattern => '^\d+$',
        is_mandatory => 0,
        is_extended => 0
    },
    start_time => {
        pattern => '^.*$',
        is_mandatory => 0,
        is_extended => 0
    },
    end_time => {
        pattern => '^.*$',
        is_mandatory => 0,
        is_extended => 0
    },
};

sub getAttrDef { return ATTR_DEF; }

sub methods {
    return {
        predict => {
            description => 'Predict metric values.',
            perm_holder => 'entity',
        }
    };
}

=pod

=begin classdoc

@constructor

Create a new instance of the class. Constructor is overridden to check params.
A DataModel of a NodemetricCombination needs a node_id parameter to specify which node is modeled.

@return a class instance

=end classdoc

=cut

sub new {
    my $class = shift;
    my %args = @_;

    if (defined $args{combination_id}) {
        my $combination = Entity->get(id => $args{combination_id});

        # DataModel of a NodemetricCombination needs a related node
        if ($combination->isa('Entity::Combination::NodemetricCombination')) {
            if (! defined $args{node_id}) {
                $errmsg = "A nodemetric combination datamodel needs a node_id argument";
                throw Kanopya::Exception(error => $errmsg);
            }
        }
        elsif ($combination->isa('Entity::Combination::ClustermetricCombination')) {
            $log->info('Ignoring node_id in the data model of a clustermetric combination');
            $args{node_id} = undef;
        }
    }
    my $self = $class->SUPER::new(%args);
    return $self;
}


=pod

=begin classdoc

Computes the coefficient of determination (or R squared) of a model.

@param data array containing the real data
@param data_model array containing the computed data

@return coefficient of determination (or R squared)

=end classdoc

=cut

sub computeRSquared {
    my ($self, %args) = @_;
    General::checkParams(args     => \%args, required => ['data', 'data_model']);

    # Compute the coefficient of determination according to its formal definition
    my $data_avg = List::Util::sum(@{$args{data}}) / @{$args{data}};
    my $SSerr = List::Util::sum( List::MoreUtils::pairwise {($a - $b)**2} @{$args{data}}, @{$args{data_model}});
    my $SStot = List::Util::sum( map {($_ - $data_avg)**2} @{$args{data}} );

    return (1 - $SSerr / $SStot);
}

=pod

=begin classdoc

Returns the already computed coefficient of determination (or R squared) of a model. Return undef
if the coefficient has not be computed yet

@return coefficient of determination (or R squared)

=end classdoc

=cut

sub getRSquared {
    my ($self, @args) = @_;
    my $pp = $self->param_preset->load();
    return $pp->{rSquared};
}

sub configure {
    throw Kanopya::Exception(error => 'Method not implemented');
}

sub predict {
    throw Kanopya::Exception(error => 'Method not implemented');
}

sub label {
    throw Kanopya::Exception(error => 'Method not implemented');
}


=pod

=begin classdoc

Format the current time in human readable form

@return the time in human readable form

=end classdoc

=cut

sub time_label {
    my $self = shift;

    my $time = time;    # or any other epoch timestamp
    my @months = ("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
    my $format = '%02i-%02i-%02i %02i:%02i';

    my ($sec, $min, $hour, $day,$month,$year) = (localtime($self->start_time))[0,1,2,3,4,5];
    my $start_date = sprintf($format, $month+1, $day, ($year+1900)%100, $hour, $min);

    ($sec, $min, $hour, $day,$month,$year) = (localtime($self->end_time))[0,1,2,3,4,5];
    my $end_date = sprintf($format, $month+1, $day, ($year+1900)%100, $hour, $min);

    return "[$start_date -> $end_date]";
}



=pod

=begin classdoc

Contruct an array of time stamps from a start time to a end time w.r.t. a sampling period (step)

@param start_time the start time
@param end_time the end time
@param sampling_period the sampling period

@return array of time stamps from start_time

=end classdoc

=cut

sub constructTimeStamps {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => ['start_time', 'end_time', 'sampling_period']);

    my @timestamps= ();
    for (my $ts = $args{start_time} ; $ts <= $args{end_time} ; $ts += $args{sampling_period}) {
        push @timestamps, $ts;
    }
    return \@timestamps;
}


=pod

=begin classdoc

Method called from child class instance to compute the forcasting.
By default the method return a hash with two keys 'timestamps' (reference to an array of timestamps)
and 'values' (reference an array of forecasted values).

@param function_args all the arguments of the forcasting function

@optional time_format 'ms' returns time in milliseconds
@optional data_format 'pair' returns an array of references of pair [timestamp, value]

@return the timestamps and forecasted values with the chosen data_format.

=end classdoc

=cut

sub constructPrediction {
    my ($self, %args) = @_;

    my $function_args = $args{function_args};

    # Construct timestamps if not defined
    if (! defined $args{timestamps}) {
        $args{timestamps} = $self->constructTimeStamps(
                                start_time      => $args{start_time},
                                end_time        => $args{end_time},
                                sampling_period => $args{sampling_period},
                            );
    }

    my @predictions;
    my @timestamps_temp;

    # Compute prediction with good format
    for my $ts (@{$args{timestamps}}) {

        $function_args->{ts} = $ts;
        my $value = $self->prediction_function(function_args => $function_args);

        # Need to use a local variable in order to avoid input data (by ref) modification
        my $ts_temp = ($args{time_format} eq 'ms') ? $ts * 1000 : $ts;

        my $prediction;
        if ($args{data_format} eq 'pair') {
            $prediction = [$ts_temp, $value];
        }
        else {
            push @timestamps_temp, $ts_temp;
            $prediction = $value
        }
        push @predictions, $prediction;
    }
    if ($args{data_format} eq 'pair') {
        return \@predictions;
    }
    else {
        return {timestamps => \@timestamps_temp, values => \@predictions};
    }
}


=pod

=begin classdoc

Splits the data into two arrays, one for the times and one for the corresponding values.

@param data the historical data

@return an array reference containing all the times and an array reference of the data values

=end classdoc

=cut

sub splitData {
    my ($self,%args) = @_;

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

    return (\@sorted_all_time_keys, \@sorted_data_values);
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
    my ($self,%args) = @_;

    General::checkParams(args     => \%args,
                         required => ['data_values','lag']
                         );

    my $data_values = $args{'data_values'};
    my $lag         = $args{'lag'};

    my @acf;

    my $path = "/tmp/kanopya/ACF.pdf";

    my $loadvect = "vect <- c (". join(",", @{$data_values}) .")" ;

    # Define an R session
    my $R = Statistics::R->new();

    # Open an R session
    $R->startR();

    #Send the instructions to R
    $R->send(
            qq`
            $loadvect
            pdf("$path")
            r<-acf(vect,$lag)
            \n print(r)
            dev.off()`
        );

    #Get the results (acf)
    my $output_value = $R->get('r$acf');

    my $j = 0;

    for (my $i = 7; $i <= $#{$output_value}; $i++) {

        if( $i % 2 != 0 ) {
            $acf[$j] = ${$output_value}[$i];
            $j++;
        }
    }

    # Close the R session
    $R->stopR();

    return \@acf;
}


=pod

=begin classdoc

Computes the value IC of the confidence interval [-IC,+IC] for a confidence of 95%.

@param data_values the values of the historical data

@return the value of the confidence interval

=end classdoc

=cut

sub confidenceAutocorrelation {
    my ($self,%args) = @_;

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

@return an array references of the positions (array index) of the peaks

=end classdoc

=cut


sub detectPeaks {
    my ($self,%args) = @_;

    General::checkParams(args     => \%args,
                         required => ['IC','tab']
                         );


    my $IC  = $args{'IC'};
    my $tab = $args{'tab'};

    my $data_count    = $#{$tab}+1;
    my $previousSlope = 0;
    my @peaks;

    #For each value of the array $tab
    for (my $i = 1; $i < $data_count; $i++) {

        my $slope = $tab->[$i] - $tab->[$i-1];

        #Take the peaks of the array :the greatest positive values or the smallest negative values
        #If slope*previousSlope<0 it means there is a peak, in our case we take only the concave ones
        #for which the values are > $IC
        if ( ($slope*$previousSlope < 0) && ($tab->[$i-1] > $tab->[$i]) && ($tab->[$i-1] > $IC) ) {
            push @peaks, ($i-1);
        }

        $previousSlope = $slope;
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

@return the maximum number of periodicity, the minimum value of the autocorrelation function of the
periodically peaks and the estimated value of the seasonality

=end classdoc

=cut


sub detectPeriodicity {
    my ($self,%args) = @_;

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
    my $offset  = int(($#{$acf}+1)*0.04);
    my $min_max = $acf->[$peaks->[$pos]];

    for (my $i = $pos+1; $i < $#{$peaks}+1; $i++) {

        #Search for the multiple value of lag given by $peak->[$pos]+1
        if ( (($peaks->[$i]+1) <= ($multiple*($peaks->[$pos]+1)+$offset)) &&
             (($peaks->[$i]+1) >= ($multiple*($peaks->[$pos]+1)-$offset)) ) {

            #Estimates the seasonality
            my $round = int( (($peaks->[$i]+1)/$multiple)+0.5 );

            if ( exists( $value_peak{$round} ) ) {
                $value_peak{$round}++;
            }
            else {
                $value_peak{$round} = 1;
            }

            $multiple++;

            #Change the min_max value of the acf
            if ($acf->[$peaks->[$i]] < $min_max) {
                $min_max = $acf->[$peaks->[$i]];
            }
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
    return ($multiple-1, $min_max, $mode_value_peak);
}


=pod

=begin classdoc

Computes the seasonality by using spectral density.

@param data_values the values of the historical data

@return the seasonality value (if equal to one, it means that there is no seasonality)

=end classdoc

=cut


sub findSeasonalityDSP {
    my ($self,%args) = @_;

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

    my $nameFile = "/opt/kanopya/scripts/R/findFreq.R";
    open (FILE,"<$nameFile") or die"open: $!";

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

@return an array reference of the seasonality values

=end classdoc

=cut

sub findSeasonalityACF {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['data_values']
                         );


    my $data_values = $args{'data_values'};

    #Contains the possible seasonalities obtained by acf
    my @season;

    #Contains the mininum autocorrelation value for each seasonality
    my @min_max_acf;

    #A choice : contains the lag for autocorrelation
    my $lag = int( ($#{$data_values}+1)/2+1 );

     #Returns the ACF of the data values with the specific lag
    my $acf = $self->computeACF('data_values' => $data_values, 'lag' => $lag);

    #Computes the value of the acf for a confidence of 95%
    my $IC = $self->confidenceAutocorrelation('data_values' => $data_values);

    #Approach 2 :ACF
    $log->debug("Approach 2 : ACF");

    #Computes the peaks of the acf
    my $peaks = $self->detectPeaks('IC' => $IC,'tab' => $acf);

    #A call to the detectPeriodicity with each position of the @peaks array
    for (my $pos = 0; $pos < $#{$peaks}+1; $pos++) {

        my ($multiple, $min_max, $mode_value_peak) =
        $self->detectPeriodicity('pos' => $pos, 'acf' => $acf, 'peaks' => $peaks);

        #If we have as many multiple as necessary for $lag,
        #put seasonality into @season and save $min_max corresponding
        my $nb_period = int($lag/$mode_value_peak);

        my $err = int($nb_period*0.6);

        if ($multiple >= $nb_period-$err) {

            push @season, $mode_value_peak;
            push @min_max_acf, $min_max;

        }
    }

    my @sorted_season;

    if (scalar @season != 0) {

        $log->debug('The seasonalities and corresponding min autocorrelations found are:');
        $log->debug("points @season \n");
        $log->debug("value acf @min_max_acf \n");

        #Sort the values of the seasonalities following the values of $min_max_acf
        my %h = map { $season[$_] => $min_max_acf[$_]} (0..$#season);

        @sorted_season = sort { $h{$b} <=> $h{$a} } keys %h;
    }

    return \@sorted_season;
}


=pod

=begin classdoc

Computes the possible values of the seasonality by using the acf and spectral density approaches.

@param data the historical data
@return an array reference of the values of the seasonalities

=end classdoc

=cut


#Call the approaches to find the seasonalities
sub findSeasonality {

    #Get the time serie in the form of a hashTable
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['data']
                         );

    #Get the data values of the time serie in an array
    my ($data_time, $data_values) = $self->splitData('data' => $args{'data'});

    my @season;
    my $seasonal_DSP = $self->findSeasonalityDSP('data_values' => $data_values);
    my $season_ACF   = $self->findSeasonalityACF('data_values' => $data_values);

    if ( ($seasonal_DSP != 1) && ((grep {$_ eq $seasonal_DSP} @{$season_ACF}) == 0) ) {
        push @season, $seasonal_DSP;
    }

    if (scalar @$season_ACF != 0) {
        push  @season, @{$season_ACF};
    }

    $log->debug("The seasonalities @season \n");

    return \@season;
}
1;
