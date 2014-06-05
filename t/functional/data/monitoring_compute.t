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
use DataCache;
DataCache::cacheActive(0);

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>__FILE__ . '.log', layout=>'%F %L %p %m%n'});
my $log = get_logger("");


use Kanopya::Database;
use Aggregator;
use Entity::ServiceProvider::Externalcluster;
use Entity::Component::MockMonitor;
use Entity::Metric::Clustermetric;
use Entity::Metric::Combination::AggregateCombination;
use Entity::Metric::Combination::NodemetricCombination;

Kanopya::Database::authenticate( login =>'admin', password => 'K4n0pY4');

Kanopya::Database::beginTransaction;

my ($indic1, $indic2);
my ($node_1, $node_2);
my $service_provider;
my $aggregator;
eval{
    $aggregator = Aggregator->new();

    $service_provider = Entity::ServiceProvider::Externalcluster->new(
            externalcluster_name => 'Test Service Provider'.time(),
    );

    my $external_cluster_mockmonitor = Entity::ServiceProvider::Externalcluster->new(
            externalcluster_name => 'Test Monitor'.time(),
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
    $node_1 = $service_provider->registerNode(hostname         => 'node_1',
                                              monitoring_state => 'up',
                                              number           => 1);

    # Create node 2
    $node_2 = $service_provider->registerNode(hostname         => 'node_2',
                                              monitoring_state => 'up',
                                              number           => 1);

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

    Kanopya::Database::rollbackTransaction;
};
if($@) {
    my $error = $@;
    print $error."\n";
    Kanopya::Database::rollbackTransaction;
    fail('Exception occurs');

}

sub testClusterMetric {
    my %args = @_;

    lives_ok {
        my $service_provider = $args{service_provider};
        my $aggregator       = $args{aggregator};

        my $cm = Entity::Metric::Clustermetric->new(
                     clustermetric_service_provider_id => $service_provider->id,
                     clustermetric_indicator_id => ($indic1->id),
                     clustermetric_statistics_function_name => 'mean',
                     clustermetric_window_time => '1200',
                 );

        # No node responds
        $service_provider->addManagerParameter(
            manager_type    => 'CollectorManager',
            name            => 'mockmonit_config',
            value           => "{'nodes' : { 'node_1' : { 'const':null }, 'node_2' : { 'const':null }}}"
        );

        $aggregator->update();

        if (defined $cm->lastValue()) {die 'Store values while undef'};

        # All node responds
        $service_provider->addManagerParameter(
            manager_type    => 'CollectorManager',
            name            => 'mockmonit_config',
            value           => "{'nodes' : { 'node_1' : { 'const':50 }, 'node_2' : { 'const':100 }}}"
        );

        sleep 1; # Avoid updating rrd at same time
        $aggregator->update();

        if ($cm->lastValue() != 75) {die 'Wrong value aggregated, stored and retrieved'};

        # One node doesn't respond
        $service_provider->addManagerParameter(
            manager_type    => 'CollectorManager',
            name            => 'mockmonit_config',
            value           => "{'nodes' : { 'node_1' : { 'const':50 }, 'node_2' : { 'const':null }}}"
        );
        sleep 1; # Avoid updating rrd at same time
        $aggregator->update();

        if ($cm->lastValue() != 50) {die 'Fail in aggregate only defined values (ignore undef)'}

        # Float values
        $service_provider->addManagerParameter(
            manager_type    => 'CollectorManager',
            name            => 'mockmonit_config',
            value           => "{'nodes' : { 'node_1' : { 'const':15.123 }, 'node_2' : { 'const':35.877 }}}"
        );
        sleep 1; # Avoid updating rrd at same time
        $aggregator->update();

        if ($cm->lastValue() - 25.5 > 10**-8) {die 'Wrongly aggregate float'}

    } 'Clustermetrics computing';
}

sub testAggregateCombination {
    my %args = @_;

    lives_ok {
        my $service_provider = $args{service_provider};
        my $aggregator          = $args{aggregator};

        # Cluster metrics
        my $cm1 = Entity::Metric::Clustermetric->new(
                      clustermetric_service_provider_id       => $service_provider->id,
                      clustermetric_indicator_id              => ($indic1->id),
                      clustermetric_statistics_function_name  => 'sum',
                      clustermetric_window_time               => '1200',
                  );

        my $cm2 = Entity::Metric::Clustermetric->new(
                      clustermetric_service_provider_id       => $service_provider->id,
                      clustermetric_indicator_id              => ($indic2->id),
                      clustermetric_statistics_function_name  => 'sum',
                      clustermetric_window_time               => '1200',
                  );

        # Combination
        my $acomb_ident = Entity::Metric::Combination::AggregateCombination->new(
                              service_provider_id             =>  $service_provider->id,
                              aggregate_combination_formula   => 'id'.($cm1->id),
                          );

        my $acomb_warn = Entity::Metric::Combination::AggregateCombination->new(
                             service_provider_id             =>  $service_provider->id,
                             aggregate_combination_formula   => '10 / id'.($cm1->id),
                         );

        my $acomb1 = Entity::Metric::Combination::AggregateCombination->new(
                         service_provider_id             =>  $service_provider->id,
                         aggregate_combination_formula   => 'id'.($cm1->id).'+'.'id'.($cm2->id).'*3',
                     );

        my $mock_conf = "{'default':{ 'const':50 }, 'indics' : { 'Memory/Pool Paged Bytes' : { 'const':null }}}";
        $service_provider->addManagerParameter(
            manager_type    => 'CollectorManager',
            name            => 'mockmonit_config',
            value           => $mock_conf
        );

        if (defined $acomb_ident->evaluate()) {die 'Combination defined while no value for metric (U)'}
        if (defined $acomb1->evaluate()) {die 'Combination defined while all metrics values are undef'}
        if (defined $acomb_warn->evaluate()) {die 'Combination defined while divide by undef value in formula'};

        sleep 1; # Avoid updating rrd at same time
        $aggregator->update();

        if (defined $acomb1->evaluate()) {die 'Combination defined while one metric value is undef'};

        if (! ($acomb_ident->evaluate() eq $cm1->lastValue())) { die 'Identity combination as same value than stored metric value'}

        # More complex config:
        #        node1 node2
        # indic1  50    10
        # indic2  50    100
        $mock_conf  = "{'default':{'const':10},"
                    . "'nodes':{'node_1':{'const':50}},'indics':{'Memory/Pool Paged Bytes':{'const':100}}}";
        $service_provider->addManagerParameter(
            manager_type    => 'CollectorManager',
            name            => 'mockmonit_config',
            value           => $mock_conf
        );
        sleep 1; # Avoid updating rrd at same time
        $aggregator->update();

        if (! ($acomb1->evaluate() == 50+10+(50+100)*3)) {die 'Combination wrongly computed'}

        $service_provider->addManagerParameter(
            manager_type    => 'CollectorManager',
            name            => 'mockmonit_config',
            value           => "{'default':{'const':10},'nodes':{'node_1':{ 'const':null }}}"
        );
        sleep 1; # Avoid updating rrd at same time
        $aggregator->update();

        if (! ($acomb1->evaluate() == 10+10*3)) { die 'Combination wrongly computed (with one node not responding)'}

        my $acomb2 = Entity::Metric::Combination::AggregateCombination->new(
                         service_provider_id           =>  $service_provider->id,
                         aggregate_combination_formula => '(3.5+id' . ($cm1->id)
                                                          . ')*(id' . ($cm1->id).'/10.1-12.876)',
                     );

        my $acomb3 = Entity::Metric::Combination::AggregateCombination->new(
                         service_provider_id           =>  $service_provider->id,
                         aggregate_combination_formula => '100000000000000000000000000 * id' . ($cm1->id),
                     );

        $service_provider->addManagerParameter(
            manager_type    => 'CollectorManager',
            name            => 'mockmonit_config',
            value           => "{'default':{'const':10.123}}"
        );
        sleep 1; # Avoid updating rrd at same time
        $aggregator->update();

        if ($acomb1->evaluate() - 10.123*2*4 > 10**-8) {die 'Combination wrongly computed with float values'};

        if (! $acomb2->evaluate() - ((3.5 + 20.246)*(20.246/10.1 - 12.876)) < 10**-8) {
            die 'Fail in combination with complex formula (parenthesis, all operators, float, neg res)'
        }
        if (! ($acomb3->evaluate() - 100000000000000000000000000*20.246 < 10**-8)) {die 'Combination with big value'};
    } 'Aggregate combination computing'
}

sub testNodemetricCombination {
    my %args = @_;

    my $service_provider = $args{service_provider};

    lives_ok {
        # Combinations
        my $ncomb_ident = Entity::Metric::Combination::NodemetricCombination->new(
                              service_provider_id             => $service_provider->id,
                              nodemetric_combination_formula  => 'id' . ($indic1->id),
                          );

        my $ncomb2 = Entity::Metric::Combination::NodemetricCombination->new(
                         service_provider_id             => $service_provider->id,
                         nodemetric_combination_formula  => '(id' . ($indic1->id) . ' + 5) * id' . ($indic2->id),
                     );

        my $mock_conf  = "{'default':{'const':null}}";

        $service_provider->addManagerParameter(
            manager_type    => 'CollectorManager',
            name            => 'mockmonit_config',
            value           => $mock_conf
        );

        $aggregator->update();

        my $evaluation = $ncomb_ident->evaluate(node => $node_1);
        if (defined $evaluation) {
            die 'Identity combination defined while no value for indicator' . $evaluation;
        }

        $evaluation = $ncomb2->evaluate(node => $node_1);
        if (defined $evaluation) {
            die 'Combination defined while all indicator values are undef =>'.$evaluation;
        }

        # More complex config:
        #        node1 node2
        # indic1  42    12
        # indic2  42    null

        $mock_conf  = "{'default':{'const':42}}";

        $service_provider->addManagerParameter(
            manager_type    => 'CollectorManager',
            name            => 'mockmonit_config',
            value           => $mock_conf
        );

        $aggregator->update();

        $evaluation = $ncomb_ident->evaluate(node => $node_1);
        if (! (defined $evaluation && $evaluation == 42)) {
            die 'Identity combination as same value than indicator';
        }

        $mock_conf = "{'default':{ 'const':42 }, 'indics' : { 'Memory/Pool Paged Bytes' : { 'const':null }}}";
        $service_provider->addManagerParameter(
            manager_type    => 'CollectorManager',
            name            => 'mockmonit_config',
            value           => $mock_conf
        );

        $aggregator->update();

        if (defined $ncomb2->evaluate(node => $node_2)) {
            die 'Combination defined while one indicator value is undef'
        }

        $mock_conf  = "{'default':{'const':42},"
                         . "'indics':{'Memory/PercentMemoryUsed':{'const':42},'Memory/Pool Paged Bytes':{'const':12}}}";

        $service_provider->addManagerParameter(
            manager_type    => 'CollectorManager',
            name            => 'mockmonit_config',
            value           => $mock_conf
        );

        $aggregator->update();

        if (! ($ncomb2->evaluate(node => $node_1) == (42 + 5)*12)) {
            die 'Combination correctly computed';
        }

        $mock_conf = "{'default':{ 'const':1.2 }, 'indics' : { 'Memory/Pool Paged Bytes' : { 'const':42.42 }}}";
        $service_provider->addManagerParameter(
            manager_type    => 'CollectorManager',
            name            => 'mockmonit_config',
            value           => $mock_conf
        );

        $aggregator->update();

        if ($ncomb2->evaluate(node => $node_1) - (1.2 + 5)*42.42 > 10**-8) {
            die 'Combination correctly computed with float values';
        }
    } 'Nodemetric combination computing'
}

sub testBigAggregation {
    my %args = @_;
    my $nodes_count = 500;

    lives_ok {
        my $service_provider    = $args{service_provider};
        my $aggregator          = $args{aggregator};

        # Delete all nodes
        map {$_->delete()} Node->search(hash => {node_hostname => {-like => 'node_%'}});

        # Create nodes
        for my $i (1..$nodes_count) {
            $service_provider->registerNode(hostname         => 'node_' . $i,
                                            monitoring_state => 'up',
                                            number           => $i);
        }

        my $cm = Entity::Metric::Clustermetric->new(
                     clustermetric_service_provider_id => $service_provider->id,
                     clustermetric_indicator_id => ($indic1->id),
                     clustermetric_statistics_function_name => 'sum',
                     clustermetric_window_time => '1200',
                 );

        $service_provider->addManagerParameter(
            manager_type    => 'CollectorManager',
            name            => 'mockmonit_config',
            value           => "{'default':{'const':12}}"
        );
        $aggregator->update();

        if (! ($cm->lastValue() == 12*$nodes_count)) {die 'Wrongly aggregated when values for all nodes'}

        my $mock_conf   = "{'default':{'const':12},"
                        . "'nodes':{'node_1':{'const':null},'node_10':{'const':null},'node_100':{'const':null} }}";
        $service_provider->addManagerParameter(
            manager_type    => 'CollectorManager',
            name            => 'mockmonit_config',
            value           => $mock_conf
        );
        sleep 1; # Avoid updating rrd at same time
        $aggregator->update();

        if (! ($cm->lastValue() == 12*$nodes_count - 3*12)) {die 'Wrongly aggregated when few undef values'};

        $mock_conf  = "{'default':{'const':null},"
                    . "'nodes':{'node_2':{'const':23},'node_20':{'const':24},'node_90':{'const':25} }}";
        $service_provider->addManagerParameter(
            manager_type    => 'CollectorManager',
            name            => 'mockmonit_config',
            value           => $mock_conf
        );
        sleep 1; # Avoid updating rrd at same time
        $aggregator->update();

        if (! ($cm->lastValue() == 23+24+25)) {'Wrongly aggregated when lot of undef values'};
    } 'Aggregation on big cluster (' . $nodes_count . ' nodes)'
}

sub testStatisticFunctions {

    lives_ok {
        # Delete all nodes
        map {$_->delete()} Node->search(hash => {node_hostname => {-like => 'node_%'}});

        # Create nodes
        for my $i (0..9) {
            $service_provider->registerNode(hostname         => 'node_' . $i,
                                            monitoring_state => 'up',
                                            number           => $i);
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
            manager_type    => 'CollectorManager',
            name            => 'mockmonit_config',
            value           => $mock_conf
        );

        my @funcs = ('sum','mean','std','variance','max','min','kurtosis','skewness');
        my @cms = ();
        for my $func (@funcs) {
            push @cms,
                Entity::Metric::Clustermetric->new(
                    clustermetric_service_provider_id       => $service_provider->id,
                    clustermetric_indicator_id              => ($indic1->id),
                    clustermetric_statistics_function_name  => $func,
                    clustermetric_window_time               => '1200',
                );
        }

        my @acs = ();
        for my $cm (@cms) {
            push @acs,
                Entity::Metric::Combination::AggregateCombination->new(
                    service_provider_id             =>  $service_provider->id,
                    aggregate_combination_formula   => 'id'.($cm->id),
                );
        }

        $aggregator->update();

        my @values = (725,72.5,30.2076149339864,912.5,110,0,3.61461544647883,-1.53239355172722);
        for my $ac (@acs) {
            if ($ac->evaluate() - shift @values > 10**-8) { die 'Fail in check function '.shift @funcs};
        }
    } 'Statistic functions';
}

sub testCombinationUnit {
    lives_ok {

        # Cluster metrics
        my $cm1 = Entity::Metric::Clustermetric->new(
                      clustermetric_service_provider_id       => $service_provider->id,
                      clustermetric_indicator_id              => ($indic1->id),
                      clustermetric_statistics_function_name  => 'sum',
                      clustermetric_window_time               => '1200',
                  );

        if (! ($cm1->getUnit() eq '%')) { die 'Fail in sum unit'}

        $cm1->update(clustermetric_statistics_function_name => 'min');
        if (! ($cm1->getUnit() eq '%')) { die 'Fail in min unit'}

        $cm1->update(clustermetric_indicator_id => ($indic2->id));
        if (! ($cm1->getUnit() eq'Bytes')) {die 'Fail in changing unit when updating indicator'}

        $cm1->update(clustermetric_statistics_function_name => 'kurtosis');
        if (! ($cm1->getUnit() eq '-')) {die 'Fail in no unit'}

        my $cm2 = Entity::Metric::Clustermetric->new(
                      clustermetric_service_provider_id       => $service_provider->id,
                      clustermetric_indicator_id              => ($indic2->id),
                      clustermetric_statistics_function_name  => 'sum',
                      clustermetric_window_time               => '1200',
                  );

        my $acomb = Entity::Metric::Combination::AggregateCombination->new(
                        service_provider_id             =>  $service_provider->id,
                        aggregate_combination_formula   => 'id' . ($cm2->id)
                                                           . ' + id' . ($cm1->id),
                    );

        if (! ($acomb->getUnit() eq 'Bytes + -')) {die 'Fail in aggregate combination unit'}

        $acomb->update (aggregate_combination_formula   => 'id'.($cm1->id).' + id'.($cm2->id)) ;

        if (! ($acomb->getUnit() eq '- + Bytes')) {die 'Fail in aggregate combination update unit'}

        # Combinations
        my $ncomb = Entity::Metric::Combination::NodemetricCombination->new(
                        service_provider_id             => $service_provider->id,
                        nodemetric_combination_formula  => 'id' . ($indic1->id)
                                                           . ' + id' . ($indic2->id),
                    );

        if (! ($ncomb->getUnit() eq '% + Bytes')) {die 'Fail in nodemetric combination unit'}

        $ncomb->update (nodemetric_combination_formula => 'id'.($indic2->id).' + id'.($indic1->id));
        if (! ($ncomb->getUnit() eq 'Bytes + %')) {die 'Fail in nodemetric combination update unit'}

    } 'Unit'
}

sub test_rrd_remove {
    lives_ok {
        my @cms = Entity::Metric::Clustermetric->search (hash => {
                      clustermetric_service_provider_id => $service_provider->id
                  });

        my @nodeids = map { $_->id } $service_provider->nodes;
        my @nms = Entity::Metric::Nodemetric->search (hash => {
                      nodemetric_node_id => \@nodeids
                  });

        my @metrics = (@cms, @nms);
        my @mids = map { $_->id } @metrics;
        while (@metrics ) { (pop @metrics )->delete(); };

        my @acs = Entity::Metric::Combination::AggregateCombination->search (hash => {
                      service_provider_id => $service_provider->id
                  });

        if (! ((scalar @acs) == 0)) {die 'Fail '.(scalar @acs).' aggregate combinations have not been deleted'}

        my $one_rrd_remove = 0;
        for my $mid (@mids) {
            if (defined open(FILE,'/var/cache/kanopya/monitor/timeDB_'.$mid.'.rrd')) {
                $one_rrd_remove++;
            }
            close(FILE);
        }
        if (! ($one_rrd_remove == 0)) {"Fail $one_rrd_remove rrd have not been deleted"};
    } 'RRD Remove'
}
