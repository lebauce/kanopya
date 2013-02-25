#!/usr/bin/perl

############################################################################
# Test clone and import of rules (node/cluster) and all associated objects #
#   - node/aggregate rule                                                  #
#   - node/aggregate condition                                             #
#   - node combination                                                     #
#   - cluster metric                                                       #
############################################################################

use strict;
use warnings;
use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Data::Dumper;

my ($sp_src, $sp_dest);
my $indic;
my ($ncomb, $ncond, $nr);
my ($cm, $acomb, $acond, $ar);

lives_ok {
    use BaseDB;
    use Entity::ServiceProvider::Externalcluster;
    use Entity::Component::MockMonitor;
    use Entity::Clustermetric;
    use Entity::AggregateCondition;
    use Entity::Combination::AggregateCombination;
    use Entity::Rule::AggregateRule;
    use Entity::Combination::NodemetricCombination;
    use Entity::NodemetricCondition;
    use Entity::Rule::NodemetricRule;
} 'All uses';

BaseDB->authenticate( login =>'admin', password => 'K4n0pY4' );

BaseDB->beginTransaction;

eval {
    init();
    testExceptions();
    testNodeRuleImport();
    testServiceRuleImport();

    # TODO
    # test cloneFormula() with complex formula
    # test rule associated workflow cloning
    # test all condition type cloning (different left and right cobination type)
    # test cloning of already existing object

    BaseDB->rollbackTransaction;
};
if($@) {
    BaseDB->rollbackTransaction;
    my $error = $@;
    print $error."\n";
    fail('Exception occurs');
}

# Test import of node rule and all associated object
sub testNodeRuleImport {
    diag('Clone and import node rule and related');

    lives_ok {
        # 'overloaded' new will do a clone
        Entity::Rule::NodemetricRule->new(
            nodemetric_rule_id   => $nr->id,
            service_provider_id  => $sp_dest->id
        );
    } 'Import node rule';

    my ($cloned_ncomb, $cloned_ncond);

    lives_ok {
        $cloned_ncomb = Entity::Combination::NodemetricCombination->find(
            hash => {
                service_provider_id             => $sp_dest->id,
                nodemetric_combination_label    => 'node combi label',
                nodemetric_combination_formula  => 'id'.($indic->id),
            }
        );
    } 'Node combination cloned';

    lives_ok {
        $cloned_ncond = Entity::NodemetricCondition->find(
            hash => {
                nodemetric_condition_service_provider_id    => $sp_dest->id,
                nodemetric_condition_label                  => 'node cond label',
                left_combination_id                         => $cloned_ncomb->id,
                nodemetric_condition_comparator             => '>',
            }
        );
    } 'Node condition cloned';

    lives_ok {
        Entity::Combination::ConstantCombination->find(
            hash => {
                service_provider_id     => $sp_dest->id,
                constant_combination_id => $cloned_ncond->right_combination_id,
                value                   => '-1.2',
            }
        );
    } 'Constant combination cloned';

    lives_ok {
        Entity::Rule::NodemetricRule->find(
            hash => {
                service_provider_id => $sp_dest->id,
                label               => 'node rule label',
                formula             => 'id'.$cloned_ncond->id,
                state               => 'enabled',
                description         => 'node rule description',
            }
        );
    } 'Node rule cloned';
}

# Test import of service rule and all associated object
sub testServiceRuleImport {
    diag('Clone and import service rule and related');

    lives_ok {
        # 'overloaded' new will do a clone
        Entity::Rule::AggregateRule->new(
            aggregate_rule_id   => $ar->id,
            service_provider_id => $sp_dest->id
        );
    } 'Import service rule';

    my ($cloned_cm, $cloned_acomb, $cloned_acond, $cloned_ar);

    lives_ok {
        $cloned_cm = Entity::Clustermetric->find(
            hash => {
                clustermetric_service_provider_id       => $sp_dest->id,
                clustermetric_indicator_id              => $indic->id,
                clustermetric_statistics_function_name  => 'mean',
                clustermetric_window_time               => '1200',
            }
        );
    } 'Service metric cloned';

    lives_ok {
        $cloned_acomb = Entity::Combination::AggregateCombination->find(
            hash => {
                service_provider_id             =>  $sp_dest->id,
                aggregate_combination_label     => 'service comb label',
                aggregate_combination_formula   => 'id'.($cloned_cm->id),
            }
        );
    } 'Service combination cloned';

    lives_ok {
        $cloned_acond = Entity::AggregateCondition->find(
            hash => {
                aggregate_condition_service_provider_id => $sp_dest->id,
                aggregate_condition_label               => 'service cond label',
                left_combination_id                     => $cloned_acomb->id,
                comparator                              => '<',
            }
        );
    } 'Service condition cloned';

    lives_ok {
        Entity::Combination::ConstantCombination->find(
            hash => {
                service_provider_id     => $sp_dest->id,
                constant_combination_id => $cloned_acond->right_combination_id,
                value                   => '12.34',
            }
        );
    } 'Constant combination cloned';

    lives_ok {
        $cloned_ar = Entity::Rule::AggregateRule->find(
            hash => {
                service_provider_id  => $sp_dest->id,
                label                => 'service rule label',
                formula              => 'id'.$cloned_acond->id,
                state                => 'enabled',
                aggregate_rule_last_eval            => undef, # this attr is not cloned
                description          => 'service rule description',
            }
        );
    } 'Service rule cloned';
}

sub testExceptions {
    my $bad_sp_dest = Entity::ServiceProvider::Externalcluster->new(
        externalcluster_name => 'Bad Dest Service Provider',
    );

    throws_ok {
        # 'overloaded' new will do a clone
        Entity::Rule::NodemetricRule->new(
            nodemetric_rule_id  => $nr->id,
            service_provider_id => $bad_sp_dest->id
        );
    } 'Kanopya::Exception::Internal::NotFound',
    'Can not import ndoe rule if no collector manager on dest';

    throws_ok {
        # 'overloaded' new will do a clone
        Entity::Rule::AggregateRule->new(
            aggregate_rule_id   => $ar->id,
            service_provider_id => $bad_sp_dest->id
        );
    } 'Kanopya::Exception::Internal::NotFound',
    'Can not import service rule if no collector manager on dest';

     my $tech_service = Entity::ServiceProvider::Externalcluster->new(
        externalcluster_name => 'Test Monitor 2',
    );

    my $mock_monitor = Entity::Component::MockMonitor->new(
        service_provider_id => $tech_service->id,
    );

    $bad_sp_dest->addManager(
        manager_id      => $mock_monitor->id,
        manager_type    => 'CollectorManager',
        no_default_conf => 1,
    );

    throws_ok {
        # 'overloaded' new will do a clone
        Entity::Rule::NodemetricRule->new(
            nodemetric_rule_id  => $nr->id,
            service_provider_id => $bad_sp_dest->id
        );
    } 'Kanopya::Exception::Internal::Inconsistency',
    'Can not import node rule if dest and src services have not the same collector manager';

    throws_ok {
        # 'overloaded' new will do a clone
        Entity::Rule::AggregateRule->new(
            aggregate_rule_id   => $ar->id,
            service_provider_id => $bad_sp_dest->id
        );
    } 'Kanopya::Exception::Internal::Inconsistency',
    'Can not import service rule if dest and src services have not the same collector manager';
}

# Create and configure services
# Add metrics and rules to source service provider
sub init {
    $sp_src = Entity::ServiceProvider::Externalcluster->new(
        externalcluster_name => 'Source Service Provider',
    );

    $sp_dest = Entity::ServiceProvider::Externalcluster->new(
        externalcluster_name => 'Dest Service Provider',
    );

    my $tech_service = Entity::ServiceProvider::Externalcluster->new(
        externalcluster_name => 'Test Monitor',
    );

    my $mock_monitor = Entity::Component::MockMonitor->new(
        service_provider_id => $tech_service->id,
    );

    $sp_src->addManager(
        manager_id      => $mock_monitor->id,
        manager_type    => 'CollectorManager',
        no_default_conf => 1,
    );

    $sp_dest->addManager(
        manager_id      => $mock_monitor->id,
        manager_type    => 'CollectorManager',
        no_default_conf => 1,
    );

    $indic = Entity::CollectorIndicator->find (
        hash => {
            collector_manager_id        => $mock_monitor->id,
            'indicator.indicator_oid'   => 'Memory/PercentMemoryUsed'
        }
    );

    #  Nodemetric combination
    $ncomb = Entity::Combination::NodemetricCombination->new(
        service_provider_id             => $sp_src->id,
        nodemetric_combination_label    => 'node combi label',
        nodemetric_combination_formula  => 'id'.($indic->id),
    );

    # Nodemetric condition
   $ncond = Entity::NodemetricCondition->new(
        nodemetric_condition_service_provider_id    => $sp_src->id,
        nodemetric_condition_label                  => 'node cond label',
        left_combination_id                         => $ncomb->id,
        nodemetric_condition_comparator             => '>',
        nodemetric_condition_threshold              => '-1.2',
    );

    # Nodemetric rule
   $nr = Entity::Rule::NodemetricRule->new(
        service_provider_id => $sp_src->id,
        label               => 'node rule label',
        formula             => 'id'.$ncond->id,
        state               => 'enabled',
        description         => 'node rule description',
    );

    # Clustermetric
    $cm = Entity::Clustermetric->new(
        clustermetric_service_provider_id       => $sp_src->id,
        clustermetric_indicator_id              => $indic->id,
        clustermetric_statistics_function_name  => 'mean',
        clustermetric_window_time               => '1200',
    );

    # Aggregate Combination
    $acomb = Entity::Combination::AggregateCombination->new(
        service_provider_id             =>  $sp_src->id,
        aggregate_combination_label     => 'service comb label',
        aggregate_combination_formula   => 'id'.($cm->id),
    );

    # Aggregate Condition
    $acond = Entity::AggregateCondition->new(
        aggregate_condition_service_provider_id => $sp_src->id,
        aggregate_condition_label               => 'service cond label',
        left_combination_id                     => $acomb->id,
        comparator                              => '<',
        threshold                               => '12.34',
    );

    # Aggregate rule
   $ar = Entity::Rule::AggregateRule->new(
        service_provider_id  => $sp_src->id,
        label                => 'service rule label',
        formula              => 'id'.$acond->id,
        state                => 'enabled',
        aggregate_rule_last_eval            => '1',
        description          => 'service rule description',
    );
}

