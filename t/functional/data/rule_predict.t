#!/usr/bin/perl

use strict;
use warnings;
use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Data::Dumper;
use Kanopya::Database;
use Aggregator;
use Entity::ServiceProvider::Externalcluster;
use Entity::Component::MockMonitor;
use Entity::Clustermetric;
use Entity::Combination::AggregateCombination;
use Entity::Combination::NodemetricCombination;
use Kanopya::Tools::TimeSerie;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'monitor_test.log', layout=>'%F %L %p %m%n'});
my $log = get_logger("");

Kanopya::Database::authenticate( login =>'admin', password => 'K4n0pY4' );

Kanopya::Database::beginTransaction;

my ($indic1, $indic2);
my ($node_1, $node_2);
my $acomb;
my $acond;
my $rule1;
my $cm;
my $service_provider;
my $aggregator;
eval{

    setup();

    fill_rrd();

    rule_predict();

    Kanopya::Database::rollbackTransaction;
};
if($@) {
    my $error = $@;
    print $error."\n";
    Kanopya::Database::rollbackTransaction;
    fail('Exception occurs');

}

sub rule_predict {

    lives_ok {
        my $value      = $acomb->evaluate();
        my $value_pred = $acomb->evaluate(timestamp => time() + 2400);


        if (! ($value < 11 && $value_pred > 11)) {
            die "Wrong aggregate combination value or prediction <$value> <$value_pred>";
        } 

        my $cond_value = $acond->evaluate();
        my $cond_value_pred = $acond->evaluate(timestamp => time() + 2400);

        if (! ($cond_value == 0 && $cond_value_pred == 1)) {
            die "Wrong aggregate condition value or prediction <$cond_value> <$cond_value_pred>";
        } 

        my $rule_value = $rule1->evaluate();
        my $rule_value_pred = $rule1->evaluate(timestamp => time() + 2400);

        if (! ((values %{$rule_value})[0] == 0 && (values %{$rule_value_pred})[0] == 1)) {
            die 'Wrong aggregate condition value or prediction <'.((values %{$rule_value})[0]).'> <'.((values %{$rule_value_pred})[0]).'>';
        } 

    } 'Prediction';
}

sub fill_rrd {
    my $time_serie = Kanopya::Tools::TimeSerie->new();

        $time_serie->generate(func => 'X',
                              srand => 1,
                              rows => 100,
                              step => 60,
                              precision => {
                                 X => 0.1
                              });
        $time_serie->store();
        $time_serie->linkToMetric(metric => $cm);
}

sub setup {
    $aggregator = Aggregator->new();

    $service_provider = Entity::ServiceProvider::Externalcluster->new(
            externalcluster_name => 'Test Service Provider',
    );

    my $external_cluster_mockmonitor = Entity::ServiceProvider::Externalcluster->new(
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
        node_hostname => 'node_1',
        service_provider_id   => $service_provider->id,
        monitoring_state    => 'up',
    );

    # Create node 2
    $node_2 = Node->new(
        node_hostname => 'node_2',
        service_provider_id   => $service_provider->id,
        monitoring_state    => 'up',
    );

    # Get indicators
    $indic1 = Entity::CollectorIndicator->find (
        hash => {
            collector_manager_id        => $mock_monitor->id,
            'indicator.indicator_oid'   => 'Memory/PercentMemoryUsed',
        }
    );

    # Clustermetric
    $cm = Entity::Clustermetric->new(
        clustermetric_service_provider_id => $service_provider->id,
        clustermetric_indicator_id => ($indic1->id),
        clustermetric_statistics_function_name => 'sum',
        clustermetric_window_time => '1200',
    );

    # Combination
    $acomb = Entity::Combination::AggregateCombination->new(
        service_provider_id             =>  $service_provider->id,
        aggregate_combination_formula   => 'id'.($cm->id),
    );

    # Condition
    $acond = Entity::AggregateCondition->new(
        aggregate_condition_service_provider_id => $service_provider->id,
        left_combination_id => $acomb->id,
        comparator => '>',
        threshold => '10',
    );

    $rule1 = Entity::Rule::AggregateRule->new(
        service_provider_id => $service_provider->id,
        formula => 'id'.$acond->id,
        state => 'enabled'
    );
}

