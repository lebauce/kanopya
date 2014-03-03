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

Static class which implements DataModel related methods : Main one automaticly select the most suitable
DataModel for a given dataset (autoPredict).

@since    2013-Feb-13

=end classdoc

=cut

package DataModelSelector;
use base BaseDB;

use warnings;
use strict;

use General;
use Entity::DataModel;
use Utils::TimeSerieAnalysis;

use Log::Log4perl "get_logger";
my $log = get_logger("");

use constant {
    DEFAULT_TRAINING_PERCENTAGE => 80,
    TIME_SERIES_MIN_LENGTH      => 20,
    BASE_NAME                   => 'Entity::DataModel::',
    MODEL_CLASSES               => [
       'AnalyticRegression::LinearRegression',
       'AnalyticRegression::LogarithmicRegression',
#       'RDataModel::AutoArima',
#       'RDataModel::ExponentialSmoothing',
#       'RDataModel::StlForecast',
       'RDataModel::ExpR',
    ],
    CHOICE_STRATEGY             => {
        DEMOCRACY => 'DEMOCRACY',
        ME        => 'ME',
        MAE       => 'MAE',
        MSE       => 'MSE',
        RMSE      => 'RMSE',
    },
};

=pod

=begin classdoc

@param predict_start_tstamps The starting point wished for the prediction (in timestamps !).
@param predict_end_tstamps The ending point wished for the prediction (in timestamps).

@optional timeserie A reference to a hash containing the timestamps and the values of the time serie
                    (timestamp => value).

@optional data_start The start time if the data is directly loaded from a combination.
@optional data_end The end time if the data it directly loaded from a combination.
@optional model_list  : The list of the available models for the selection. By default all existing models are
                        used.

@return A reference to the forecast : Hash containing a reference to an
        array of timestamps ('timestamps'), and a reference to an array of values ('values')
        and the used data model 'data_model'.

=end classdoc

=cut

sub autoPredict {
    my ($class, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['predict_start_tstamps', 'predict_end_tstamps'],
                         optional => {'timeserie'      => undef,
                                      'combination_id' => undef,
                                      'node_id'        => undef,
                                      'data_start'     => undef,
                                      'data_end'       => undef,
                                      'model_list'     => MODEL_CLASSES,
                         });

    if (!defined($args{timeserie}) && !defined($args{combination_id})) {
        throw Kanopya::Exception(error => 'SelectDataModel : A timeserie or a combination must be defined.');
    }

    $log->debug('autoPredict - Loading the data from the combination.');

    # Extract the data
    my $rawdata;

    if (defined($args{timeserie})) {
        $rawdata = $args{timeserie};
    }
    elsif (defined($args{combination_id}) && defined $args{data_start} && defined($args{data_end})) {
        my $combination = Entity::Combination->get(id => $args{combination_id});
        $rawdata = $combination->evaluateTimeSerie(start_time => $args{data_start},
                                                   stop_time  => $args{data_end},
                                                   node_id    => $args{node_id},);
    }
    else {
        throw Kanopya::Exception(error => 'SelecDataModel : Cannot call autoPredict method without data ' .
                                          'or without a combination_id with a data_start and a data_end}.');
    }

    return $class->autoPredictData(predict_start_tstamps => $args{predict_start_tstamps},
                                   predict_end_tstamps   => $args{predict_end_tstamps},
                                   model_list            => $args{model_list},
                                   timeserie             => $rawdata);
}


=pod
=begin classdoc

Predict datas by selecting the best data model from a model list

@param predict_start_tstamps The starting point wished for the prediction (in timestamps !).
@param predict_end_tstamps The ending point wished for the prediction (in timestamps).

@optional timeserie A reference to a hash containing the timestamps and the values of the time serie
                    (timestamp => value).

@optional model_list The list of the available models for the selection.
                     By default all existing models are used.

@return A reference to the forecast : Hash containing a reference to an
        array of timestamps ('timestamps'), and a reference to an array of values ('values')
        and the used data model 'data_model'.

=end classdoc
=cut

sub autoPredictData {
    my ($class, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['predict_start_tstamps', 'predict_end_tstamps', 'timeserie'],
                         optional => {'model_list' => MODEL_CLASSES });

   $log->debug('autoPredict - Fixing the data.');

    # Fix the data
    my $timeserie = Utils::TimeSerieAnalysis->fixTimeSerie(timeserie => $args{timeserie});

    # Extract the data
    my $extracted  = Utils::TimeSerieAnalysis->splitData(data => $timeserie);

    # ARBITRARY RESTRICTION : We throw an exception when the time series length is under a fixed limit, in
    #                         order to avoid R crashes (especially in auto.arima, which does not seem to
    #                          enjoy small time series).
    my $length = @{$extracted->{values_ref}};
    if ($length < TIME_SERIES_MIN_LENGTH) {
        my $min_length = TIME_SERIES_MIN_LENGTH;
        throw Kanopya::Exception::Internal::WrongValue(
                  error => 'SelectDataModel : I will not proceed an automatic forecast for ' .
                           "a time serie with a length < $min_length (actual length is " .
                           "$length), it is unsafe and unreliable ! "
              );
    }

    if (scalar(@{$extracted->{values_ref}}) <= 0 || scalar(@{$extracted->{timestamps_ref}}) <= 0) {
        throw Kanopya::Exception::Internal::WrongValue(
                  error => 'SelectDataModel : Empty dataset.'
              );
    }

    $log->debug("autoPredict - Selecting best model among @{$args{model_list}} .");

    # Select DataModel
    my $best = $class->selectDataModel(
                    data           => $extracted->{values_ref},
                    model_list     => $args{model_list},
                );

    $log->info('Automatic Prediction : ' . $best->{best_model}
               . ' chosen, with freq : ' . $best->{best_freq});

    # Compute the granularity and predict points
    my $granularity = Utils::TimeSerieAnalysis->computePredictPointsAndGranularity(
                          timestamps            => $extracted->{timestamps_ref},
                          predict_start_tstamps => $args{predict_start_tstamps},
                          predict_end_tstamps   => $args{predict_end_tstamps},
                      );

    # Instanciate and configure the best found model
    my $datamodel = $best->{best_model}->new();

    # Configure
    $datamodel->configure(
        data           => $extracted->{values_ref},
        freq           => $best->{best_freq},
        predict_start  => $granularity->{predict_start},
        predict_end    => $granularity->{predict_end},
    );

    # Forecast the test part of the data
    my $prediction = $datamodel->predict(data          => $extracted->{values_ref},
                                         freq          => $best->{best_freq},
                                         predict_start => $granularity->{predict_start},
                                         predict_end   => $granularity->{predict_end},);

    # Construct new timestamps
    my @n_timestamps = ();
    for my $i ($granularity->{predict_start}..$granularity->{predict_end}) {
        if (($granularity->{predict_end} - $i) <= $#{$prediction}) {
            push @n_timestamps, $i * $granularity->{granularity} + $extracted->{timestamps_ref}->[0];
        }
    }

    $datamodel->delete();

    return {
        'timestamps' => \@n_timestamps,
        'values'     => $prediction,
        'data_model' => $best->{best_model},
    };
}

=pod

=begin classdoc

Select the best DataModel and the best freq (is needed) among a given list, using the evaluateDataModel and
the chooseBestDataModel methods.

@param data A reference to an array containing the values of the time serie.

@optional model_list  : The list of the available models for the selection. By default all existing models are
                        used.
@optional combination_id the combination's id to model
@optional node_id modeled node in case of NodemetricCombination

@return the selected model and the selected frequency as a reference to a hash (keys : 'best_model' and
        'best_freq').

=end classdoc

=cut

sub selectDataModel {
    my ($class, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['data'],
                         optional => {'model_list' => MODEL_CLASSES});

    # Manage model classes. If full class name is not provided (shortcut) we add the base name
    my $base_name = BASE_NAME;
    my @data_model_classes = @{$args{model_list}};
    for my $i (0..$#data_model_classes) {
        if ($data_model_classes[$i] !~ m/^$base_name/) {
            $data_model_classes[$i] = BASE_NAME . $data_model_classes[$i];
        }
    }

    # Compute the possible seasonality values
    my @freqs = @{Utils::TimeSerieAnalysis->findSeasonality(data => $args{data})};
    if (scalar(@freqs) == 0) {
        @freqs = (1);
    }
    $log->debug("selectDataModel - possible frequencies computed : @freqs .");

    # Models with the best freq found {class_name => $freq}
    my %freq_hash;

    # Models with their computed accuracy {class_name => {accuracy}}
    my %accuracy_hash;

    my $error;

    for my $data_model_class (@data_model_classes) {
        General::requireClass($data_model_class);

        # If the model is a seasonal one, try each possible seasonality value and only retain the best one
        if ($data_model_class->isSeasonal()) {

            my %temp_accuracy_hash;

            # Compute the accuracy of the model for each freq
            for my $freq (@freqs) {
                eval {
                    my $accur = $class->evaluateDataModelAccuracy(
                        data_model_class => $data_model_class,
                        data             => $args{data},
                        freq             => $freq,
                    );
                    if (defined($accur)) {
                        $temp_accuracy_hash{$freq} = $accur;
                    }
                };
                if ($@) {
                    $error = $@;
                    $log->info("$error");
                }
            }

            # Store the best model retained if there is at least one available
            if (scalar(keys(%temp_accuracy_hash)) != 0) {
                my $best_freq = $class->chooseBestDataModel(accuracy_measures => {%temp_accuracy_hash});
                $freq_hash{$data_model_class}     = $best_freq;
                $accuracy_hash{$data_model_class} = $temp_accuracy_hash{$best_freq};
            }
        }
        else {
            eval {
                my $t_freq = 1;
                my $accur  = $class->evaluateDataModelAccuracy(
                    data_model_class => $data_model_class,
                    data             => $args{data},
                );
                if (defined($accur)) {
                    $freq_hash{$data_model_class}     = $t_freq;
                    $accuracy_hash{$data_model_class} = $accur;
                }
            };
            if ($@) {
                $error = $@;
                $log->info("$error");
            }
        }
    }

    # If there was only exceptions, throw an exception !
    if (scalar(keys(%accuracy_hash)) == 0) {
        throw Kanopya::Exception::Internal(
                  error => 'All selected models were unable to proceed the forecast with ' .
                           'the selected data.please try to select more data or more ' .
                           'models. See logs for details.'
              );
    }

    # Choose the best DataModel among all
    my $best_data_model = $class->chooseBestDataModel(accuracy_measures => {%accuracy_hash});
    my $best_freq       = $freq_hash{$best_data_model};

    return {
        best_model => $best_data_model,
        best_freq  => $best_freq,
    }
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
        throw Kanopya::Exception::Internal(
                  error => "DataModelSelector : Unknown DataModel choice strategy: $strategy"
              );
    }
}

=pod

=begin classdoc

Evaluates the accuracy of a data model using the following protocol : Takes a certain amount of the available
data to train and fit the model (80% by default), then use it to forecast the remaining data and computes the
accuracy of the forecasted data according to the measures provided by the Utils::TimeSerieAnalysis class.

@param data_model_class The class name of the evaluated data model.
@param data A reference to an array containing the data.

@optional freq The frequence (or seasonality) to use, if needed by the model.
@optional training_percentage The amount in percentage of data to use for training the model (80% by default).

@return A reference to an array containing the values of the time serie.

=end classdoc

=cut

sub evaluateDataModelAccuracy {
    my ($class, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['data_model_class', 'data'],
                         optional => {'freq'                => undef,
                                      'training_percentage' => 80,
                                      });

    # Adjust the training percentage if incorrect
    my $training_percentage = $args{training_percentage};
    if ( ($training_percentage <= 0) || ($training_percentage >= 100) ) {
        $training_percentage = DEFAULT_TRAINING_PERCENTAGE;
    }

    my @data = @{$args{data}};

    # Segment the data
    my $last_training_index = int( ($#data * $training_percentage) / 100 );

    my @training_data;
    for my $i (0..$last_training_index) {
        $training_data[$i] = $data[$i];
    }

    # Load and instanciate the data model
    my $data_model_class = $args{data_model_class};

    General::requireClass($data_model_class);

    my $model = $data_model_class;

    $model = $data_model_class->new();

    # Configure
    $model->configure(
        data           => \@training_data,
        freq           => $args{freq},
        predict_start  => $last_training_index + 1,
        predict_end    => $#data,
    );

    # Forecast the test part of the data
    my $forecasted_ref = $model->predict(
        data           => \@training_data,
        freq           => $args{freq},
        predict_start  => $last_training_index + 1,
        predict_end    => $#data,
    );

    my @forecast = @{$forecasted_ref};
    # Delete the model
    $model->delete();

    return Utils::TimeSerieAnalysis->accuracy(
        theorical_data_ref => \@forecast,
        real_data_ref      => [@data[ ($last_training_index + 1)..$#data ]],
    );
}

1;
