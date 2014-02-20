
=head1 SCOPE

DataModelSelector

=head1 PRE-REQUISITE

=cut

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;

use Log::Log4perl qw(:easy);
Log::Log4perl -> easy_init({
    level => 'DEBUG',
    file => __FILE__.'.log',
    layout => '%F %L %p %m%n'
});

use Kanopya::Database;
use Entity::ServiceProvider::Externalcluster;
use Entity::Component::MockMonitor;
use DataModelSelector;
use Utils::TimeSerieAnalysis;

my $testing = 1;
my $service_provider;
my $external_cluster_mockmonitor;
my $node_1;
my $indic_1;
my $node_data_model;
my $service_data_model;
my $service_data_log_model;
my $comb;
my $cm;

main();

sub main {

    Kanopya::Database::authenticate( login =>'admin', password => 'K4n0pY4' );

    if ($testing == 1) {
        Kanopya::Database::beginTransaction;
    }

    setup();
    testBestModel();
    testDataModelSelector();
    testAutoPredict();

    if ($testing == 1) {
        Kanopya::Database::rollbackTransaction;
    }
}

sub testBestModel {
    lives_ok {

        my %lin_serie = map {$_ => $_} (0..100);

        my $pred = DataModelSelector->autoPredictData(
                       predict_start_tstamps => 101,
                       predict_end_tstamps   => 200,
                       timeserie             => \%lin_serie,
                       model_list            => ['AnalyticRegression::LinearRegression',
                                                 'AnalyticRegression::LogarithmicRegression',],
                   );

        if ($pred->{data_model} ne 'Entity::DataModel::AnalyticRegression::LinearRegression') {
            die 'Wrong Linear Model';
        }

        my %log_serie = map {$_ => log($_)} (3..23);

        $pred = DataModelSelector->autoPredictData(
                    predict_start_tstamps => 101,
                    predict_end_tstamps   => 200,
                    timeserie             => \%log_serie,
                    model_list            => ['AnalyticRegression::LinearRegression',
                                              'AnalyticRegression::LogarithmicRegression',],
                );

        if ($pred->{data_model} ne 'Entity::DataModel::AnalyticRegression::LogarithmicRegression') {
            die 'Wrong Logarithmic Model';
        }


    } 'Right Model selection';

}


sub testAutoPredict {

    my $min_length = DataModelSelector->TIME_SERIES_MIN_LENGTH;

    throws_ok {
        my %timeserie = (
            4  => 15 , 5  => 13 , 6  => 12 , 7  => 5  , 8  => 12 ,
        );

        my %extracted  = %{Utils::TimeSerieAnalysis->splitData(data => \%timeserie)};
        my @timestamps = @{$extracted{timestamps_ref}};
        my @values     = @{$extracted{values_ref}};

        my %forecast = %{DataModelSelector->autoPredict(
            predict_start_tstamps => 45,
            predict_end_tstamps  => 61,
            timeserie             => \%timeserie,
        )};
    } 'Kanopya::Exception',
      "DataModelSelector with a too small time serie (min lenght is $min_length)";

    lives_ok {
        my %timeserie = (
            1  => undef , 2  => undef , 3  => undef , 4  => 15 , 5  => 13 ,
            6  => 12 , 7  => 5  , 8  => 12 , 9  => 13 , 10 => 15 ,
            11 => 13 , 12 => 12 , 13 => 5  , 14 => 12 , 15 => 13 ,
            16 => 15 , 17 => 13 , 18 => 12 , 19 => 5  , 20 => 12 ,
            21 => 13 , 22 => 15 , 23 => 13 , 24 => 12 , 25 => 5  ,
            26 => 12 , 27 => 13 , 28 => 15 , 29 => 13 , 30 => 12 ,
            31 => 5  , 32 => 12 , 33 => 13 , 34 => 15 , 35 => 13 ,
            36 => 12 , 37 => 5  , 38 => 12 , 39 => 13 , 40 => 15 ,
            41 => 13 , 42 => 12 , 43 => 5  , 44 => 12 , 45 => 13 ,
            46 => 15 , 47 => 13 , 48 => 12 , 49 => 5  , 50 => undef ,
        );

        my %extracted  = %{Utils::TimeSerieAnalysis->splitData(data => \%timeserie)};
        my @timestamps = @{$extracted{timestamps_ref}};
        my @values     = @{$extracted{values_ref}};

        my $forecast = DataModelSelector->autoPredict(
                           predict_start_tstamps => 45,
                           predict_end_tstamps   => 61,
                           timeserie             => \%timeserie,
                       );

         if ($forecast->{data_model} ne 'Entity::DataModel::RDataModel::ExpR') {
            die 'Wrong data model got <' . $forecast->{data_model}
                . '> expect <Entity::DataModel::RDataModel::ExpR>';
         }

    } 'DataModelSelector : Testing autoPredict Method';
}

sub testDataModelSelector {

    my %timeserie = (
        1  => 5  , 2  => 12 , 3  => 13 , 4  => 15 , 5  => 13 ,
        6  => 12 , 7  => 5  , 8  => 12 , 9  => 13 , 10 => 15 ,
        11 => 13 , 12 => 12 , 13 => 5  , 14 => 12 , 15 => 13 ,
        16 => 15 , 17 => 13 , 18 => 12 , 19 => 5  , 20 => 12 ,
        21 => 13 , 22 => 15 , 23 => 13 , 24 => 12 , 25 => 5  ,
        26 => 12 , 27 => 13 , 28 => 15 , 29 => 13 , 30 => 12 ,
        31 => 5  , 32 => 12 , 33 => 13 , 34 => 15 , 35 => 13 ,
        36 => 12 , 37 => 5  , 38 => 12 , 39 => 13 , 40 => 15 ,
        41 => 13 , 42 => 12 , 43 => 5  , 44 => 12 , 45 => 13 ,
        46 => 15 , 47 => 13 , 48 => 12 , 49 => 5  , 50 => 12 ,
    );

    my %extracted  = %{Utils::TimeSerieAnalysis->splitData(data => \%timeserie)};
    my @timestamps = @{$extracted{timestamps_ref}};
    my @values     = @{$extracted{values_ref}};

    my %accuracy_lin_reg;
    my %accuracy_log_reg;
    my %accuracy_auto_arima;
    my %accuracy_exp_smoothing;
    my %accuracy_stlf;
    my %accuracy_exp_r;


    lives_ok {
        %accuracy_lin_reg = %{DataModelSelector->evaluateDataModelAccuracy(
            data_model_class => 'Entity::DataModel::AnalyticRegression::LinearRegression',
            data             => \@values,
            combination_id   => $comb->id,
        )};
    } 'DataModelSelector : Testing accuracy evaluation for Linear Regression DataModel';

    lives_ok {
        %accuracy_log_reg = %{DataModelSelector->evaluateDataModelAccuracy(
            data_model_class => 'Entity::DataModel::AnalyticRegression::LogarithmicRegression',
            data             => \@values,
            combination_id   => $comb->id,
        )};
    } 'DataModelSelector : Testing accuracy evaluation for Logarithmic Regression DataModel';

    lives_ok {
        %accuracy_auto_arima = %{DataModelSelector->evaluateDataModelAccuracy(
            data_model_class => 'Entity::DataModel::RDataModel::AutoArima',
            data             => \@values,
            combination_id   => $comb->id,
            freq             => 6,
        )};
    } 'DataModelSelector : Testing accuracy evaluation for AutoArima DataModel';

    lives_ok {
        %accuracy_exp_smoothing = %{DataModelSelector->evaluateDataModelAccuracy(
            data_model_class => 'Entity::DataModel::RDataModel::ExponentialSmoothing',
            data             => \@values,
            combination_id   => $comb->id,
            freq             => 6,
        )};
    } 'DataModelSelector : Testing accuracy evaluation for ExponentialSmoothing DataModel';

    lives_ok {
        %accuracy_stlf = %{DataModelSelector->evaluateDataModelAccuracy(
            data_model_class => 'Entity::DataModel::RDataModel::StlForecast',
            data             => \@values,
            combination_id   => $comb->id,
            freq             => 6,
        )};
    } 'DataModelSelector : Testing accuracy evaluation for StlForecast DataModel';

    lives_ok {
        %accuracy_exp_r = %{DataModelSelector->evaluateDataModelAccuracy(
            data_model_class => 'Entity::DataModel::RDataModel::ExpR',
            data             => \@values,
            combination_id   => $comb->id,
            freq             => 6,
        )};
    } 'DataModelSelector : Testing accuracy evaluation for ExpR DataModel';

    for my $strategy ('RMSE', 'MSE', 'MAE', 'ME', 'DEMOCRACY') {
        my $best_model;
        lives_ok {
            $best_model = DataModelSelector->chooseBestDataModel(
                accuracy_measures => {
                    'Entity::DataModel::AnalyticRegression::LinearRegression' => {%accuracy_lin_reg},
                    'Entity::DataModel::LogarithmicRegression'                => {%accuracy_log_reg},
                    'Entity::DataModel::RDataModel::AutoArima'                => {%accuracy_auto_arima},
                    'Entity::DataModel::RDataModel::ExponentialSmoothing'     => {%accuracy_exp_smoothing},
                    'Entity::DataModel::RDataModel::StlForecast'              => {%accuracy_stlf},
                    'Entity::DataModel::RDataModel::ExpR'                     => {%accuracy_exp_r},
                },
                choice_strategy   => $strategy,
            );
        } "DataModelSelector : Testing best model choice with $strategy strategy";
    }

    throws_ok {
        my $best_model = DataModelSelector->chooseBestDataModel(
            accuracy_measures => {
                    'Entity::DataModel::AnalyticRegression::LinearRegression' => {%accuracy_lin_reg},
                    'Entity::DataModel::LogarithmicRegression'                => {%accuracy_log_reg},
                    'Entity::DataModel::RDataModel::AutoArima'                => {%accuracy_auto_arima},
                    'Entity::DataModel::RDataModel::ExponentialSmoothing'     => {%accuracy_exp_smoothing},
                    'Entity::DataModel::RDataModel::StlForecast'              => {%accuracy_stlf},
                    'Entity::DataModel::RDataModel::ExpR'                     => {%accuracy_exp_r},
            },
            choice_strategy   => 'Are you kidding me ?!',
        );
    } 'Kanopya::Exception', 'DataModelSelector : Testing best model choice with incorrect strategy argument';

    lives_ok {
        my $best_model = DataModelSelector->selectDataModel(
            data           => \@values,
            combination_id => $comb->id,
            start_time     => 10,
            end_time       => 10,
        );
    } "DataModelSelector : Testing selectDataModel method";
}

sub setup {

    srand(1);
    $service_provider = Entity::ServiceProvider::Externalcluster->new(
                            externalcluster_name => 'Test Service Provider 9',
                        );

    $external_cluster_mockmonitor = Entity::ServiceProvider::Externalcluster->new(
                                        externalcluster_name => 'Test Monitor 9',
                                    );

    my $mock_monitor = Entity::Component::MockMonitor->new(
                           service_provider_id => $external_cluster_mockmonitor->id,
                       );

    $service_provider->addManager(
        manager_id      => $mock_monitor->id,
        manager_type    => 'CollectorManager',
        no_default_conf => 1,
    );

    # Create node 1
    $node_1 = Node->new(
                  node_hostname         => 'node_1',
                  service_provider_id   => $service_provider->id,
                  monitoring_state      => 'up',
              );

    # Get indicators
    $indic_1 = Entity::CollectorIndicator->find (
                   hash => {
                       collector_manager_id        => $mock_monitor->id,
                       'indicator.indicator_oid'   => 'Memory/PercentMemoryUsed'
                   }
               );

   # Clustermetric
    $cm = Entity::Clustermetric->new(
                 clustermetric_service_provider_id      => $service_provider->id,
                 clustermetric_indicator_id             => ($indic_1->id),
                 clustermetric_statistics_function_name => 'sum',
                 clustermetric_window_time              => '1200',
             );

    # Combination
    $comb = Entity::Combination::AggregateCombination->new(
                service_provider_id           =>  $service_provider->id,
                aggregate_combination_formula => 'id'.($cm->id),
            );

    #  Nodemetric combination
    my $ncomb = Entity::Combination::NodemetricCombination->new(
                    service_provider_id            => $service_provider->id,
                    nodemetric_combination_formula => 'id'.($indic_1->id),
                );

}
