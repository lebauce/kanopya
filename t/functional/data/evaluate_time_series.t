#!/usr/bin/perl

use strict;
use warnings;
use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Data::Dumper;
use DataCache;
DataCache::cacheActive(1);

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'evaluate_time_series.log', layout=>'%F %L %p %m%n'});
my $log = get_logger("");


use Kanopya::Database;
use Entity::ServiceProvider::Externalcluster;
use Entity::Component::MockMonitor;
use Entity::Clustermetric;
use Entity::Combination::AggregateCombination;
use Entity::Combination::NodemetricCombination;
use Kanopya::Tools::TimeSerie;


my ($ci_1, $ci_2);
my ($node_1, $node_2);
my ($cm, $comb, $nmcomb);
my $service_provider;

main();

sub main {
    Kanopya::Database::authenticate( login =>'admin', password => 'K4n0pY4' );
    Kanopya::Database::beginTransaction;

    _create_infra();
    _generate_time_series();
    test_nodemetric_combination();
}

sub test_nodemetric_combination {

    my $time = time();
    my $data_fetch = $ci_1->fetch(nodes      => [$node_1, $node_2],
                                  start_time => $time - 1200,
                                  end_time   => $time);

    print Dumper $data_fetch;

    my %data_evaluateTimeSeries = $nmcomb->evaluateTimeSerie(
                                      start_time => $time - 1200,
                                      end_time  => $time,
                                      nodes      => [$node_1, $node_2],
                                  );

    print Dumper \%data_evaluateTimeSeries;
}

sub _generate_time_series {
    my $time_serie = Kanopya::Tools::TimeSerie->new();

    $time_serie->generate(func => '10',
                          rows => 100,
                          step => 60);

    $time_serie->store();
    $time_serie->linkToMetric(metric => $cm);

    $time_serie->generate(func => '100',
                          rows => 100,
                          step => 60);

    $time_serie->store();
    $time_serie->linkToCollectorIndicator(metric => $ci_1, node => $node_1);

    $time_serie->generate(func => '50',
                          rows => 100,
                          step => 60);

    $time_serie->store();
    $time_serie->linkToCollectorIndicator(metric => $ci_1, node => $node_2);
}

sub _create_infra {
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
    $ci_1 = Entity::CollectorIndicator->find (
        hash => {
            collector_manager_id        => $mock_monitor->id,
            'indicator.indicator_oid'   => 'Memory/PercentMemoryUsed',
        }
    );

    $ci_2 = Entity::CollectorIndicator->find (
        hash => {
            collector_manager_id        => $mock_monitor->id,
            'indicator.indicator_oid'   => 'Memory/Pool Paged Bytes'
        }
    );

   # Clustermetric
    $cm = Entity::Clustermetric->new(
                 clustermetric_service_provider_id      => $service_provider->id,
                 clustermetric_indicator_id             => ($ci_1->id),
                 clustermetric_statistics_function_name => 'sum',
                 clustermetric_window_time              => '1200',
             );

    # Combination
    $comb = Entity::Combination::AggregateCombination->new(
                service_provider_id           =>  $service_provider->id,
                aggregate_combination_formula => 'id'.($cm->id),
            );

    # Combination
    $nmcomb = Entity::Combination::NodemetricCombination->new(
                service_provider_id            =>  $service_provider->id,
                nodemetric_combination_formula => 'id'.$ci_1->id.' + id'.$ci_2->id,
             );
}
