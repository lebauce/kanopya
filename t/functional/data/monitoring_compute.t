#!/usr/bin/perl

#########################################
# Test monitoring objects computing     #
#   - clustermetric value (aggregation) #
#   - AggregateCombination value        #
#   - NodemetricCombination value       #
#########################################

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Data::Dumper;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'/tmp/monitor_test.log', layout=>'%F %L %p %m%n'});
my $log = get_logger("");


lives_ok {
    use Administrator;
    use Aggregator;

    use Entity::ServiceProvider::Outside::Externalcluster;
    use Entity::Connector::MockMonitor;
    use Clustermetric;
    use AggregateCombination;
    use NodemetricCombination;
} 'All uses';

Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
my $adm = Administrator->new;
$adm->{db}->txn_begin;

my ($indic1, $indic2);
my $service_provider;

eval{

    my $aggregator= Aggregator->new();

    $service_provider = Entity::ServiceProvider::Outside::Externalcluster->new(
            externalcluster_name => 'Test Service Provider',
    );

    my $external_cluster_mockmonitor = Entity::ServiceProvider::Outside::Externalcluster->new(
            externalcluster_name => 'Test Monitor',
    );

    my $mock_monitor = Entity::Connector::MockMonitor->new(
            service_provider_id => $external_cluster_mockmonitor->id,
    );

    lives_ok{
        $service_provider->addManager(
            manager_id      => $mock_monitor->id,
            manager_type    => 'collector_manager',
            no_default_conf => 1,
        );
    } 'Add mock monitor to service provider';

    # Create node 1
    Externalnode->new(
        externalnode_hostname => 'node_1',
        service_provider_id   => $service_provider->id,
        externalnode_state    => 'up',
    );

    # Create node 2
    Externalnode->new(
        externalnode_hostname => 'node_2',
        service_provider_id   => $service_provider->id,
        externalnode_state    => 'up',
    );

    # Get indicators
    $indic1 = ScomIndicator->find (
        hash => {
            service_provider_id => $service_provider->id,
            indicator_oid => 'Memory/PercentMemoryUsed'
        }
    );

    $indic2 = ScomIndicator->find (
        hash => {
            service_provider_id => $service_provider->id,
            indicator_oid => 'Memory/Pool Paged Bytes'
        }
    );

    # Tests
    testClusterMetric(
        service_provider    => $service_provider,
        aggregator          => $aggregator,
    );

    testAggregateCombination(
        service_provider    => $service_provider,
        aggregator          => $aggregator,
    );

    testNodemetricCombination(
        service_provider    => $service_provider,
    );

    testBigAggregation(
        service_provider    => $service_provider,
        aggregator          => $aggregator,
    );

    $adm->{db}->txn_rollback;
};
if($@) {
    $adm->{db}->txn_rollback;
    my $error = $@;
    print $error."\n";
}

sub testClusterMetric {
    my %args = @_;

    my $service_provider     = $args{service_provider};
    my $aggregator          = $args{aggregator};

    diag('Cluster metric computing (last value)');

    my $indic1 = ScomIndicator->find (
        hash => {
            service_provider_id => $service_provider->id,
            indicator_oid => 'Memory/PercentMemoryUsed'
        }
    );

    my $cm = Clustermetric->new(
        clustermetric_service_provider_id => $service_provider->id,
        clustermetric_indicator_id => ($indic1->id),
        clustermetric_statistics_function_name => 'mean',
        clustermetric_window_time => '1200',
    );

    # No node responds
    $service_provider->addManagerParameter(
        manager_type    => 'collector_manager',
        name            => 'mockmonit_config',
        value           => "{'nodes' : { 'node_1' : { 'const':null }, 'node_2' : { 'const':null }}}"
    );
    $aggregator->update();
    is($cm->getLastValueFromDB(), 'U', 'Do not store when all values undef');

    # All node responds
    $service_provider->addManagerParameter(
        manager_type    => 'collector_manager',
        name            => 'mockmonit_config',
        value           => "{'nodes' : { 'node_1' : { 'const':50 }, 'node_2' : { 'const':100 }}}"
    );
    sleep 1; # Avoid updating rrd at same time
    $aggregator->update();
    is($cm->getLastValueFromDB(), 75, 'Good value aggregated, stored and retrieved');

    # One node doesn't respond
    $service_provider->addManagerParameter(
        manager_type    => 'collector_manager',
        name            => 'mockmonit_config',
        value           => "{'nodes' : { 'node_1' : { 'const':50 }, 'node_2' : { 'const':null }}}"
    );
    sleep 1; # Avoid updating rrd at same time
    $aggregator->update();
    is($cm->getLastValueFromDB(), 50, 'Aggregate only defined values (ignore undef)');

    # Float values
    $service_provider->addManagerParameter(
        manager_type    => 'collector_manager',
        name            => 'mockmonit_config',
        value           => "{'nodes' : { 'node_1' : { 'const':15.123 }, 'node_2' : { 'const':35.877 }}}"
    );
    sleep 1; # Avoid updating rrd at same time
    $aggregator->update();
    is($cm->getLastValueFromDB(), 25.5, 'Correctly aggregate float');
}

sub testAggregateCombination {
    my %args = @_;

    my $service_provider = $args{service_provider};
    my $aggregator          = $args{aggregator};

    diag('Aggregate combination computing (last value)');

    # Cluster metrics
    my $cm1 = Clustermetric->new(
        clustermetric_service_provider_id       => $service_provider->id,
        clustermetric_indicator_id              => ($indic1->id),
        clustermetric_statistics_function_name  => 'sum',
        clustermetric_window_time               => '1200',
    );

    my $cm2 = Clustermetric->new(
        clustermetric_service_provider_id       => $service_provider->id,
        clustermetric_indicator_id              => ($indic2->id),
        clustermetric_statistics_function_name  => 'sum',
        clustermetric_window_time               => '1200',
    );

    # Combination
    my $acomb_ident = AggregateCombination->new(
        aggregate_combination_service_provider_id   =>  $service_provider->id,
        aggregate_combination_formula               => 'id'.($cm1->id),
    );

    my $acomb_warn = AggregateCombination->new(
        aggregate_combination_service_provider_id   =>  $service_provider->id,
        aggregate_combination_formula               => '10 / id'.($cm1->id),
    );

    my $acomb1 = AggregateCombination->new(
        aggregate_combination_service_provider_id   =>  $service_provider->id,
        aggregate_combination_formula               => 'id'.($cm1->id).'+'.'id'.($cm2->id).'*3',
    );

    my $mock_conf = "{'default':{ 'const':50 }, 'indics' : { 'Memory/Pool Paged Bytes' : { 'const':null }}}";
    $service_provider->addManagerParameter(
        manager_type    => 'collector_manager',
        name            => 'mockmonit_config',
        value           => $mock_conf
    );

    is( $acomb_ident->computeLastValue(),
        undef,
        "Identity combination is undef when no value for metric ('U')"
    );
    is($acomb1->computeLastValue(), undef, 'Combination is undef when all metrics values are undef');
    is($acomb_warn->computeLastValue(), undef, 'Combination is undef when divide by undef value in formula');

    sleep 1; # Avoid updating rrd at same time
    $aggregator->update();
    is($acomb1->computeLastValue(), undef, 'Combination is undef if one metric value is undef');
    is( $acomb_ident->computeLastValue(),
        $cm1->getLastValueFromDB(),
        'Identity combination as same value than stored metric value'
    );

    # More complex config:
    #        node1 node2
    # indic1  50    10
    # indic2  50    100
    $mock_conf  = "{'default':{'const':10},"
                . "'nodes':{'node_1':{'const':50}},'indics':{'Memory/Pool Paged Bytes':{'const':100}}}";
    $service_provider->addManagerParameter(
        manager_type    => 'collector_manager',
        name            => 'mockmonit_config',
        value           => $mock_conf
    );
    sleep 1; # Avoid updating rrd at same time
    $aggregator->update();
    is($acomb1->computeLastValue(), 50+10+(50+100)*3, 'Combination correctly computed');

    $service_provider->addManagerParameter(
        manager_type    => 'collector_manager',
        name            => 'mockmonit_config',
        value           => "{'default':{'const':10},'nodes':{'node_1':{ 'const':null }}}"
    );
    sleep 1; # Avoid updating rrd at same time
    $aggregator->update();
    is($acomb1->computeLastValue(), 10+10*3, 'Combination correctly computed (with one node not responding)');

    my $acomb2 = AggregateCombination->new(
        aggregate_combination_service_provider_id   =>  $service_provider->id,
        aggregate_combination_formula               => '(3.5+id'.($cm1->id).')*(id'.($cm1->id).'/10.1-12.876)',
    );

    my $acomb3 = AggregateCombination->new(
        aggregate_combination_service_provider_id   =>  $service_provider->id,
        aggregate_combination_formula               => '100000000000000000000000000 * id'.($cm1->id),
    );

    $service_provider->addManagerParameter(
        manager_type    => 'collector_manager',
        name            => 'mockmonit_config',
        value           => "{'default':{'const':10.123}}"
    );
    sleep 1; # Avoid updating rrd at same time
    $aggregator->update();
    is($acomb1->computeLastValue(), 10.123*2*4, 'Combination correctly computed with float values');
    is( $acomb2->computeLastValue(),
        (3.5 + 20.246)*(20.246/10.1 - 12.876),
        'Combination with complex formula (parenthesis, all operators, float, neg res)'
    );
    is($acomb3->computeLastValue(), 100000000000000000000000000*20.246, 'Combination with big value');
}

sub testNodemetricCombination {
    my %args = @_;

    my $service_provider = $args{service_provider};

    diag('Nodemetric combination computing');

    # Combinations
    my $ncomb_ident = NodemetricCombination->new(
        nodemetric_combination_service_provider_id => $service_provider->id,
        nodemetric_combination_formula             => 'id'.($indic1->id),
    );

    my $ncomb2 = NodemetricCombination->new(
        nodemetric_combination_service_provider_id => $service_provider->id,
        nodemetric_combination_formula             => '(id'.($indic1->id).' + 5) * id'.($indic2->id),
    );

    is(
        $ncomb_ident->computeValueFromMonitoredValues( monitored_values_for_one_node => {}),
        undef,
        'Identity combination is undef when no value for indicator'
    );
    is(
        $ncomb_ident->computeValueFromMonitoredValues(
            monitored_values_for_one_node => {'Memory/PercentMemoryUsed' => 42}
        ),
        42,
        'Identity combination as same value than indicator'
    );
    is(
        $ncomb2->computeValueFromMonitoredValues( monitored_values_for_one_node => {}),
        undef,
        'Combination is undef if all indicator values are undef'
    );
    is(
        $ncomb2->computeValueFromMonitoredValues(
            monitored_values_for_one_node => {'Memory/PercentMemoryUsed' => 42}
        ),
        undef,
        'Combination is undef if one indicator value is undef'
    );
    is(
        $ncomb2->computeValueFromMonitoredValues(
            monitored_values_for_one_node => {
                'Memory/PercentMemoryUsed' => 42, 'Memory/Pool Paged Bytes' => 12
            }
        ),
        (42 + 5)*12,
        'Combination correctly computed'
    );
    is(
        $ncomb2->computeValueFromMonitoredValues(
            monitored_values_for_one_node => {
                'Memory/PercentMemoryUsed' => 1.2, 'Memory/Pool Paged Bytes' => 42.42
            }
        ),
        (1.2 + 5)*42.42,
        'Combination correctly computed with float values'
    );
}

sub testBigAggregation {
    my %args = @_;

    my $nodes_count = 500;
    diag('Aggregation on big cluster (' . $nodes_count . ' nodes)');

    my $service_provider    = $args{service_provider};
    my $aggregator          = $args{aggregator};

    Externalnode->find(hash => {externalnode_hostname => 'node_1'})->delete();
    Externalnode->find(hash => {externalnode_hostname => 'node_2'})->delete();

    # Create nodes
    for my $i (1..$nodes_count) {
        Externalnode->new(
            externalnode_hostname => 'node_' . $i,
            service_provider_id   => $service_provider->id,
            externalnode_state    => 'up',
        );
    }

    my $cm = Clustermetric->new(
        clustermetric_service_provider_id => $service_provider->id,
        clustermetric_indicator_id => ($indic1->id),
        clustermetric_statistics_function_name => 'sum',
        clustermetric_window_time => '1200',
    );

    $service_provider->addManagerParameter(
        manager_type    => 'collector_manager',
        name            => 'mockmonit_config',
        value           => "{'default':{'const':12}}"
    );
    $aggregator->update();
    is($cm->getLastValueFromDB(), 12*$nodes_count, 'Correctly aggregated when values for all nodes');

    my $mock_conf   = "{'default':{'const':12},"
                    . "'nodes':{'node_1':{'const':null},'node_10':{'const':null},'node_100':{'const':null} }}";
    $service_provider->addManagerParameter(
        manager_type    => 'collector_manager',
        name            => 'mockmonit_config',
        value           => $mock_conf
    );
    sleep 1; # Avoid updating rrd at same time
    $aggregator->update();
    is($cm->getLastValueFromDB(), 12*$nodes_count - 3*12, 'Correctly aggregated when few undef values');

    $mock_conf  = "{'default':{'const':null},"
                . "'nodes':{'node_2':{'const':23},'node_20':{'const':24},'node_90':{'const':25} }}";
    $service_provider->addManagerParameter(
        manager_type    => 'collector_manager',
        name            => 'mockmonit_config',
        value           => $mock_conf
    );
    sleep 1; # Avoid updating rrd at same time
    $aggregator->update();
    is($cm->getLastValueFromDB(), 23+24+25, 'Correctly aggregated when lot of undef values');
}
