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
DataModel for a given dataset.

@since    2013-Feb-13

=end classdoc

=cut

package DataModelSelector;

use base 'BaseDB';

use warnings;
use strict;
use Data::Dumper;
use BaseDB;
use Entity::DataModel;
use Utils::TimeSerieAnalysis;

use Log::Log4perl "get_logger";
my $log = get_logger("");

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

sub methods {
    return {
        autoPredict => {
            description => 'Find best model and predict metric values.',
            perm_holder => 'entity',
        }
    };
}

=pod

=begin classdoc

Proceed a forecast with an automatic selection of the model and his parameters.

@param combination_id The id of the combination to model.
@param start_time Define the start time of historical data taken to configure.
@param end_time Define the end time of historical data taken to configure.

@optional horizon The horizon of the forecast (when this forecast mode is selected).
@optional timestamps The timestamps to forecast (when this forecast mode is selected).
@optional node_id Modeled node in case of NodemetricCombination.
@optional model_list  : The list of the available models for the selection. By default all existing models are
                        used. 
@optional data A reference to a hash containing the available {timestamp => value}.
@optional data_format The format wished for the forecast (default : Hash containing a reference to an array
                      of timestamps ('timestamps'), and a reference to an array of values ('values').
                      'pairs' : An array where each value is a reference to an array containing a timestamp
                      and the corresponding value).

@return A reference to the forecast, with the selected format (default : Hash containing a reference to an 
        array of timestamps ('timestamps'), and a reference to an array of values ('values').
        'pairs' : An array where each value is a reference to an array containing a timestamp and the 
        corresponding value).

=end classdoc

=cut

sub autoPredict {
    my ($class, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['combination_id', 'start_time', 'end_time'],
                         optional => {'horizon'       => undef,
                                      'timestamps'    => undef,
                                      'node_id'       => undef, 
                                      'model_list'    => MODEL_CLASSES,
                                      'data'          => undef,
                                      'data_format'   => undef,
                         });

    if (!defined($args{horizon}) && !defined($args{timestamps})) {
        throw Kanopya::Exception(error => 'SelectDataModel : An horizon or an array of timestamps must be'
                                          . 'defined.');
    }

    $log->debug('autoPredict - Loading the data from the combination.');

    # Get the combination from the given id
    my $combination = Entity::Combination->get(id => $args{combination_id});

    # Extract the data
    my %raw_data = defined($args{data}) ? %{$args{data}}
             :                              $combination->evaluateTimeSerie(start_time => $args{start_time},
                                                                            stop_time  => $args{end_time},
                                                                            node_id    => $args{node_id})
             ;

    $log->debug('autoPredict - Fixing the data.');

    # Fix the data
    my %data = %{Utils::TimeSerieAnalysis->fixTimeSerie(data => \%raw_data)};

    $log->debug("autoPredict - unfixed data size = " . scalar(keys(%raw_data)) . '.');
    $log->debug("autoPredict - fixed data size = " . scalar(keys(%data)) . '.');

    # If horizon or timestamps undefined, construct the undefined one
    if (!defined($args{horizon})) {
        my @timestamps = @{$args{timestamps}};
        $args{horizon} = $timestamps[-1];
    }
    if (!defined($args{timestamps})) {
        my @timestamps = sort {$a <=> $b} keys(%data);
        my $granularity      = int($timestamps[-1] -$timestamps[0]) / (@timestamps - 1);
        my $relative_end     = ($args{horizon} - $timestamps[0]);
        my $relative_horizon = ($relative_end % $granularity) == 0 ? $relative_end / $granularity
                             :                                       int($relative_end / $granularity) + 1
                             ;
        my @n_timestamps;
        for my $i (1..$relative_horizon) {
            push @n_timestamps, $timestamps[-1] + ($i * $granularity);
        }
        $args{timestamps} = \@n_timestamps;
    }

    $log->debug("autoPredict - Selecting best model among @{$args{model_list}} .");

    # Select DataModel
    my %best = %{$class->selectDataModel(
        combination => $combination,
        start_time  => $args{start_time},
        end_time    => $args{end_time},
        node_id     => $args{node_id},
        model_list  => $args{model_list},
        data        => \%data,
    )};

    my $best_model = $best{best_model};
    my $best_freq  = $best{best_freq};

    $log->debug("autoPredict - best found model : $best_model with freq : $best_freq . Will now proceed " .
                              'the forecast.');

    $log->info("Automatic Prediction : $best_model chosen, with freq : $best_freq.");

    # Instanciate and configure the best found model
    my $datamodel = $best_model->new(
        node_id        => $args{node_id},
        combination_id => $args{combination_id},
    );
    $datamodel->configure(
        data => \%data,
        freq => $best_freq,
    );

    # Return the forecast
    my $prediction = $datamodel->predict(
        data            => \%data,
        freq            => $best_freq,
        timestamps      => $args{timestamps},
        end_time        => $args{horizon},
    );

    $log->debug("autoPredict - forecasted values : @{${$prediction}{values}}");

    return $prediction;
}

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
@optional data A reference to a hash containing the available {timestamp => value}.

@return the selected model

=end classdoc

=cut

sub selectDataModel {
    my ($class, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['combination', 'start_time', 'end_time'],
                         optional => {'node_id'       => undef, 
                                      'model_list'    => MODEL_CLASSES,
                                      'data'          => undef,
                         });

    # Extract the data
    my %data = defined($args{data}) ? %{$args{data}}
             :                        $args{combination}->computeValues(start_time => $args{start_time},
                                                                        stop_time  => $args{end_time},
                                                                        node_id    => $args{node_id})
             ;

    my @data_model_classes = @{$args{model_list}};
    for my $i (0..$#data_model_classes) {
        $data_model_classes[$i] = BASE_NAME . $data_model_classes[$i];
    }

    # Compute the possible seasonality values
    my @freqs = @{Utils::TimeSerieAnalysis->findSeasonality(data => \%data)} || (1);
    $log->debug("selectDataModel - possible frequencies computed : @freqs .");

    # Models with the best freq found {class_name => $freq}
    my %freq_hash;

    # Models with their computed accuracy {class_name => {accuracy}}
    my %accuracy_hash;

    for my $data_model_class (@data_model_classes) {
        BaseDB::requireClass($data_model_class);

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
}

=pod

=begin classdoc

Evaluates the accuracy of a data model using the following protocol : Takes a certain amount of the available 
data to train and fit the model (80% by default), then use it to forecast the remaining data and computes the
accuracy of the forecasted data according to the measures provided by the Utils::TimeSerieAnalysis class.

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

    return Utils::TimeSerieAnalysis->accuracy(
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
