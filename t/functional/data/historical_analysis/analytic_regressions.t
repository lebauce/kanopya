=head1 SCOPE

LinearRegression

=head1 PRE-REQUISITE

=cut

use strict;
use warnings;
 
use Test::More 'no_plan';
use Test::Exception;

use BaseDB;
use Entity::ServiceProvider::Externalcluster;
use Entity::Component::MockMonitor;

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
use Entity::DataModel::AnalyticRegression::LinearRegression;
use Entity::DataModel::AnalyticRegression::LogarithmicRegression;

main();

sub main {
    BaseDB->authenticate( login =>'admin', password => 'K4n0pY4' );

    if ($testing == 1) {
        BaseDB->beginTransaction;
    }

    setup();
    testLinearRegression();
    testLogarithmicRegression();

    if ($testing == 1) {
        BaseDB->rollbackTransaction;
    }
}

sub testLinearRegression {
    # The data (y = 2 * x + 5) with x in [1..20].
    my @data = (7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31, 33, 35, 37, 39, 41, 43, 45);

    # Initialize the LinearRegression
    my $model = Entity::DataModel::AnalyticRegression::LinearRegression->new(
        combination_id => $comb->id,
    );

    lives_ok {
        $model->configure(
            data           => \@data,
            predict_start  => 10,
            predict_end    => 25,
        );
    } 'LinearRegression : Testing configure';

    lives_ok {
        my $forecast_ref = $model->predict(
            data          => \@data,
            predict_start => 9,
            predict_end   => 24,
        );
        my @forecast = @{$forecast_ref};
        my @expected = (25, 27, 29, 31, 33, 35, 37, 39, 41, 43, 45, 47, 49, 51, 53, 55);
        my $eps      = 0.001;
        for my $i (0..$#forecast) {
            if (abs($forecast[$i] - $expected[$i]) > $eps) {
                die ("LinearRegression prediction test : Incorrect value forecasted ($forecast[$i] instead " .
                     "of $expected[$i])");
            }
        } 
    } 'LinearRegression : Testing predict';
}

sub testLogarithmicRegression {
    # The data (y = 5 * log(x) + 8) with x in [1..20].
    my @data = (8.00000, 11.46574, 13.49306, 14.93147, 16.04719, 16.95880, 17.72955, 18.39721, 18.98612,
                19.51293, 19.98948, 20.42453, 20.82475, 21.19529, 21.54025, 21.86294, 22.16607, 22.45186,
                22.72219, 22.97866);

    # Initialize the LinearRegression
    my $model = Entity::DataModel::AnalyticRegression::LogarithmicRegression->new(
        combination_id => $comb->id,
    );

    lives_ok {
        $model->configure(
            data           => \@data,
            predict_start  => 10,
            predict_end    => 25,
        );
    } 'LogarithmicRegression : Testing configure';

    lives_ok {
        my $forecast_ref = $model->predict(
            data          => \@data,
            predict_start => 9,
            predict_end   => 24,
        );
        my @forecast = @{$forecast_ref};
        my @expected = (19.51293, 19.98948, 20.42453, 20.82475, 21.19529, 21.54025, 21.86294, 22.16607, 
                        22.45186, 22.72219, 22.97866, 23.22261, 23.45521, 23.67747, 23.89027, 24.09438);
        my $eps      = 0.001;
        for my $i (0..$#forecast) {
            if (abs($forecast[$i] - $expected[$i]) > $eps) {
                die ("LogarithmicRegression prediction test : Incorrect value forecasted ($forecast[$i] instead " .
                     "of $expected[$i])");
            }
        } 
    } 'LogarithmicRegression : Testing predict';
}

#    # Configure 
#    $model->configure(
#        data           => \@training_data,
#        freq           => $args{freq},
#        predict_start  => $last_training_index + 1,
#        predict_end    => $#data,
#        combination_id => $args{combination_id},
#        node_id        => $args{node_id},
#    );
#
#    # Forecast the test part of the data
#    my $forecasted_ref = $model->predict(
#        data           => \@training_data,
#        freq           => $args{freq},
#        predict_start  => $last_training_index + 1,
#        predict_end    => $#data,
#        combination_id => $args{combination_id},
#        node_id        => $args{node_id},
#    );

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