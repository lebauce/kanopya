#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Data::Dumper;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'/tmp/delete_rule.log', layout=>'%F %L %p %m%n'});
my $log = get_logger("");


lives_ok {
    use Administrator;
    use Entity::ServiceProvider::Outside::Externalcluster;
    use Entity::Connector::MockMonitor;
    use Entity::Indicator;
    use Entity::CollectorIndicator;
    use Externalnode;
    use Entity::Combination::NodemetricCombination;
    use Entity::NodemetricCondition;
    use Entity::NodemetricRule;
    use VerifiedNoderule;
    use WorkflowNoderule;
    use Entity::Clustermetric;
    use Entity::AggregateCondition;
    use Entity::Combination::AggregateCombination;
} 'All uses';

Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
my $adm = Administrator->new;
$adm->beginTransaction;

my $indicator_deleted;
my $indicator_other;
my $service_provider;

my $cmd;
my $cm2;
my $cm3;
my $ac3;
my $acd2;
my $acd1;
my $acombd1;
my $acombd2;
my $acomb3;
my $rule1d;
my $rule2d;
my $rule3d;
my $rule4;
my $ncombd1;
my $ncombd2;
my $ncomb3;
my $ncd1;
my $ncd2;
my $ncd3;
my $nc3;
my $nrule1d;
my $nrule2d;
my $nrule3d;
my $nrule4;

eval{

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
            manager_id   => $mock_monitor->id,
            manager_type => 'collector_manager',
        );
    } 'Add mock monitor to service provider';

    # Create one node
    my $node = Externalnode->new(
        externalnode_hostname => 'test_node',
        service_provider_id   => $service_provider->id,
        externalnode_state    => 'up',
    );

    $indicator_deleted = Entity::CollectorIndicator->find (
                            hash => {
                                collector_manager_id        => $mock_monitor->id,
                                'indicator.indicator_oid'   => 'Memory/PercentMemoryUsed'
                            }
                        );

    $indicator_other = Entity::CollectorIndicator->find (
                            hash => {
                                collector_manager_id        => $mock_monitor->id,
                                'indicator.indicator_oid'   => 'Memory/Pool Paged Bytes'
                            }
                        );

    service_rule_objects_creation();
    node_rule_objects_creation();



    lives_ok {
        Entity::Indicator->find(hash => {indicator_oid => $indicator_deleted->indicator->indicator_oid})->delete()
    } 'Indicator Memory/PercentMemoryUsed deletion';

    dies_ok { Entity::Clustermetric->get(id => $cmd->id); } 'Check clustermetric deletion';
    dies_ok { Entity::Combination::AggregateCombination->get(id => $acombd1->id);} 'Check AggregateCombination deletion 1/2';
    dies_ok { Entity::Combination::AggregateCombination->get(id => $acombd2->id);} 'Check AggregateCombination deletion 2/2';
    dies_ok { Entity::AggregateCondition->get(id => $acd1->id);} 'Check AggregateCondition deletion 1/2';
    dies_ok { Entity::AggregateCondition->get(id => $acd2->id);} 'Check AggregateCondition deletion 2/2';
    dies_ok { Entity::AggregateRule->get(id => $rule1d->id);} 'Check AggregateRule deletion 1/3';
    dies_ok { Entity::AggregateRule->get(id => $rule2d->id);} 'Check AggregateRule deletion 2/3';
    dies_ok { Entity::AggregateRule->get(id => $rule3d->id);} 'Check AggregateRule deletion 3/3';
    dies_ok { Entity::Combination->get(id => $ncombd1->id);} 'Check NodemetricCombination deletion 1/2';
    dies_ok { Entity::Combination->get(id => $ncombd2->id);} 'Check NodemetricCombination deletion 2/2';
    dies_ok { Entity::NodemetricCondition->get(id => $ncd1->id);} 'Check NodemetricCondition deletion comb right';
    dies_ok { Entity::NodemetricCondition->get(id => $ncd2->id);} 'Check NodemetricCondition deletion comb left';
    lives_ok {$ncd1->left_combination_id; $ncd1->right_combination_id;} 'Check left and right combination existance';
    dies_ok { Entity::Combination->get(id => $ncd1->left_combination_id);} 'Check left combination deletion a';
    dies_ok { Entity::Combination->get(id => $ncd1->right_combination_id);} 'Check right combination deletion a';
    lives_ok {$ncd2->left_combination_id; $ncd2->right_combination_id;}'Check left and right combination existance';
    dies_ok { Entity::Combination->get(id => $ncd2->left_combination_id);}'Check left combination deletion b';
    dies_ok { Entity::Combination->get(id => $ncd2->right_combination_id);} 'Check right combination deletion b';
    dies_ok { Entity::NodemetricRule->get(id => $nrule1d->id);} 'Check NodemetricRule deletion 1/3';
    dies_ok { Entity::NodemetricRule->get(id => $nrule2d->id);} 'Check NodemetricRule deletion 2/3';
    dies_ok { Entity::NodemetricRule->get(id => $nrule3d->id);} 'Check NodemetricRule deletion 3/3';

    lives_ok {
        Entity::Clustermetric->get(id => $cm2->id);
        Entity::Clustermetric->get(id => $cm3->id);
        Entity::Combination->get(id => $acomb3->id);
        Entity::AggregateCondition->get(id => $ac3->id);
        Entity::AggregateRule->get(id => $rule4->id);
        Entity::Combination->get(id => $ncomb3->id);
        Entity::Combination->get(id => Entity::NodemetricCondition->get(id => $nc3->id)->left_combination_id);
        Entity::Combination->get(id => Entity::NodemetricCondition->get(id => $nc3->id)->right_combination_id);
        Entity::NodemetricRule->get(id => $nrule4->id);
    } 'Check not deleted objects';

    $adm->rollbackTransaction;
};
if($@) {
    $adm->rollbackTransaction;
    my $error = $@;
    print $error."\n";
}

sub service_rule_objects_creation {
    lives_ok {
        $cmd = Entity::Clustermetric->new(
            clustermetric_service_provider_id => $service_provider->id,
            clustermetric_indicator_id => ($indicator_deleted->id),
            clustermetric_statistics_function_name => 'mean',
            clustermetric_window_time => '1200',
        );

        $cm2 = Entity::Clustermetric->new(
            clustermetric_service_provider_id => $service_provider->id,
            clustermetric_indicator_id => ($indicator_other->id),
            clustermetric_statistics_function_name => 'mean',
            clustermetric_window_time => '1200',
        );

        $cm3 = Entity::Clustermetric->new(
            clustermetric_service_provider_id => $service_provider->id,
            clustermetric_indicator_id => ($indicator_other->id),
            clustermetric_statistics_function_name => 'std',
            clustermetric_window_time => '1200',
        );

        $acombd1 = Entity::Combination::AggregateCombination->new(
            service_provider_id             =>  $service_provider->id,
            aggregate_combination_formula   => 'id'.($cmd->id).' + id'.($cm2->id),
        );

        $acombd2 = Entity::Combination::AggregateCombination->new(
            service_provider_id             =>  $service_provider->id,
            aggregate_combination_formula   => 'id'.($cm3->id).' - id'.($cmd->id),
        );

        $acomb3 = Entity::Combination::AggregateCombination->new(
            service_provider_id             =>  $service_provider->id,
            aggregate_combination_formula   => 'id'.($cm2->id).' + id'.($cm3->id),
        );

        $acd1 = Entity::AggregateCondition->new(
            aggregate_condition_service_provider_id => $service_provider->id,
            left_combination_id => $acombd1->id,
            comparator => '>',
            threshold => '0',
            state => 'enabled'
        );

        $acd2 = Entity::AggregateCondition->new(
            aggregate_condition_service_provider_id => $service_provider->id,
            left_combination_id => $acombd2->id,
            comparator => '<',
            threshold => '0',
            state => 'enabled'
        );

        $ac3 = Entity::AggregateCondition->new(
            aggregate_condition_service_provider_id => $service_provider->id,
            left_combination_id => $acomb3->id,
            comparator => '<',
            threshold => '0',
            state => 'enabled'
        );

        $rule1d = Entity::AggregateRule->new(
            aggregate_rule_service_provider_id => $service_provider->id,
            aggregate_rule_formula => 'id'.$acd1->id.' && id'.$acd2->id,
            aggregate_rule_state => 'enabled'
        );

        $rule2d = Entity::AggregateRule->new(
            aggregate_rule_service_provider_id => $service_provider->id,
            aggregate_rule_formula => 'id'.$ac3->id.' || id'.$acd2->id,
            aggregate_rule_state => 'enabled'
        );

        $rule3d = Entity::AggregateRule->new(
            aggregate_rule_service_provider_id => $service_provider->id,
            aggregate_rule_formula => 'id'.$acd2->id.' && id'.$ac3->id,
            aggregate_rule_state => 'enabled'
        );

        $rule4 = Entity::AggregateRule->new(
            aggregate_rule_service_provider_id => $service_provider->id,
            aggregate_rule_formula => 'id'.$ac3->id.' || id'.$ac3->id,
            aggregate_rule_state => 'enabled'
        );
    } 'Create aggregate rules objects';
}



sub node_rule_objects_creation {
    my $rule1;
    my $rule2;

    lives_ok {

        # Create nodemetric rule objects
        $ncombd1 = Entity::Combination::NodemetricCombination->new(
            service_provider_id             => $service_provider->id,
            nodemetric_combination_formula  => 'id'.($indicator_deleted->id).' + id'.($indicator_other->id),
        );

        $ncombd2 = Entity::Combination::NodemetricCombination->new(
            service_provider_id             => $service_provider->id,
            nodemetric_combination_formula  => 'id'.($indicator_other->id).' + id'.($indicator_deleted->id),
        );

        $ncomb3 = Entity::Combination::NodemetricCombination->new(
            service_provider_id             => $service_provider->id,
            nodemetric_combination_formula  => 'id'.($indicator_other->id).' + id'.($indicator_other->id),
        );

        $ncd1 = Entity::NodemetricCondition->new(
            nodemetric_condition_service_provider_id => $service_provider->id,
            left_combination_id => $ncombd1->id,
            nodemetric_condition_comparator => '>',
            nodemetric_condition_threshold => '0',
        );

        $ncd2 = Entity::NodemetricCondition->new(
            nodemetric_condition_service_provider_id => $service_provider->id,
            left_combination_id => $ncombd2->id,
            nodemetric_condition_comparator => '<',
            nodemetric_condition_threshold => '0',
        );

        $nc3 = Entity::NodemetricCondition->new(
            nodemetric_condition_service_provider_id => $service_provider->id,
            left_combination_id => $ncomb3->id,
            nodemetric_condition_comparator => '>',
            nodemetric_condition_threshold => '0',
        );

        $nrule1d = Entity::NodemetricRule->new(
            nodemetric_rule_service_provider_id => $service_provider->id,
            nodemetric_rule_formula => 'id'.$ncd1->id.' && id'.$ncd2->id,
            nodemetric_rule_state => 'enabled'
        );

        $nrule2d = Entity::NodemetricRule->new(
            nodemetric_rule_service_provider_id => $service_provider->id,
            nodemetric_rule_formula => 'id'.$ncd1->id.' || id'.$nc3->id,
            nodemetric_rule_state => 'enabled'
        );

        $nrule3d = Entity::NodemetricRule->new(
            nodemetric_rule_service_provider_id => $service_provider->id,
            nodemetric_rule_formula => 'id'.$nc3->id.' || id'.$ncd2->id,
            nodemetric_rule_state => 'enabled'
        );

        $nrule4 = Entity::NodemetricRule->new(
            nodemetric_rule_service_provider_id => $service_provider->id,
            nodemetric_rule_formula => 'id'.$nc3->id.' || id'.$nc3->id,
            nodemetric_rule_state => 'enabled'
        );
    } 'Create node rules objects';
}

