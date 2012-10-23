#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Data::Dumper;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'/tmp/capacity_management.log', layout=>'%F %L %p %m%n'});
my $log = get_logger("");


lives_ok {
    use Administrator;
    use Entity::ServiceProvider::Outside::Externalcluster;
    use Entity::Connector::MockMonitor;
    use ScomIndicator;
    use Externalnode;
    use NodemetricCombination;
    use NodemetricCondition;
    use NodemetricRule;
    use VerifiedNoderule;
    use WorkflowNoderule;

    use Clustermetric;
    use AggregateCondition;
    use AggregateCombination;
} 'All uses';

Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
my $adm = Administrator->new;
$adm->{db}->txn_begin;

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

    $indicator_deleted = ScomIndicator->find (
                            hash => {
                                service_provider_id => $service_provider->id,
                                indicator_oid => 'Memory/PercentMemoryUsed'
                            }
                        );

    $indicator_other = ScomIndicator->find (
                            hash => {
                                service_provider_id => $service_provider->id,
                                indicator_oid => 'Memory/Pool Paged Bytes'
                            }
                        );

    service_rule_objects_creation();
    node_rule_objects_creation();

    lives_ok {
       Indicator->find(hash => {indicator_oid => $indicator_deleted->indicator_oid})->delete()
    } 'Indicator Memory/PercentMemoryUsed deletion';

    dies_ok { Clustermetric->get(id => $cmd->id); } 'Check clustermetric deletion';
    dies_ok { AggregateCombination->get(id => $acombd1->id);} 'Check AggregateCombination deletion 1/2';
    dies_ok { AggregateCombination->get(id => $acombd2->id);} 'Check AggregateCombination deletion 2/2';
    dies_ok { AggregateCondition->get(id => $acd1->id);} 'Check AggregateCondition deletion 1/2';
    dies_ok { AggregateCondition->get(id => $acd2->id);} 'Check AggregateCondition deletion 2/2';
    dies_ok { AggregateRule->get(id => $rule1d->id);} 'Check AggregateRule deletion 1/3';
    dies_ok { AggregateRule->get(id => $rule2d->id);} 'Check AggregateRule deletion 2/3';
    dies_ok { AggregateRule->get(id => $rule3d->id);} 'Check AggregateRule deletion 3/3';

    dies_ok { NodemetricCombination->get(id => $ncombd1->id);} 'Check NodemetricCombination deletion 1/2';
    dies_ok { NodemetricCombination->get(id => $ncombd2->id);} 'Check NodemetricCombination deletion 2/2';
    dies_ok { NodemetricCondition->get(id => $ncd1->id);} 'Check NodemetricCondition deletion 1/2';
    dies_ok { NodemetricCondition->get(id => $ncd2->id);} 'Check NodemetricCondition deletion 2/2';
    dies_ok { NodemetricRule->get(id => $nrule1d->id);} 'Check NodemetricRule deletion 1/3';
    dies_ok { NodemetricRule->get(id => $nrule2d->id);} 'Check NodemetricRule deletion 2/3';
    dies_ok { NodemetricRule->get(id => $nrule3d->id);} 'Check NodemetricRule deletion 3/3';

    lives_ok {
        Clustermetric->get(id => $cm2->id);
        Clustermetric->get(id => $cm3->id);
        AggregateCombination->get(id => $acomb3->id);
        AggregateCondition->get(id => $ac3->id);
        AggregateRule->get(id => $rule4->id);
        NodemetricCombination->get(id => $ncomb3->id);
        NodemetricCondition->get(id => $nc3->id);
        NodemetricRule->get(id => $nrule4->id);
    } 'Check not deleted objects';

    $adm->{db}->txn_rollback;
};
if($@) {
    $adm->{db}->txn_rollback;
    my $error = $@;
    print $error."\n";
}

sub service_rule_objects_creation {
    lives_ok {
        $cmd = Clustermetric->new(
            clustermetric_service_provider_id => $service_provider->id,
            clustermetric_indicator_id => ($indicator_deleted->id),
            clustermetric_statistics_function_name => 'mean',
            clustermetric_window_time => '1200',
        );

        $cm2 = Clustermetric->new(
            clustermetric_service_provider_id => $service_provider->id,
            clustermetric_indicator_id => ($indicator_other->id),
            clustermetric_statistics_function_name => 'mean',
            clustermetric_window_time => '1200',
        );

        $cm3 = Clustermetric->new(
            clustermetric_service_provider_id => $service_provider->id,
            clustermetric_indicator_id => ($indicator_other->id),
            clustermetric_statistics_function_name => 'std',
            clustermetric_window_time => '1200',
        );

        $acombd1 = AggregateCombination->new(
            aggregate_combination_service_provider_id =>  $service_provider->id,
            aggregate_combination_formula => 'id'.($cmd->id).' + id'.($cm2->id),
        );

        $acombd2 = AggregateCombination->new(
            aggregate_combination_service_provider_id =>  $service_provider->id,
            aggregate_combination_formula => 'id'.($cm3->id).' - id'.($cmd->id),
        );

        $acomb3 = AggregateCombination->new(
            aggregate_combination_service_provider_id =>  $service_provider->id,
            aggregate_combination_formula => 'id'.($cm2->id).' + id'.($cm3->id),
        );

        $acd1 = AggregateCondition->new(
            aggregate_condition_service_provider_id => $service_provider->id,
            aggregate_combination_id => $acombd1->id,
            comparator => '>',
            threshold => '0',
            state => 'enabled'
        );

        $acd2 = AggregateCondition->new(
            aggregate_condition_service_provider_id => $service_provider->id,
            aggregate_combination_id => $acombd2->id,
            comparator => '<',
            threshold => '0',
            state => 'enabled'
        );

        $ac3 = AggregateCondition->new(
            aggregate_condition_service_provider_id => $service_provider->id,
            aggregate_combination_id => $acomb3->id,
            comparator => '<',
            threshold => '0',
            state => 'enabled'
        );

        $rule1d = AggregateRule->new(
            aggregate_rule_service_provider_id => $service_provider->id,
            aggregate_rule_formula => 'id'.$acd1->id.' && id'.$acd2->id,
            aggregate_rule_state => 'enabled'
        );

        $rule2d = AggregateRule->new(
            aggregate_rule_service_provider_id => $service_provider->id,
            aggregate_rule_formula => 'id'.$ac3->id.' || id'.$acd2->id,
            aggregate_rule_state => 'enabled'
        );

        $rule3d = AggregateRule->new(
            aggregate_rule_service_provider_id => $service_provider->id,
            aggregate_rule_formula => 'id'.$acd2->id.' && id'.$ac3->id,
            aggregate_rule_state => 'enabled'
        );

        $rule4 = AggregateRule->new(
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
        $ncombd1 = NodemetricCombination->new(
            nodemetric_combination_service_provider_id => $service_provider->id,
            nodemetric_combination_formula             => 'id'.($indicator_deleted->id).' + id'.($indicator_other->id),
        );

        $ncombd2 = NodemetricCombination->new(
            nodemetric_combination_service_provider_id => $service_provider->id,
            nodemetric_combination_formula             => 'id'.($indicator_other->id).' + id'.($indicator_deleted->id),
        );

        $ncomb3 = NodemetricCombination->new(
            nodemetric_combination_service_provider_id => $service_provider->id,
            nodemetric_combination_formula             => 'id'.($indicator_other->id).' + id'.($indicator_other->id),
        );

        $ncd1 = NodemetricCondition->new(
            nodemetric_condition_service_provider_id => $service_provider->id,
            nodemetric_condition_combination_id => $ncombd1->id,
            nodemetric_condition_comparator => '>',
            nodemetric_condition_threshold => '0',
        );

        $ncd2 = NodemetricCondition->new(
            nodemetric_condition_service_provider_id => $service_provider->id,
            nodemetric_condition_combination_id => $ncombd2->id,
            nodemetric_condition_comparator => '<',
            nodemetric_condition_threshold => '0',
        );

        $nc3 = NodemetricCondition->new(
            nodemetric_condition_service_provider_id => $service_provider->id,
            nodemetric_condition_combination_id => $ncomb3->id,
            nodemetric_condition_comparator => '<',
            nodemetric_condition_threshold => '0',
        );

        $nrule1d = NodemetricRule->new(
            nodemetric_rule_service_provider_id => $service_provider->id,
            nodemetric_rule_formula => 'id'.$ncd1->id.' && id'.$ncd2->id,
            nodemetric_rule_state => 'enabled'
        );

        $nrule2d = NodemetricRule->new(
            nodemetric_rule_service_provider_id => $service_provider->id,
            nodemetric_rule_formula => 'id'.$ncd1->id.' || id'.$nc3->id,
            nodemetric_rule_state => 'enabled'
        );

        $nrule3d = NodemetricRule->new(
            nodemetric_rule_service_provider_id => $service_provider->id,
            nodemetric_rule_formula => 'id'.$nc3->id.' || id'.$ncd2->id,
            nodemetric_rule_state => 'enabled'
        );

        $nrule4 = NodemetricRule->new(
            nodemetric_rule_service_provider_id => $service_provider->id,
            nodemetric_rule_formula => 'id'.$nc3->id.' || id'.$nc3->id,
            nodemetric_rule_state => 'enabled'
        );
    } 'Create node rules objects';
}