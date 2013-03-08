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

Static class which implements DataModel related methods

@since    2013-Feb-13

=end classdoc

=cut


package DataModelSelector;

use warnings;
use strict;
use Data::Dumper;
use BaseDB;
use Utils::Accuracy;
use Statistics::R;
use Utils::R;

use constant {
    DEFAULT_TRAINING_PERCENTAGE => 80,
    BASE_NAME => 'Entity::DataModel::',
    MODEL_CLASSES               => ['LinearRegression',
                                    'LogarithmicRegression',
                                    'AutoArima',
                                    ],
};


use constant CHOICE_STRATEGY => {
    DEMOCRACY => 'DEMOCRACY',
    ME        => 'ME',
    MAE       => 'MAE',
    MSE       => 'MSE',
    RMSE      => 'RMSE',
};

# logger
use Log::Log4perl "get_logger";
my $log = get_logger("");

=pod

=begin classdoc

Class method which configure all the available models for a combination.
Save and returns the model which has the highest R squared error.

@param combination the combination to model
@param start_time define the start time of historical data taken to configure
@param end_time define the end time of historical data taken to configure

@optional node_id modeled node in case of NodemetricCombination
@optional model_list  : The list of the available models for the selection. By default all existing models are
                        used. 

@return the selected model

=end classdoc

=cut


sub selectDataModel {
    my ($class, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['combination', 'start_time', 'end_time'],
                         optional => {'node_id'       => undef, 
                                      'model_list'    => MODEL_CLASSES,
                         });

    my %data = $args{combination}->evaluateTimeSerie(start_time => $args{start_time},
                                                     stop_time  => $args{end_time},
                                                     node_id    => $args{node_id});

    my @data_model_classes = @{$args{model_list}};
    for my $i (0..$#data_model_classes) {
        $data_model_classes[$i] = BASE_NAME . $data_model_classes[$i];
    }

    # Compute the possible seasonality values
    #TODO
    my @freqs = (1,2,3,4);

    # Models with the best freq found {class_name => $freq}
    my %freq_hash;

    # Models with their computed accuracy {class_name => {accuracy}}
    my %accuracy_hash;

    for my $data_model_class (@data_model_classes) {

        # If the model is a seasonal one, try each possible seasonality value and only retain the best one
        if ($data_model_class->isSeasonal()) {

            my %temp_accuracy_hash;

            # Compute the accuracy of the model for each freq
            for my $freq (@freqs) {
                $temp_accuracy_hash{$freq} = $class->evaluateDataModelAccuracy(
                    data_model_class => $data_model_class,
                    data             => {%data},
                    combination      => $args{combination},
                    node_id          => $args{node_if},
                    freq             => $freq,
                );
            }

            # Store the best model retained
            my $best_freq = $class->chooseBestDataModel(accuracy_measures => {%temp_accuracy_hash});
            $freq_hash{$data_model_class}     = $best_freq;
            $accuracy_hash{$data_model_class} = $temp_accuracy_hash{$best_freq};
        }
        else {
            $freq_hash{$data_model_class}     = undef;
            $accuracy_hash{$data_model_class} = $class->evaluateDataModelAccuracy(
                data_model_class => $data_model_class,
                data             => {%data},
                combination      => $args{combination},
                node_id          => $args{node_if},
            );
        }
    }

    # Choose the best DataModel among all
    my $best_data_model = $class->chooseBestDataModel(accuracy_measures => {%accuracy_hash});
    my $best_freq       = $freq_hash{$best_data_model};

    return {
        best_model => $best_data_model,
        best_freq  => $best_freq,
    }
#    my @models;
#    my @RSquareds;
#
#    # Configure all DataModels available
#    for my $data_model_class (@model_classes) {
#
#        BaseDB::requireClass($data_model_class);
#
#        my $model = $data_model_class->new(
#                        node_id        => $args{node_id},
#                        combination_id => $args{combination}->id,
#                    );
#
#        $model->configure(data       => \%data,
#                          start_time => $args{start_time},
#                          end_time   => $args{end_time});
#
#        push @models, $model;
#        push @RSquareds, $model->getRSquared();
#        $log->info("$data_model_class -> R = ".($model->getRSquared())."\n");
#    }
#
#    my $max_model    = shift @models;
#    my $max_RSquared = shift @RSquareds;
#
#    # Choose the DataModem with maximal RSquared, delete all the others
#    while (my $current_model = shift @models) {
#
#        my $current_RSquare = shift @RSquareds;
#
#        if ($current_RSquare > $max_RSquared) {
#             $max_RSquared = $current_RSquare;
#             $max_model->delete();
#             $max_model = $current_model;
#        }
#        else {
#            $current_model->delete();
#        }
#    }
#    $log->info('Best model id '.($max_model->id));
#    return $max_model;
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
    my ($class,%args) = @_;

    General::checkParams(args     => \%args,
                         required => ['data_values','lag']
                         );

    my $data_values = $args{'data_values'};
    my $lag         = $args{'lag'};


    my $path = "/tmp/ACF.pdf";

    my $loadvect = "vect <- c (". join(",", @{$data_values}) .")" ;

    # Define an R session
    my $R = Statistics::R->new();

    # Open an R session
    $R->startR();

    # Send the instructions to R
    $R->send(
                qq`
                $loadvect
                pdf("$path")
                r<-acf(vect,$lag)
                \n print(r)
                dev.off()`
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

@return the maximum number of periodicity, the minimum value of the autocorrelation function of the
periodically peaks and the estimated value of the seasonality

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
    my $min_max = $acf->[$peaks->[$pos]];

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

@return an array reference of the seasonality values

=end classdoc

=cut

sub findSeasonalityACF {
    my ($class, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['data_values']
                        );

    my $data_values = $args{'data_values'};

    #Contains the possible seasonalities obtained by acf
    my @season;

    #Contains the mininum autocorrelation value for each seasonality
    my @min_max_acf;

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
        my ($multiple, $min_max, $mode_value_peak) =
        $class->detectPeriodicity('pos' => $pos, 'acf' => $acf, 'peaks' => $peaks);

        #If we have as many multiple as necessary for $lag,
        #put seasonality into @season and save $min_max corresponding
        my $nb_period = int($lag / $mode_value_peak);
        my $err       = int($nb_period * 0.6);

        if ($multiple >= $nb_period - $err) {
            push @season, $mode_value_peak;
            push @min_max_acf, $min_max;
        }
    }

    my @sorted_season;

    if (scalar @season != 0) {
        $log->debug('The seasonalities and corresponding min autocorrelations found are:');
        $log->debug("points @season \n");
        $log->debug("values acf @min_max_acf \n");

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
    my ($class, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['data']
                        );

    #Get the data values of the time serie in an array
    my ($data_time, $data_values) = $class->splitData('data' => $args{'data'});

    my @season;
    my $seasonal_DSP = $class->findSeasonalityDSP('data_values' => $data_values);
    my $season_ACF   = $class->findSeasonalityACF('data_values' => $data_values);

    if ( $seasonal_DSP != 1 ) {
        push @season, $seasonal_DSP;
        if ( ($#$season_ACF+1 != 0) && ((grep {$_ eq $seasonal_DSP} @{$season_ACF}) == 0) ) {
            push  @season, $season_ACF->[0];
        }
    }
    else {
        push @season, $season_ACF->[0] if ( $#$season_ACF+1 != 0 );
    }

    $log->debug("The seasonalities @season \n");

    return \@season;
}


=pod

=begin classdoc

Evaluates the accuracy of a data model using the following protocol : Takes a certain amount of the available 
data to train and fit the model (80% by default), then use it to forecast the remaining data and computes the
accuracy of the forecasted data according to the measures provided by the Utils::Accuracy utility class.

@param data_model_class The class name of the evaluated data model.
@param data A reference to a hash containing the available {timestamp => value}.
@param combination the combination to model.

@optional node_id modeled node in case of NodemetricCombination.
@optional freq The frequence (or seasonality) to use, if needed by the model.
@optional training_percentage The amount in percentage of data to use for training the model (80% by default).
@return A reference to an array containing all the accuracy measures computed.

=end classdoc

=cut

sub evaluateDataModelAccuracy {
    my ($class, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['data_model_class', 'data', 'combination'],
                         optional => {'node_id'             => undef,
                                      'freq'                => undef,
                                      'training_percentage' => 80,
                                      });

    # Adjust the training percentage if incorrect
    my $training_percentage = $args{training_percentage};
    if ( ($training_percentage <= 0) || ($training_percentage >= 100) ) {
        $training_percentage = DEFAULT_TRAINING_PERCENTAGE;
    }

    my %data = %{$args{data}};

    # Extract data hash into two sorted arrays
    my @timestamps = sort {$a <=> $b} keys(%data);
    my @values;
    for my $key (@timestamps) {
        push (@values, $args{data}->{$key});
    }

    # Segment the data
    my $last_training_index = int( ((keys(%data) - 1) * $training_percentage) / 100 );

    my %training_data;
    for my $i (0..$last_training_index) {
        $training_data{$timestamps[$i]} = $values[$i];
    }

    # Load and instanciate the data model
    my $data_model_class = $args{data_model_class};

    BaseDB::requireClass($data_model_class);

    my $model = $data_model_class->new(
        node_id        => $args{node_id},
        combination_id => $args{combination}->id,
    );

    # Configure 
    $model->configure(
        data => \%training_data,
        freq => $args{freq},
    );

    # Forecast the test part of the data
    my $forecasted_ref = $model->predict(
        data            => \%training_data,
        freq            => $args{freq},
        timestamps      => [@timestamps[ ($last_training_index + 1)..$#timestamps ]],
        end_time        => $timestamps[-1],
    );

    my @forecast = @{$forecasted_ref->{values}};

    # Delete the model
    $model->delete();

    return Utils::Accuracy->accuracy(
        theorical_data_ref => \@forecast,
        real_data_ref      => [@values[ ($last_training_index + 1)..$#timestamps ]],
    );
}

=pod

=begin classdoc

Choose the best DataModel given a set a accuracy measure for each one.

@param accuracy_measures A hash containing datamodel class and their accuracy measures 
                         { data_model_class => {measure_name ('mae', 'mse', ...) => measure} }.

@optional choice_strategy The strategy to adopt for choosing the best model (by default : DEMOCRACY) : 

                          'DEMOCRACY' -> For each model, count the times where it is the best one according to
                                         available accuracy measures and finally choose the one having the 
                                         most counts. If two models reach the same score, the one with the 
                                         lowest ME is choosen (arbitrary).

                          'RMSE'      -> Select the datamodel with the lowest RMSE.  

                          'MSE'       -> Select the datamodel with the lowest MSE.

                          'MAE'       -> Select the datamodel with the lowest MAE.

                          'ME'        -> Select the datamodel with the lowest ME.

@return The best DataModel classname choosen according to the selected strategy.

=end classdoc

=cut

sub chooseBestDataModel {
    my ($class, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['accuracy_measures'],
                         optional => {'choice_strategy' => CHOICE_STRATEGY->{DEMOCRACY}});

    my %accuracy_measures     = %{$args{accuracy_measures}};
    my $strategy = $args{choice_strategy};

    my $best_rmse = undef;
    my $best_mse  = undef;
    my $best_mae  = undef;
    my $best_me   = undef;

    my $best_rmse_model = undef;
    my $best_mse_model  = undef;
    my $best_mae_model  = undef;
    my $best_me_model   = undef;

    # Find the best model for each accuracy measure
    while (my ($data_model_class, $accuracy_ref) = each(%accuracy_measures)) {
        my $current_rmse = $accuracy_ref->{rmse};
        my $current_mse  = $accuracy_ref->{mse};
        my $current_mae  = $accuracy_ref->{mae};
        my $current_me   = $accuracy_ref->{me};

        if (!defined($best_rmse_model) || abs($current_rmse) < abs($best_rmse)) {
            $best_rmse_model = $data_model_class;
            $best_rmse       = $current_rmse;
        }
        if (!defined($best_mse_model)  || abs($current_mse)  < abs($best_mse)) {
            $best_mse_model = $data_model_class;
            $best_mse       = $current_mse;
        }
        if (!defined($best_mae_model)  || abs($current_mae)  < abs($best_mae)) {
            $best_mae_model = $data_model_class;
            $best_mae       = $current_mae;
        }
        if (!defined($best_me_model)   || abs($current_me)   < abs($best_me)) {
            $best_me_model  = $data_model_class;
            $best_me        = $current_me;
        }
    }

    # Return the best model according to the chosen strategy
    if ($strategy eq CHOICE_STRATEGY->{DEMOCRACY}) {
        my $president          = undef;
        my $votes              = -1;
        my $shortest_straw     = undef;

        for my $data_model_class (keys(%accuracy_measures)) {
            my $score = 0;
            my $straw = $accuracy_measures{$data_model_class}->{me};

            for my $best ($best_rmse_model, $best_mse_model, $best_mae_model, $best_me_model) {
                if ($best eq $data_model_class) {
                    $score ++;
                }
            }
            if (($score > $votes) || (($score == $votes) && ($straw < $shortest_straw))) {
                $president      = $data_model_class;
                $votes          = $score;
                $shortest_straw = $straw;
            }
        }
        return $president;
    }
    elsif ($strategy eq CHOICE_STRATEGY->{RMSE}) {
        return $best_mse_model;
    }
    elsif ($strategy eq CHOICE_STRATEGY->{MSE}) {
        return $best_mse_model;
    }
    elsif ($strategy eq CHOICE_STRATEGY->{MAE}) {
        return $best_mae_model;
    }
    elsif ($strategy eq CHOICE_STRATEGY->{ME}) {
        return $best_me_model;
    }
    else {
        throw Kanopya::Exception(error => "DataModelSelector : Unknown DataModel choice strategy: $strategy");
    }
}

1;
