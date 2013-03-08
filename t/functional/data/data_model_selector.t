=head1 SCOPE

DataModel

=head1 PRE-REQUISITE

=cut

use strict;
use warnings;
use Data::Dumper;
 
use Test::More 'no_plan';
use Test::Exception;

use BaseDB;
use Entity::ServiceProvider::Externalcluster;
use Node;
use Entity::Component::MockMonitor;
use Entity::Clustermetric;
use Entity::Combination::AggregateCombination;
use Entity::Combination::NodemetricCombination;

use Entity::DataModel;
use Entity::DataModel::LinearRegression;
use Entity::DataModel::LogarithmicRegression;

use List::MoreUtils;
use List::Util;

use Aggregator;
use Executor;

use DataModelSelector;

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

    BaseDB->authenticate( login =>'admin', password => 'K4n0pY4' );

    if ($testing == 1) {
        BaseDB->beginTransaction;
    }

    setup();

    testDataModelAccuracyEvaluation();

    if ($testing == 1) {
        BaseDB->rollbackTransaction;
    }
}

sub testDataModelAccuracyEvaluation {

    my %data = (
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

my %accuracy_linear_regression;
my %accuracy_logarithmic_regression;
my %accuracy_auto_arima;

    lives_ok {
        %accuracy_linear_regression = %{DataModelSelector->evaluateDataModelAccuracy(
            data_model_class => 'Entity::DataModel::LinearRegression',
            data             => \%data,
            combination      => $comb,
        )};
    } 'DataModelSelector : Testing accuracy evaluation for Linear Regression DataModel';

    lives_ok {
        %accuracy_logarithmic_regression = %{DataModelSelector->evaluateDataModelAccuracy(
            data_model_class => 'Entity::DataModel::LogarithmicRegression',
            data             => \%data,
            combination      => $comb,
        )};
    } 'DataModelSelector : Testing accuracy evaluation for Logarithmic Regression DataModel';

    lives_ok {
        %accuracy_auto_arima = %{DataModelSelector->evaluateDataModelAccuracy(
            data_model_class => 'Entity::DataModel::AutoArima',
            data             => \%data,
            combination      => $comb,
            freq             => 6,
        )};
    } 'DataModelSelector : Testing accuracy evaluation for AutoArima DataModel';
    for my $strategy ('RMSE', 'MSE', 'MAE', 'ME', 'DEMOCRACY') {
        my $best_model;
        lives_ok {
            $best_model = DataModelSelector->chooseBestDataModel(
                accuracy_measures => {
                    'Entity::DataModel::LinearRegression'      => {%accuracy_linear_regression},
                    'Entity::DataModel::LogarithmicRegression' => {%accuracy_logarithmic_regression},
                    'Entity::DataModel::AutoArima'             => {%accuracy_auto_arima},
                },
                choice_strategy   => $strategy,
            );
        } "DataModelSelector : Testing best model choice with $strategy strategy";
        diag("\t\t\t\t\t\t\t\t(Best chosen : $best_model)");
    }

    throws_ok {
        my $best_model = DataModelSelector->chooseBestDataModel(
            accuracy_measures => {
                'Entity::DataModel::LinearRegression'      => {%accuracy_linear_regression},
                'Entity::DataModel::LogarithmicRegression' => {%accuracy_logarithmic_regression},
                'Entity::DataModel::AutoArima'             => {%accuracy_auto_arima},
            },
            choice_strategy   => 'Are you kidding me ?!',
        );
    } 'Kanopya::Exception', 'DataModelSelector : Testing best model choice with incorrect strategy argument';
}

sub setup {

    srand(1);
    $service_provider = Entity::ServiceProvider::Externalcluster->new(
                            externalcluster_name => 'Test Service Provider',
                        );

    $external_cluster_mockmonitor = Entity::ServiceProvider::Externalcluster->new(
                                        externalcluster_name => 'Test Monitor',
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