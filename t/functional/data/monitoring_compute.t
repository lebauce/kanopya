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
    use Entity::Clustermetric;
    use Entity::Combination::AggregateCombination;
    use Entity::Combination::NodemetricCombination;
} 'All uses';

Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
my $adm = Administrator->new;
$adm->beginTransaction;

my ($indic1, $indic2);
my $service_provider;
my $aggregator;
eval{
    $aggregator = Aggregator->new();

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
    $indic1 = Entity::CollectorIndicator->find (
        hash => {
            collector_manager_id        => $mock_monitor->id,
            'indicator.indicator_oid'   => 'Memory/PercentMemoryUsed',
        }
    );

    $indic2 = Entity::CollectorIndicator->find (
        hash => {
            collector_manager_id        => $mock_monitor->id,
            'indicator.indicator_oid'   => 'Memory/Pool Paged Bytes'
        }
    );

    testCombinationUnit();
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

    testStatisticFunctions();

    testBigAggregation(
        service_provider    => $service_provider,
        aggregator          => $aggregator,
    );

    test_rrd_remove();

    $adm->rollbackTransaction;
};
if($@) {
    $adm->rollbackTransaction;
    my $error = $@;
    print $error."\n";
    fail('Exception occurs');
}

sub testClusterMetric {
    my %args = @_;

    my $service_provider = $args{service_provider};
    my $aggregator       = $args{aggregator};

    diag('Cluster metric computing (last value)');

    my $cm = Entity::Clustermetric->new(
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
    ok (! defined $cm->getLastValueFromDB(), 'Do not store when all values undef');

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
    my $cm1 = Entity::Clustermetric->new(
        clustermetric_service_provider_id       => $service_provider->id,
        clustermetric_indicator_id              => ($indic1->id),
        clustermetric_statistics_function_name  => 'sum',
        clustermetric_window_time               => '1200',
    );

    my $cm2 = Entity::Clustermetric->new(
        clustermetric_service_provider_id       => $service_provider->id,
        clustermetric_indicator_id              => ($indic2->id),
        clustermetric_statistics_function_name  => 'sum',
        clustermetric_window_time               => '1200',
    );

    # Combination
    my $acomb_ident = Entity::Combination::AggregateCombination->new(
        service_provider_id             =>  $service_provider->id,
        aggregate_combination_formula   => 'id'.($cm1->id),
    );

    my $acomb_warn = Entity::Combination::AggregateCombination->new(
        service_provider_id             =>  $service_provider->id,
        aggregate_combination_formula   => '10 / id'.($cm1->id),
    );

    my $acomb1 = Entity::Combination::AggregateCombination->new(
        service_provider_id             =>  $service_provider->id,
        aggregate_combination_formula   => 'id'.($cm1->id).'+'.'id'.($cm2->id).'*3',
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

    my $acomb2 = Entity::Combination::AggregateCombination->new(
        service_provider_id             =>  $service_provider->id,
        aggregate_combination_formula   => '(3.5+id'.($cm1->id).')*(id'.($cm1->id).'/10.1-12.876)',
    );

    my $acomb3 = Entity::Combination::AggregateCombination->new(
        service_provider_id             =>  $service_provider->id,
        aggregate_combination_formula   => '100000000000000000000000000 * id'.($cm1->id),
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
    my $ncomb_ident = Entity::Combination::NodemetricCombination->new(
        service_provider_id             => $service_provider->id,
        nodemetric_combination_formula  => 'id'.($indic1->id),
    );

    my $ncomb2 = Entity::Combination::NodemetricCombination->new(
        service_provider_id             => $service_provider->id,
        nodemetric_combination_formula  => '(id'.($indic1->id).' + 5) * id'.($indic2->id),
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

    # Delete all nodes
    map {$_->delete()} Externalnode->search(hash => {});

    # Create nodes
    for my $i (1..$nodes_count) {
        Externalnode->new(
            externalnode_hostname => 'node_' . $i,
            service_provider_id   => $service_provider->id,
            externalnode_state    => 'up',
        );
    }

    my $cm = Entity::Clustermetric->new(
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

sub testStatisticFunctions {

    # Delete all nodes
    map {$_->delete()} Externalnode->search(hash => {});

    # Create nodes
    for my $i (0..9) {
        Externalnode->new(
            externalnode_hostname => 'node_' . $i,
            service_provider_id   => $service_provider->id,
            externalnode_state    => 'up',
        );
    }

    my $mock_conf  = "{'default':{'const':null},"
                   . "'nodes':{'node_0':{'const':0},
                               'node_1':{'const':60},
                               'node_2':{'const':60},
                               'node_3':{'const':70},
                               'node_4':{'const':75},
                               'node_5':{'const':75},
                               'node_6':{'const':85},
                               'node_7':{'const':90},
                               'node_8':{'const':100},
                               'node_9':{'const':110},
                      }}";

    $service_provider->addManagerParameter(
        manager_type    => 'collector_manager',
        name            => 'mockmonit_config',
        value           => $mock_conf
    );

    my @funcs = ('sum','mean','std','variance','max','min','kurtosis','skewness');
    my @cms = ();
    for my $func (@funcs) {
        push @cms,
            Entity::Clustermetric->new(
                clustermetric_service_provider_id       => $service_provider->id,
                clustermetric_indicator_id              => ($indic1->id),
                clustermetric_statistics_function_name  => $func,
                clustermetric_window_time               => '1200',
            );
    }

    my @acs = ();
    for my $cm (@cms) {
        push @acs,
            Entity::Combination::AggregateCombination->new(
                service_provider_id             =>  $service_provider->id,
                aggregate_combination_formula   => 'id'.($cm->id),
            );
    }

    $aggregator->update();
    my @values = (725,72.5,30.2076149339864,912.5,110,0,3.61461544647883,-1.53239355172722);
    for my $ac (@acs) {
        is($ac->computeLastValue(),shift @values,'Check function '.shift @funcs);
    }

}

sub testCombinationUnit {
    # Cluster metrics
    my $cm1 = Entity::Clustermetric->new(
        clustermetric_service_provider_id       => $service_provider->id,
        clustermetric_indicator_id              => ($indic1->id),
        clustermetric_statistics_function_name  => 'sum',
        clustermetric_window_time               => '1200',
    );

    is ($cm1->getUnit(),'%','Check unit % (a)');
    $cm1->update(clustermetric_statistics_function_name => 'min');
    is ($cm1->getUnit(),'%','Check unit % (b)');
    $cm1->update(clustermetric_indicator_id => ($indic2->id));
    is ($cm1->getUnit(),'Bytes','Check unit bytes');
    $cm1->update(clustermetric_statistics_function_name => 'kurtosis');
    is ($cm1->getUnit(),'-','Check unit bytes');

    my $cm2 = Entity::Clustermetric->new(
        clustermetric_service_provider_id       => $service_provider->id,
        clustermetric_indicator_id              => ($indic2->id),
        clustermetric_statistics_function_name  => 'sum',
        clustermetric_window_time               => '1200',
    );

    my $acomb = Entity::Combination::AggregateCombination->new(
        service_provider_id             =>  $service_provider->id,
        aggregate_combination_formula   => 'id'.($cm2->id).' + id'.($cm1->id),
    );
    is ($acomb->getUnit(),'Bytes + -','Check aggregate combination unit');

    $acomb->update (aggregate_combination_formula   => 'id'.($cm1->id).' + id'.($cm2->id)) ;

    is ($acomb->getUnit(),'- + Bytes','Check aggregate combination unit');

    # Combinations
    my $ncomb = Entity::Combination::NodemetricCombination->new(
        service_provider_id             => $service_provider->id,
        nodemetric_combination_formula  => 'id'.($indic1->id).' + id'.($indic2->id),
    );

    is ($ncomb->getUnit(),'% + Bytes','Check nodemetric combination unit');
    $ncomb->update (nodemetric_combination_formula => 'id'.($indic2->id).' + id'.($indic1->id));
    is ($ncomb->getUnit(),'Bytes + %','Check nodemetric combination unit update');
}

sub test_rrd_remove {
    my @cms = Entity::Clustermetric->search (hash => {
        clustermetric_service_provider_id => $service_provider->id
    });
    
    my @cm_ids = map {$_->id} @cms;
    while (@cms) { (pop @cms)->delete(); };

    is (scalar Entity::Combination::AggregateCombination->search (hash => {
        service_provider_id => $service_provider->id
    }), 0, 'Check all aggregate combinations are deleted');

    is (scalar Entity::AggregateRule->search (hash => {
        aggregate_rule_service_provider_id => $service_provider->id
    }), 0, 'Check all aggregate rules are deleted');

    my $one_rrd_remove = 0;
    for my $cm_id (@cm_ids) {
        if (defined open(FILE,'/var/cache/kanopya/monitor/timeDB_'.$cm_id.'.rrd')) {
            $one_rrd_remove++;
        }
        close(FILE);
    }
    ok ($one_rrd_remove == 0, "Check all have been removed, still $one_rrd_remove rrd");
}