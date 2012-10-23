#!/usr/bin/perl

use strict;
use warnings;
use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Data::Dumper;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'/tmp/rule_compute.log', layout=>'%F %L %p %m%n'});
my $log = get_logger("");


lives_ok {
    use Administrator;
    use Aggregator;
    use Orchestrator;
    use Entity::ServiceProvider::Outside::Externalcluster;
    use Entity::Connector::MockMonitor;
    use Clustermetric;
    use AggregateCombination;
    use NodemetricCombination;

} 'All uses';

Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
my $adm = Administrator->new;
$adm->beginTransaction;

my ($indic1);
my ($ac_f, $ac_t);
my $service_provider;
my $aggregator;
my $orchestrator;

eval{

    $aggregator= Aggregator->new();
    $orchestrator = Orchestrator->new();

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

    # Get indicators
    $indic1 = ScomIndicator->find (
        hash => {
            service_provider_id => $service_provider->id,
            indicator_oid => 'Memory/PercentMemoryUsed'
        }
    );

    test_aggregate_rules();

    $adm->rollbackTransaction;
};
if($@) {
    $adm->rollbackTransaction;
    my $error = $@;
    print $error."\n";
}

sub test_aggregate_rules {
    my %args = @_;

    # Clustermetric
    my $cm = Clustermetric->new(
        clustermetric_service_provider_id => $service_provider->id,
        clustermetric_indicator_id => ($indic1->id),
        clustermetric_statistics_function_name => 'sum',
        clustermetric_window_time => '1200',
    );

    # Combination
    my $comb = AggregateCombination->new(
        aggregate_combination_service_provider_id   =>  $service_provider->id,
        aggregate_combination_formula               => 'id'.($cm->id),
    );

    # Condition
    $ac_t = AggregateCondition->new(
        aggregate_condition_service_provider_id => $service_provider->id,
        aggregate_combination_id => $comb->id,
        comparator => '>',
        threshold => '0',
        state => 'enabled'
    );

    $ac_f = AggregateCondition->new(
        aggregate_condition_service_provider_id => $service_provider->id,
        aggregate_combination_id => $comb->id,
        comparator => '<',
        threshold => '0',
        state => 'enabled'
    );

    # No node responds
    $service_provider->addManagerParameter(
        manager_type    => 'collector_manager',
        name            => 'mockmonit_config',
        value           => "{'default':{ 'const':50 }}",
    );

    $aggregator->update();

    is($ac_t->eval, 1, 'Check true condition');
    is($ac_f->eval, 0, 'Check false condition');


    test_not();
    test_or();
    test_and();
    test_big_formulas();
}

sub test_and {
    my $rule1 = AggregateRule->new(
        aggregate_rule_service_provider_id => $service_provider->id,
        aggregate_rule_formula => 'id'.$ac_t->id.' && id'.$ac_t->id,
        aggregate_rule_state => 'enabled'
    );

    my $rule2 = AggregateRule->new(
        aggregate_rule_service_provider_id => $service_provider->id,
        aggregate_rule_formula => 'id'.$ac_t->id.' && id'.$ac_f->id,
        aggregate_rule_state => 'enabled'
    );

    my $rule3 = AggregateRule->new(
        aggregate_rule_service_provider_id => $service_provider->id,
        aggregate_rule_formula => 'id'.$ac_f->id.' && id'.$ac_t->id,
        aggregate_rule_state => 'enabled'
    );

    my $rule4 = AggregateRule->new(
        aggregate_rule_service_provider_id => $service_provider->id,
        aggregate_rule_formula => 'id'.$ac_f->id.' && id'.$ac_f->id,
        aggregate_rule_state => 'enabled'
    );

    $orchestrator->manage_aggregates();
    is($rule1->eval, 1, 'Check 1 && 1 rule');
    is($rule2->eval, 0, 'Check 1 && 0 rule');
    is($rule3->eval, 0, 'Check 0 && 1 rule');
    is($rule4->eval, 0, 'Check 0 && 0 rule');
}

sub test_or {
    my $rule1 = AggregateRule->new(
        aggregate_rule_service_provider_id => $service_provider->id,
        aggregate_rule_formula => 'id'.$ac_t->id.' || id'.$ac_t->id,
        aggregate_rule_state => 'enabled'
    );

    my $rule2 = AggregateRule->new(
        aggregate_rule_service_provider_id => $service_provider->id,
        aggregate_rule_formula => 'id'.$ac_t->id.' || id'.$ac_f->id,
        aggregate_rule_state => 'enabled'
    );

    my $rule3 = AggregateRule->new(
        aggregate_rule_service_provider_id => $service_provider->id,
        aggregate_rule_formula => 'id'.$ac_f->id.' || id'.$ac_t->id,
        aggregate_rule_state => 'enabled'
    );

    my $rule4 = AggregateRule->new(
        aggregate_rule_service_provider_id => $service_provider->id,
        aggregate_rule_formula => 'id'.$ac_f->id.' || id'.$ac_f->id,
        aggregate_rule_state => 'enabled'
    );

    $orchestrator->manage_aggregates();
    is($rule1->eval, 1, 'Check 1 || 1 rule');
    is($rule2->eval, 1, 'Check 1 || 0 rule');
    is($rule3->eval, 1, 'Check 0 || 1 rule');
    is($rule4->eval, 0, 'Check 0 || 0 rule');
}

sub test_not{
    my $rule1 = AggregateRule->new(
        aggregate_rule_service_provider_id => $service_provider->id,
        aggregate_rule_formula => 'id'.$ac_t->id,
        aggregate_rule_state => 'enabled'
    );

    my $rule2 = AggregateRule->new(
        aggregate_rule_service_provider_id => $service_provider->id,
        aggregate_rule_formula => '! id'.$ac_t->id,
        aggregate_rule_state => 'enabled'
    );

    my $rule3 = AggregateRule->new(
        aggregate_rule_service_provider_id => $service_provider->id,
        aggregate_rule_formula => 'id'.$ac_f->id,
        aggregate_rule_state => 'enabled'
    );

    my $rule4 = AggregateRule->new(
        aggregate_rule_service_provider_id => $service_provider->id,
        aggregate_rule_formula => '! id'.$ac_f->id,
        aggregate_rule_state => 'enabled'
    );

    my $rule5 = AggregateRule->new(
        aggregate_rule_service_provider_id => $service_provider->id,
        aggregate_rule_formula => '!! id'.$ac_t->id,
        aggregate_rule_state => 'enabled'
    );

    my $rule6 = AggregateRule->new(
        aggregate_rule_service_provider_id => $service_provider->id,
        aggregate_rule_formula => '!!! id'.$ac_t->id,
        aggregate_rule_state => 'enabled'
    );

    $orchestrator->manage_aggregates();
    is($rule1->eval, 1, 'Check 1 rule');
    is($rule2->eval, 0, 'Check ! 1 rule');
    is($rule3->eval, 0, 'Check 0 rule');
    is($rule4->eval, 1, 'Check ! 0 rule');
    is($rule5->eval, 1, 'Check !! 1 rule');
    is($rule6->eval, 0, 'Check !!! 1 rule');
}

sub test_big_formulas {
    my $rule1 = AggregateRule->new(
        aggregate_rule_service_provider_id => $service_provider->id,
        aggregate_rule_formula => '(!! ('.'id'.$ac_t->id.' || '.'id'.$ac_f->id.')) && ('.'id'.$ac_t->id.' && '.'id'.$ac_t->id.')',
        aggregate_rule_state => 'enabled'
    );

    my $rule2 = AggregateRule->new(
        aggregate_rule_service_provider_id => $service_provider->id,
        aggregate_rule_formula => '(('.'id'.$ac_f->id.' || '.'id'.$ac_f->id.') || ('.'id'.$ac_f->id.' || '.'id'.$ac_t->id.')) && ! ( (! ('.'id'.$ac_f->id.' || '.'id'.$ac_t->id.')) || ! ('.'id'.$ac_t->id.' && '.'id'.$ac_t->id.'))',
        aggregate_rule_state => 'enabled'
    );

    $orchestrator->manage_aggregates();
    is($rule1->eval, 1, 'Check (!! (1 || 0)) && (1 && 1) rule');
    is($rule2->eval, 1, 'Check ((0 || 0) || (0 || 1)) && ! ( (! (0 || 1)) || ! (1 && 1)) rule');
}
