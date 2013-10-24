#!/usr/bin/perl

use strict;
use warnings;
use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Data::Dumper;
use Kanopya::Tools::TestUtils 'expectedException';

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'rule_compute.log', layout=>'%F %L %p %m%n'});
my $log = get_logger("");

    use Kanopya::Database;
    use Aggregator;
    use RulesEngine;
    use Entity::ServiceProvider::Externalcluster;
    use Entity::Component::MockMonitor;
    use Entity::Clustermetric;
    use Entity::AggregateCondition;
    use Entity::Combination::AggregateCombination;
    use Entity::Rule::AggregateRule;
    use Entity::Combination::NodemetricCombination;
    use Entity::NodemetricCondition;
    use Entity::Rule::NodemetricRule;
    use VerifiedNoderule;

Kanopya::Database::authenticate( login =>'admin', password => 'K4n0pY4' );

Kanopya::Database::beginTransaction;

my ($indic1,$indic2);
my ($ac_f, $ac_t);
my ($ac_left, $ac_right, $ac_both);
my ($nc_f, $nc_t);
my ($node,$node2);
my $service_provider;
my $aggregator;
my $rulesengine;

eval{

    $aggregator   = Aggregator->new();
    $rulesengine  = RulesEngine->new();
    $rulesengine->_component->time_step(2);
    $rulesengine  = RulesEngine->new();

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

    # Create node
    $node = Node->new(
        node_hostname => 'node_1',
        service_provider_id   => $service_provider->id,
        monitoring_state    => 'up',
    );

    # Create node
    $node2 = Node->new(
        node_hostname => 'node_2',
        service_provider_id   => $service_provider->id,
        monitoring_state    => 'up',
    );

    # Get indicators
    $indic1 = Entity::CollectorIndicator->find (
        hash => {
            collector_manager_id        => $mock_monitor->id,
            'indicator.indicator_oid'   => 'Memory/PercentMemoryUsed'
        }
    );

    $indic2 = Entity::CollectorIndicator->find (
        hash => {
            collector_manager_id        => $mock_monitor->id,
            'indicator.indicator_oid'   => 'Memory/Pool Paged Bytes'
        }
    );



    test_aggregate_condition_update();
    test_nodemetric_condition_update();
    test_aggregate_combination();
    test_aggregate_rules_undef();
    test_aggregate_rules();
    test_two_combinations_on_nodemetric_condition();
    test_aggregate_combination_on_nodemetric_condition();
    test_nodemetric_condition();
    test_nodemetric_rules();
    test_rrd_remove();
    Kanopya::Database::rollbackTransaction;
    # Kanopya::Database::commitTransaction();
};
if($@) {
    my $error = $@;
    print $error."\n";
    Kanopya::Database::rollbackTransaction;
}

sub test_rrd_remove {
    lives_ok {
        my @cms = Entity::Clustermetric->search (hash => {
            clustermetric_service_provider_id => $service_provider->id
        });

        my @cm_ids = map {$_->id} @cms;
        while (@cms) { (pop @cms)->delete(); };

        my @acs = Entity::Combination::AggregateCombination->search (hash => {
            service_provider_id => $service_provider->id
        });

        if (! (scalar @acs) == 0) {
            die ''.(scalar @acs).' aggregate combinations have not been deleted';
        }

        my @ars = Entity::Rule::AggregateRule->search (hash => {
            service_provider_id => $service_provider->id
        });

        if (! scalar @acs == 0) {
            die ''.(scalar @acs).' aggregate rules have not been deleted';
        }

        my $one_rrd_remove = 0;
        for my $cm_id (@cm_ids) {
            if (defined open(FILE,'/var/cache/kanopya/monitor/timeDB_'.$cm_id.'.rrd')) {
                $one_rrd_remove++;
            }
            close(FILE);
        }
        if (! $one_rrd_remove == 0) {
            die $one_rrd_remove." rrd bases have not been removed";
        }
    } 'Delete rules';
}
sub test_nodemetric_condition {
    lives_ok {
        # Clustermetric
        my $cm = Entity::Clustermetric->new(
            clustermetric_service_provider_id => $service_provider->id,
            clustermetric_indicator_id => ($indic1->id),
            clustermetric_statistics_function_name => 'mean',
            clustermetric_window_time => '1200',
        );

        #  Nodemetric combination
        my $ncomb = Entity::Combination::NodemetricCombination->new(
            service_provider_id             => $service_provider->id,
            nodemetric_combination_formula  => 'id'.($indic1->id),
        );

        # Aggregate Combination
        my $comb = Entity::Combination::AggregateCombination->new(
            service_provider_id             =>  $service_provider->id,
            aggregate_combination_formula   => 'id'.($cm->id),
        );

        my $nc_agg_th_right = Entity::NodemetricCondition->new(
            nodemetric_condition_service_provider_id => $service_provider->id,
            left_combination_id             => $comb->id,
            nodemetric_condition_comparator => '>',
            nodemetric_condition_threshold  => '-1.2',
        );

        my $nc_agg_th_left = Entity::NodemetricCondition->new(
            nodemetric_condition_service_provider_id => $service_provider->id,
            nodemetric_condition_threshold  => '-1.4',
            nodemetric_condition_comparator => '<',
            right_combination_id            => $comb->id,
        );

        my $nc_mix_1 = Entity::NodemetricCondition->new(
            nodemetric_condition_service_provider_id => $service_provider->id,
            left_combination_id             => $ncomb->id,
            nodemetric_condition_comparator => '<',
            right_combination_id            => $comb->id,
        );

        my $nc_mix_2 = Entity::NodemetricCondition->new(
            nodemetric_condition_service_provider_id => $service_provider->id,
            left_combination_id             => $comb->id,
            nodemetric_condition_comparator => '<',
            right_combination_id            => $ncomb->id,
        );

        my $comb_th_left = Entity::Combination::ConstantCombination->get(
                               id => $nc_agg_th_right->right_combination_id
                           );

        my $comb_th_right = Entity::Combination::ConstantCombination->get(
                                id => $nc_agg_th_left->left_combination_id
                            );

        $service_provider->addManagerParameter(
            manager_type    => 'CollectorManager',
            name            => 'mockmonit_config',
            value           =>  "{'default':{'const':50},'nodes':{'node_1':{'const':1.234}, 'node_2':{'const':2.345}}}",
        );

        if (! $comb_th_left->evaluate() == -1.2){ die 'wrong left theshold value of nodemetric condition';}
        if (! $comb_th_right->evaluate() == -1.4){ die 'wrong right theshold value of nodemetric condition';}

        sleep(2);
        $aggregator->update();

        if (! $comb->evaluate() == 0.5*(1.234+2.345)) { die 'Wrong aggregate combination of nodemetric condition';}

        my $r1 = Entity::Rule::NodemetricRule->new(
            service_provider_id => $service_provider->id,
            formula => 'id'.$nc_agg_th_left->id,
            state => 'enabled'
        );

        my $r2 = Entity::Rule::NodemetricRule->new(
            service_provider_id => $service_provider->id,
            formula => 'id'.$nc_agg_th_left->id,
            state => 'enabled'
        );

        my $r3 = Entity::Rule::NodemetricRule->new(
            service_provider_id => $service_provider->id,
            formula => 'id'.$nc_mix_1->id,
            state => 'enabled',
        );

        my $r4 = Entity::Rule::NodemetricRule->new(
            service_provider_id => $service_provider->id,
            formula => 'id'.$nc_mix_2->id,
            state => 'enabled'
        );

        sleep(2);
        $aggregator->update();

        $rulesengine->oneRun();

        VerifiedNoderule->find(hash => {
            verified_noderule_node_id    => $node->id,
            verified_noderule_nodemetric_rule_id => $r1->id,
            verified_noderule_state              => 'verified',
        });

        VerifiedNoderule->find(hash => {
            verified_noderule_node_id    => $node->id,
            verified_noderule_nodemetric_rule_id => $r2->id,
            verified_noderule_state              => 'verified',
        });

        VerifiedNoderule->find(hash => {
            verified_noderule_node_id    => $node->id,
            verified_noderule_nodemetric_rule_id => $r3->id,
            verified_noderule_state              => 'verified',
        });

        expectedException {
            VerifiedNoderule->find(hash => {
                verified_noderule_node_id    => $node2->id,
                verified_noderule_nodemetric_rule_id => $r3->id,
            })
        } 'Kanopya::Exception::Internal::NotFound', 'wrong mixed nodemetric rule node 2';

        expectedException {
            VerifiedNoderule->find(hash => {
                verified_noderule_node_id    => $node->id,
                verified_noderule_nodemetric_rule_id => $r4->id,
            })
        } 'Kanopya::Exception::Internal::NotFound', 'wrong mixed nodemetric rule node 1';

        VerifiedNoderule->find(hash => {
            verified_noderule_node_id    => $node2->id,
            verified_noderule_nodemetric_rule_id => $r4->id,
            verified_noderule_state              => 'verified',
        });

        if (! $nc_agg_th_right->toString() eq 'mean(RAM used) > -1.2'){ die 'Wrong nodemetric condition toString()';}
        if (! $nc_agg_th_left->toString() eq '-1.4 < mean(RAM used)'){ die 'Wrong nodemetric condition toString()';}
        if (! $nc_mix_1->toString() eq 'RAM used < mean(RAM used)'){ die 'Wrong nodemetric condition toString()';}
        if (! $nc_mix_2->toString() eq 'mean(RAM used) < RAM used'){ die 'Wrong nodemetric condition toString()';}

        $cm->update(clustermetric_statistics_function_name => 'min');
        $ncomb->update(nodemetric_combination_formula  => '2*id'.($indic1->id));
        $comb->update(aggregate_combination_formula   => '3*id'.($cm->id));
        $nc_agg_th_left->update(nodemetric_condition_comparator => '==');

        if (! Entity->get(id => $nc_agg_th_left->id)->toString() eq '-1.4 == 3*min(RAM used)') {
            die 'Check update nodemetric String'
        }

        expectedException {
            $nc_agg_th_right->update(left_combination_id => $ncomb->id);
        } 'Kanopya::Exception::Internal::WrongValue', 'not only one left combination update';
        expectedException {
            $nc_agg_th_right->update(right_combination_id => $ncomb->id);
        } 'Kanopya::Exception::Internal::WrongValue', 'not only one right combination update';
        expectedException {
            $nc_agg_th_right->update(nodemetric_condition_threshold => $ncomb->id);
        } 'Kanopya::Exception::Internal::WrongValue', 'not only threshold update';

        if (! Entity->get(id => $nc_agg_th_right->id)->nodemetric_condition_formula_string eq '3*min(RAM used) > -1.2') {
            die 'Wrong update nodemetric condition formula string';
        }
        if (! Entity->get(id => $nc_mix_1->id)->toString() eq '2*RAM used < 3*min(RAM used)') {
            die 'Wrong update nodemetric condition formula string';
        }
        if (! Entity->get(id => $nc_mix_2->id)->toString() eq '3*min(RAM used) < 2*RAM used') {
            die 'Wrong update nodemetric condition formula string';
        }

        my $old_const_id = $nc_agg_th_left->left_combination_id;

        $nc_agg_th_left->update(
            left_combination_id => $comb->id,
            right_combination_id => $ncomb->id,
        );

        if (! Entity->get(id => $nc_agg_th_left->id)->toString() eq '3*min(RAM used) == 2*RAM used') {
            die 'Wrong update nodemetric String';
        }

        expectedException {
            Entity->get(id => $old_const_id)
        } 'Kanopya::Exception::Internal::NotFound', 'Old constant comb has been removed';

        $nc_agg_th_left->update(
            left_combination_id => $ncomb->id,
            nodemetric_condition_threshold => 21.01,
        );

        if (! Entity->get(id => $nc_agg_th_left->id)->toString() eq '2*RAM used == 21.01') {
            die 'Wrong update nodemetric String';
        }

        $old_const_id = $nc_agg_th_left->right_combination_id;
        $nc_agg_th_left->update(
            left_combination_id => $ncomb->id,
            nodemetric_condition_threshold => 19.83,
        );
        if (! Entity->get(id => $nc_agg_th_left->id)->toString() eq '2*RAM used == 19.83'){
            die 'Wrong update nodemetric String';
        }
        expectedException {
            Entity->get(id => $old_const_id)
        } 'Kanopya::Exception::Internal::NotFound', 'Old constant comb has been removed';
    } 'Nodemetric condition compute';
}

sub test_two_combinations_on_nodemetric_condition {

    lives_ok {
        # Create nodemetric rule objects
        my $ncomb_left = Entity::Combination::NodemetricCombination->new(
            service_provider_id             => $service_provider->id,
            nodemetric_combination_formula  => 'id'.($indic1->id),
        );

        # Create nodemetric rule objects
        my $ncomb_right = Entity::Combination::NodemetricCombination->new(
            service_provider_id             => $service_provider->id,
            nodemetric_combination_formula  => 'id'.($indic2->id),
        );

        my $nc1 = Entity::NodemetricCondition->new(
            nodemetric_condition_service_provider_id => $service_provider->id,
            left_combination_id => $ncomb_left->id,
            right_combination_id => $ncomb_right->id,
            nodemetric_condition_comparator => '>',
        );

        my $nc2 = Entity::NodemetricCondition->new(
            nodemetric_condition_service_provider_id => $service_provider->id,
            left_combination_id => $ncomb_left->id,
            right_combination_id => $ncomb_right->id,
            nodemetric_condition_comparator => '<',
        );

        my $r1 = Entity::Rule::NodemetricRule->new(
            service_provider_id => $service_provider->id,
            formula => 'id'.$nc1->id,
            state => 'enabled'
        );

        my $r2 = Entity::Rule::NodemetricRule->new(
            service_provider_id => $service_provider->id,
            formula => 'id'.$nc2->id,
            state => 'enabled'
        );

        $service_provider->addManagerParameter(
            manager_type    => 'CollectorManager',
            name            => 'mockmonit_config',
            value           =>  "{
                                      'default':{ 'const':50 },
                                      'indics' : {
                                     'Memory/PercentMemoryUsed' : { 'const':51 },
                                     'Memory/Pool Paged Bytes' : { 'const':50 }
                                      }
                                 }",
        );

        sleep(2);
        $aggregator->update();
        $rulesengine->oneRun();


        VerifiedNoderule->find(hash => {
            verified_noderule_node_id    => $node->id,
            verified_noderule_nodemetric_rule_id => $r1->id,
            verified_noderule_state              => 'verified',
        });

        expectedException {
            VerifiedNoderule->find(hash => {
                verified_noderule_node_id    => $node->id,
                verified_noderule_nodemetric_rule_id => $r2->id,
                verified_noderule_state              => 'verified',
            })
        } 'Kanopya::Exception::Internal::NotFound', 'Wrong 2 combinations on a nodemetric condition case not verified';
    } 'Two combinations on nodemetric condition compute'
}

sub test_aggregate_combination_on_nodemetric_condition {
    lives_ok {
        # Clustermetric
        my $cm = Entity::Clustermetric->new(
            clustermetric_service_provider_id       => $service_provider->id,
            clustermetric_indicator_id              => ($indic1->id),
            clustermetric_statistics_function_name  => 'sum',
            clustermetric_window_time               => '1200',
        );

        # Combination
        my $comb = Entity::Combination::AggregateCombination->new(
            service_provider_id             =>  $service_provider->id,
            aggregate_combination_formula   => 'id'.($cm->id),
        );

        $nc_t = Entity::NodemetricCondition->new(
            nodemetric_condition_service_provider_id => $service_provider->id,
            left_combination_id             => $comb->id,
            nodemetric_condition_comparator => '>',
            nodemetric_condition_threshold  => '0',
        );

        my $r1 = Entity::Rule::NodemetricRule->new(
            service_provider_id => $service_provider->id,
            formula => 'id'.$nc_t->id,
            state => 'enabled'
        );

        sleep(2);
        $aggregator->update();
        $rulesengine->oneRun();

        VerifiedNoderule->find(hash => {
            verified_noderule_node_id            => $node->id,
            verified_noderule_nodemetric_rule_id => $r1->id,
            verified_noderule_state              => 'verified',
        });

        VerifiedNoderule->find(hash => {
            verified_noderule_node_id            => $node2->id,
            verified_noderule_nodemetric_rule_id => $r1->id,
            verified_noderule_state              => 'verified',
        });
    } 'Aggregate combination on nodemetric condition'
}

sub test_nodemetric_rules {

    lives_ok {
        # Create nodemetric rule objects
        my $ncomb = Entity::Combination::NodemetricCombination->new(
            service_provider_id             => $service_provider->id,
            nodemetric_combination_formula  => 'id'.($indic1->id),
        );

        $nc_f = Entity::NodemetricCondition->new(
            nodemetric_condition_service_provider_id => $service_provider->id,
            left_combination_id => $ncomb->id,
            nodemetric_condition_comparator => '<',
            nodemetric_condition_threshold => '0',
        );

        $nc_t = Entity::NodemetricCondition->new(
            nodemetric_condition_service_provider_id => $service_provider->id,
            left_combination_id => $ncomb->id,
            nodemetric_condition_comparator => '>',
            nodemetric_condition_threshold => '0',
        );

        $service_provider->addManagerParameter(
            manager_type    => 'CollectorManager',
            name            => 'mockmonit_config',
            value           =>  "{'default':{'const':50},'nodes':{'node_2':{'const':null}}}",
        );

        sleep(2);
        $aggregator->update();

        my $nr_f = Entity::Rule::NodemetricRule->new(
            service_provider_id => $service_provider->id,
            formula => 'id'.$nc_f->id,
            state => 'enabled'
        );

        my $nr_t = Entity::Rule::NodemetricRule->new(
            service_provider_id => $service_provider->id,
            formula => 'id'.$nc_t->id,
            state => 'enabled',
        );

        $rulesengine->oneRun();

        if (! $nr_t->isVerifiedForANode(node_id => $node->id) == 1) {
            die 'Nodemetric rule should be true';
        }
        if (! $nr_f->isVerifiedForANode(node_id => $node->id) == 0) {
            die 'Nodemetric rule should be false';
        }
        if (defined $nr_t->isVerifiedForANode(node_id => $node2->id)) {
            die 'Nodemetric rule should be undefined';
        }
        if (defined $nr_f->isVerifiedForANode(node_id => $node2->id)) {
            die 'Nodemetric rule should be undefined';
        }

        expectedException {
            VerifiedNoderule->find(hash => {
                verified_noderule_node_id               => $node->id,
                verified_noderule_nodemetric_rule_id    => $nr_f->id,
                verified_noderule_state                 => 'verified',
            })
        } 'Kanopya::Exception::Internal::NotFound', 'Nodemetric rule should be false';

        VerifiedNoderule->find(hash => {
            verified_noderule_node_id               => $node->id,
            verified_noderule_nodemetric_rule_id    => $nr_t->id,
            verified_noderule_state                 => 'verified',
        });

        VerifiedNoderule->find(hash => {
            verified_noderule_node_id               => $node2->id,
            verified_noderule_nodemetric_rule_id    => $nr_t->id,
            verified_noderule_state                 => 'undef',
        });


        VerifiedNoderule->find(hash => {
            verified_noderule_node_id               => $node2->id,
            verified_noderule_nodemetric_rule_id    => $nr_t->id,
            verified_noderule_state                 => 'undef',
        });

        test_not_n();
        test_or_n();
        test_and_n();
        test_big_formulas_n();
    } 'Nodemetric rules evaluation'
}

sub test_aggregate_rules_undef {

    lives_ok {
        my $cm = Entity::Clustermetric->new(
            clustermetric_service_provider_id => $service_provider->id,
            clustermetric_indicator_id => ($indic1->id),
            clustermetric_statistics_function_name => 'sum',
            clustermetric_window_time => '1200',
        );

        my $comb = Entity::Combination::AggregateCombination->new(
            service_provider_id             =>  $service_provider->id,
            aggregate_combination_formula   => 'id'.($cm->id),
        );

        my $ac = Entity::AggregateCondition->new(
            aggregate_condition_service_provider_id => $service_provider->id,
            left_combination_id => $comb->id,
            comparator => '>',
            threshold => '0',
        );

        my $rule = Entity::Rule::AggregateRule->new(
            service_provider_id => $service_provider->id,
            formula => 'id'.$ac->id,
            state => 'enabled'
        );

        sleep(2);
        $aggregator->update();
        $rulesengine->oneRun();

        if (! defined $comb->evaluate()) {die 'Clustermetric undefined';}
        if (! $ac->evaluate() == 1) { die 'Condition not true'}
        if (! Entity->get(id=>$ac->id)->last_eval == 1) {die 'Condition last_eval parameter updated';}
        if (! Entity->get(id=>$rule->id)->aggregate_rule_last_eval == 1) { die 'Rule last eval is not true';}

        $service_provider->addManagerParameter(
            manager_type    => 'CollectorManager',
            name            => 'mockmonit_config',
            value           =>  "{'default':{'const':null}}",
        );

        sleep(2);
        $aggregator->update();
        $rulesengine->oneRun();

        if (defined $comb->evaluate()) {die 'Clustermetric should be undef'};
        if (defined Entity->get(id=>$ac->id)->evaluate()) {die 'Condition evaluate should be undef'};
        if (defined Entity->get(id=>$ac->id)->last_eval) {die 'Condition last_eval should be undef'};
        if (defined Entity->get(id=>$rule->id)->aggregate_rule_last_eval) {die 'Rule last update should be undef'};

    } 'Aggregate rule undefined value management'
}

sub test_aggregate_combination {

    lives_ok {

        # Clustermetric
        my $cm = Entity::Clustermetric->new(
            clustermetric_service_provider_id => $service_provider->id,
            clustermetric_indicator_id => ($indic1->id),
            clustermetric_statistics_function_name => 'sum',
            clustermetric_window_time => '1200',
        );

        # Combination
        my $comb = Entity::Combination::AggregateCombination->new(
            service_provider_id             =>  $service_provider->id,
            aggregate_combination_formula   => 'id'.($cm->id),
        );

        # Combination
        my $comb2 = Entity::Combination::AggregateCombination->new(
            service_provider_id             =>  $service_provider->id,
            aggregate_combination_formula   => '2*id'.($cm->id),
        );

        # Condition
        $ac_left = Entity::AggregateCondition->new(
            aggregate_condition_service_provider_id => $service_provider->id,
            left_combination_id => $comb->id,
            comparator => '<',
            threshold => '12.34',
        );

        $ac_right = Entity::AggregateCondition->new(
            aggregate_condition_service_provider_id => $service_provider->id,
            threshold => '-43.21',
            comparator => '<',
            right_combination_id => $comb->id,
        );

        $ac_both = Entity::AggregateCondition->new(
            aggregate_condition_service_provider_id => $service_provider->id,
            left_combination_id  => $comb->id,
            comparator => '<',
            right_combination_id => $comb2->id,
        );

        my $rule = Entity::Rule::AggregateRule->new(
            service_provider_id => $service_provider->id,
            formula => 'id'.$ac_left->id.' && id'.$ac_right->id,
            state => 'enabled'
        );

        $service_provider->addManagerParameter(
            manager_type    => 'CollectorManager',
            name            => 'mockmonit_config',
            value           =>  "{'default':{'const':50},'nodes':{'node_1':{'const':1.234}, 'node_2':{'const':2.345}}}",
        );

        my $cc1 = Entity::Combination->get(id => $ac_left->right_combination_id),
        my $cc2 = Entity::Combination->get(id => $ac_right->left_combination_id),

        sleep(2);
        $aggregator->update();

        if (! $cc1->evaluate() == 12.34) { die 'wrong aggregate condition right theshold value' };
        if (! $cc2->evaluate() == -43.21) { die 'wrong aggregate condition left theshold value'};
        if (! $comb->evaluate() == 3.579) { die 'wrong aggregate condition mock monitor combination value'};
        if (! $comb2->evaluate() == 2*3.579) { die 'wrong aggregate condition mock monitor combination value'};

        if (! $ac_left->evaluate() == 1) { die 'wrong condition combi left'};
        if (! $ac_right->evaluate() == 1) { die 'wrong condition combi right'};
        if (! $ac_both->evaluate() == 1) { die 'wrong condition combi both'};

        if (! $ac_left->toString() eq 'sum(RAM used) < 12.34') {die 'wrong aggregate combination toString()'}
        if (! $ac_right->toString() eq '-43.21 < sum(RAM used)') {die 'wrong aggregate combination toString()'}
        if (! $ac_both->toString() eq 'sum(RAM used) < 2*sum(RAM used)') {die 'wrong aggregate combination toString()'}
        if (! $rule->toString() eq 'sum(RAM used) < 12.34 && -43.21 < sum(RAM used)') {die 'wrong aggregate rule toString'}


        $ac_left->update(
            aggregate_condition_service_provider_id => $service_provider->id,
            left_combination_id => $comb->id,
            comparator => '<',
            threshold => '99.99',
        );

        $cm->update(clustermetric_statistics_function_name => 'min');
        $comb->update(aggregate_combination_formula => '-id'.($cm->id));
        $ac_left->update(
            threshold => '21.01',
            comparator => '==',
            right_combination_id => $comb2->id,
        );

        if (! Entity->get(id => $ac_right->id)->aggregate_condition_formula_string eq '-43.21 < -min(RAM used)') {
            die 'wrong update formula string';
        }
        if (! Entity->get(id => $ac_both->id)->aggregate_condition_formula_string eq '-min(RAM used) < 2*min(RAM used)') {
            die 'wrong update formula string';
        }
        if (! Entity->get(id => $ac_left->id)->aggregate_condition_formula_string eq '21.01 == 2*min(RAM used)') {
            die 'wrong update formula string';
        }
        if (! Entity->get(id => $rule->id)->formula_string eq '21.01 == 2*min(RAM used) && -43.21 < -min(RAM used)') {
            die 'wrong update rule formula string';
        }
    } 'Aggregate condition computing';
}

sub test_aggregate_rules {
    my %args = @_;
    lives_ok {
        # Clustermetric
        my $cm = Entity::Clustermetric->new(
            clustermetric_service_provider_id => $service_provider->id,
            clustermetric_indicator_id => ($indic1->id),
            clustermetric_statistics_function_name => 'sum',
            clustermetric_window_time => '1200',
        );

        # Combination
        my $comb = Entity::Combination::AggregateCombination->new(
            service_provider_id             =>  $service_provider->id,
            aggregate_combination_formula   => 'id'.($cm->id),
        );

        # Condition
        $ac_t = Entity::AggregateCondition->new(
            aggregate_condition_service_provider_id => $service_provider->id,
            left_combination_id => $comb->id,
            comparator => '>',
            threshold => '0',
        );

        $ac_f = Entity::AggregateCondition->new(
            aggregate_condition_service_provider_id => $service_provider->id,
            right_combination_id => $comb->id,
            comparator => '>',
            threshold => '0',
        );

        # No node responds
        $service_provider->addManagerParameter(
            manager_type    => 'CollectorManager',
            name            => 'mockmonit_config',
            value           =>  "{'default':{'const':50},'nodes':{'node_2':{'const':null}}}",
        );

        sleep(2);
        $aggregator->update();

        if (! $ac_t->evaluate() == 1) {die 'Condition shoud be true';}
        if (! $ac_f->evaluate() == 0) {die 'Condition shoud be false';}

        test_not();
        test_or();
        test_and();
        test_big_formulas();
    } 'Aggregate rules evaluation'
}

sub test_and_n {

    my $r1 = Entity::Rule::NodemetricRule->new(
        service_provider_id => $service_provider->id,
        formula => 'id'.$nc_f->id.' && '.'id'.$nc_f->id,
        state => 'enabled'
    );

    my $r2 = Entity::Rule::NodemetricRule->new(
        service_provider_id => $service_provider->id,
        formula => 'id'.$nc_f->id.' && '.'id'.$nc_t->id,
        state => 'enabled'
    );

    my $r3 = Entity::Rule::NodemetricRule->new(
        service_provider_id => $service_provider->id,
        formula => 'id'.$nc_t->id.' && '.'id'.$nc_f->id,
        state => 'enabled',
    );

    my $r4 = Entity::Rule::NodemetricRule->new(
        service_provider_id => $service_provider->id,
        formula => 'id'.$nc_t->id.' && '.'id'.$nc_t->id,
        state => 'enabled'
    );

    $rulesengine->oneRun();

    expectedException {
        VerifiedNoderule->find(hash => {
            verified_noderule_node_id    => $node->id,
            verified_noderule_nodemetric_rule_id => $r1->id,
            verified_noderule_state              => 'verified',
        })
    } 'Kanopya::Exception::Internal::NotFound', ' Nodemetric rule 0 && 0 should be false';

    expectedException {
        VerifiedNoderule->find(hash => {
            verified_noderule_node_id    => $node->id,
            verified_noderule_nodemetric_rule_id => $r2->id,
            verified_noderule_state              => 'verified',
        })
    } 'Kanopya::Exception::Internal::NotFound', 'Nodemetric rule 0 && 1 should be false';

    expectedException {
        VerifiedNoderule->find(hash => {
            verified_noderule_node_id    => $node->id,
            verified_noderule_nodemetric_rule_id => $r3->id,
            verified_noderule_state              => 'verified',
        })
    } 'Kanopya::Exception::Internal::NotFound', ' Nodemetric rule 1 && 0 should be false';


    VerifiedNoderule->find(hash => {
        verified_noderule_node_id    => $node->id,
        verified_noderule_nodemetric_rule_id => $r4->id,
        verified_noderule_state              => 'verified',
    })

}

sub test_and {
    my $rule1 = Entity::Rule::AggregateRule->new(
        service_provider_id => $service_provider->id,
        formula => 'id'.$ac_t->id.' && id'.$ac_t->id,
        state => 'enabled'
    );

    my $rule2 = Entity::Rule::AggregateRule->new(
        service_provider_id => $service_provider->id,
        formula => 'id'.$ac_t->id.' && id'.$ac_f->id,
        state => 'enabled'
    );

    my $rule3 = Entity::Rule::AggregateRule->new(
        service_provider_id => $service_provider->id,
        formula => 'id'.$ac_f->id.' && id'.$ac_t->id,
        state => 'enabled'
    );

    my $rule4 = Entity::Rule::AggregateRule->new(
        service_provider_id => $service_provider->id,
        formula => 'id'.$ac_f->id.' && id'.$ac_f->id,
        state => 'enabled'
    );

    $rulesengine->oneRun();

    if (! (values %{$rule1->evaluate()})[0] == 1){ die ' 1 && 1 rule should be true'};
    if (! (values %{$rule2->evaluate()})[0] == 0){ die ' 1 && 0 rule should be false'};
    if (! (values %{$rule3->evaluate()})[0] == 0){ die ' 0 && 1 rule should be false'};
    if (! (values %{$rule4->evaluate()})[0] == 0){ die ' 0 && 0 rule should be false'};

    if (! $rule1->formula_string eq 'sum(RAM used) > 0 && sum(RAM used) > 0') {die 'Wrong formula string aggregate rule before update'};
    $rule1->update (formula => 'id'.$ac_t->id.' && ! id'.$ac_t->id);
    if (! $rule1->formula_string eq 'sum(RAM used) > 0 && ! sum(RAM used) > 0') {die 'Wrong formula string aggregate rule after update'};
}

sub test_or_n {

    my $r1 = Entity::Rule::NodemetricRule->new(
        service_provider_id => $service_provider->id,
        formula => 'id'.$nc_f->id.' || '.'id'.$nc_f->id,
        state => 'enabled'
    );

    my $r2 = Entity::Rule::NodemetricRule->new(
        service_provider_id => $service_provider->id,
        formula => 'id'.$nc_f->id.' || '.'id'.$nc_t->id,
        state => 'enabled'
    );

    my $r3 = Entity::Rule::NodemetricRule->new(
        service_provider_id => $service_provider->id,
        formula => 'id'.$nc_t->id.' || '.'id'.$nc_f->id,
        state => 'enabled'
    );

    my $r4 = Entity::Rule::NodemetricRule->new(
        service_provider_id => $service_provider->id,
        formula => 'id'.$nc_t->id.' || '.'id'.$nc_t->id,
        state => 'enabled'
    );

    $rulesengine->oneRun();

    expectedException {
        VerifiedNoderule->find(hash => {
            verified_noderule_node_id               => $node->id,
            verified_noderule_nodemetric_rule_id    => $r1->id,
            verified_noderule_state                 => 'verified',
        })
    } 'Kanopya::Exception::Internal::NotFound', 'Nodemetric rule 0 || 0 should be false';

    VerifiedNoderule->find(hash => {
        verified_noderule_node_id               => $node->id,
        verified_noderule_nodemetric_rule_id    => $r2->id,
        verified_noderule_state                 => 'verified',
    });

    VerifiedNoderule->find(hash => {
        verified_noderule_node_id               => $node->id,
        verified_noderule_nodemetric_rule_id    => $r3->id,
        verified_noderule_state                 => 'verified',
    });

    VerifiedNoderule->find(hash => {
        verified_noderule_node_id               => $node->id,
        verified_noderule_nodemetric_rule_id    => $r4->id,
        verified_noderule_state                 => 'verified',
    })
}

sub test_or {
    my $rule1 = Entity::Rule::AggregateRule->new(
        service_provider_id => $service_provider->id,
        formula => 'id'.$ac_t->id.' || id'.$ac_t->id,
        state => 'enabled'
    );

    my $rule2 = Entity::Rule::AggregateRule->new(
        service_provider_id => $service_provider->id,
        formula => 'id'.$ac_t->id.' || id'.$ac_f->id,
        state => 'enabled'
    );

    my $rule3 = Entity::Rule::AggregateRule->new(
        service_provider_id => $service_provider->id,
        formula => 'id'.$ac_f->id.' || id'.$ac_t->id,
        state => 'enabled'
    );

    my $rule4 = Entity::Rule::AggregateRule->new(
        service_provider_id => $service_provider->id,
        formula => 'id'.$ac_f->id.' || id'.$ac_f->id,
        state => 'enabled'
    );

    $rulesengine->oneRun();

    if (! (values %{$rule1->evaluate()})[0] == 1){ die '1 || 1 rule should be true';}
    if (! (values %{$rule2->evaluate()})[0] == 1){ die '1 || 0 rule should be true';}
    if (! (values %{$rule3->evaluate()})[0] == 1){ die '0 || 1 rule should be true';}
    if (! (values %{$rule4->evaluate()})[0] == 0){ die '0 || 0 rule should be false';}

}

sub test_not_n {

    my $r1 = Entity::Rule::NodemetricRule->new(
        service_provider_id => $service_provider->id,
        formula => '! id'.$nc_f->id,
        state => 'enabled'
    );

    my $r2 = Entity::Rule::NodemetricRule->new(
        service_provider_id => $service_provider->id,
        formula => '! id'.$nc_t->id,
        state => 'enabled'
    );

    my $r3 = Entity::Rule::NodemetricRule->new(
        service_provider_id => $service_provider->id,
        formula => 'not ! id'.$nc_f->id,
        state => 'enabled'
    );

    my $r4 = Entity::Rule::NodemetricRule->new(
        service_provider_id => $service_provider->id,
        formula => 'not ! id'.$nc_t->id,
        state => 'enabled'
    );

    $rulesengine->oneRun();


    VerifiedNoderule->find(hash => {
        verified_noderule_node_id    => $node->id,
        verified_noderule_nodemetric_rule_id => $r1->id,
        verified_noderule_state              => 'verified',
    });


    VerifiedNoderule->find(hash => {
        verified_noderule_node_id    => $node2->id,
        verified_noderule_nodemetric_rule_id => $r1->id,
        verified_noderule_state              => 'undef',
    });


    expectedException {
        VerifiedNoderule->find(hash => {
            verified_noderule_node_id    => $node->id,
            verified_noderule_nodemetric_rule_id => $r2->id,
            verified_noderule_state              => 'verified',
        });
    } 'Kanopya::Exception::Internal::NotFound', 'Nodemetric rule ! 1 should be false';

    expectedException {
        VerifiedNoderule->find(hash => {
            verified_noderule_node_id    => $node->id,
            verified_noderule_nodemetric_rule_id => $r3->id,
            verified_noderule_state              => 'verified',
        })
    } 'Kanopya::Exception::Internal::NotFound', 'Nodemetric rule not ! 0 should be false';

    VerifiedNoderule->find(hash => {
        verified_noderule_node_id    => $node->id,
        verified_noderule_nodemetric_rule_id => $r4->id,
        verified_noderule_state              => 'verified',
    });
}


sub test_not{
    my $rule1 = Entity::Rule::AggregateRule->new(
        service_provider_id => $service_provider->id,
        formula => 'id'.$ac_t->id,
        state => 'enabled'
    );

    my $rule2 = Entity::Rule::AggregateRule->new(
        service_provider_id => $service_provider->id,
        formula => '! id'.$ac_t->id,
        state => 'enabled'
    );

    my $rule3 = Entity::Rule::AggregateRule->new(
        service_provider_id => $service_provider->id,
        formula => 'id'.$ac_f->id,
        state => 'enabled'
    );

    my $rule4 = Entity::Rule::AggregateRule->new(
        service_provider_id => $service_provider->id,
        formula => '! id'.$ac_f->id,
        state => 'enabled'
    );

    my $rule5 = Entity::Rule::AggregateRule->new(
        service_provider_id => $service_provider->id,
        formula => 'not ! id'.$ac_t->id,
        state => 'enabled'
    );

    my $rule6 = Entity::Rule::AggregateRule->new(
        service_provider_id => $service_provider->id,
        formula => '! not ! id'.$ac_t->id,
        state => 'enabled'
    );

    $rulesengine->oneRun();

    if (! (values %{$rule1->evaluate()})[0] == 1) { die '1 rule should be true'}
    if (! (values %{$rule2->evaluate()})[0] == 0) { die '! 1 rule should be false';}
    if (! (values %{$rule3->evaluate()})[0] == 0) { die '0 rule should be false';}
    if (! (values %{$rule4->evaluate()})[0] == 1) { die '! 0 rule should be true';}
    if (! (values %{$rule5->evaluate()})[0] == 1) { die 'not ! 1 rule should be true';}
    if (! (values %{$rule6->evaluate()})[0] == 0) { die '! not ! 1 rule hould be false';}
}

sub test_big_formulas_n {

    my $r1 = Entity::Rule::NodemetricRule->new(
        service_provider_id => $service_provider->id,
        formula => '(!('.'id'.$nc_t->id.' && (!'.'id'.$nc_f->id.') && '.'id'.$nc_t->id.')) || ! ('.'id'.$nc_t->id.' && '.'id'.$nc_f->id.')',
        state => 'enabled'
    );

    $rulesengine->oneRun();

    VerifiedNoderule->find(hash => {
        verified_noderule_node_id    => $node->id,
        verified_noderule_nodemetric_rule_id => $r1->id,
        verified_noderule_state              => 'verified',
    })

}

sub test_big_formulas {
    my $rule1 = Entity::Rule::AggregateRule->new(
        service_provider_id => $service_provider->id,
        formula => '(!! ('.'id'.$ac_t->id.' || '.'id'.$ac_f->id.')) && ('.'id'.$ac_t->id.' && '.'id'.$ac_t->id.')',
        state => 'enabled'
    );

    my $rule2 = Entity::Rule::AggregateRule->new(
        service_provider_id => $service_provider->id,
        formula => '(('.'id'.$ac_f->id.' || '.'id'.$ac_f->id.') || ('.'id'.$ac_f->id.' || '.'id'.$ac_t->id.')) && ! ( (! ('.'id'.$ac_f->id.' || '.'id'.$ac_t->id.')) || ! ('.'id'.$ac_t->id.' && '.'id'.$ac_t->id.'))',
        state => 'enabled'
    );

    $rulesengine->oneRun();

    if (! (values %{$rule1->evaluate()})[0] == 1){ die '(!! (1 || 0)) && (1 && 1) rule should be true'};
    if (! (values %{$rule2->evaluate()})[0] == 1){ die '((0 || 0) || (0 || 1)) && ! ( (! (0 || 1)) || ! (1 && 1)) rule should be true'};
}

sub test_aggregate_condition_update {

    lives_ok {

        # Clustermetric
        my $cm = Entity::Clustermetric->new(
            clustermetric_service_provider_id => $service_provider->id,
            clustermetric_indicator_id => ($indic1->id),
            clustermetric_statistics_function_name => 'sum',
            clustermetric_window_time => '1200',
        );

        # Combination
        my $comb = Entity::Combination::AggregateCombination->new(
            service_provider_id             =>  $service_provider->id,
            aggregate_combination_formula   => 'id'.($cm->id),
        );

        # Combination
        my $comb2 = Entity::Combination::AggregateCombination->new(
            service_provider_id             =>  $service_provider->id,
            aggregate_combination_formula   => '2*id'.($cm->id),
        );

        # Condition
        $ac_left = Entity::AggregateCondition->new(
            aggregate_condition_service_provider_id => $service_provider->id,
            left_combination_id => $comb->id,
            comparator => '<',
            threshold => '12.34',
        );

        $ac_right = Entity::AggregateCondition->new(
            aggregate_condition_service_provider_id => $service_provider->id,
            threshold => '-43.21',
            comparator => '<',
            right_combination_id => $comb->id,
        );

        $ac_both = Entity::AggregateCondition->new(
            aggregate_condition_service_provider_id => $service_provider->id,
            left_combination_id  => $comb->id,
            comparator => '<',
            right_combination_id => $comb2->id,
        );

        my $old_constant_comb_id = $ac_left->right_combination_id;

        $ac_left->update(
            left_combination_id => $comb2->id,
            comparator => '>',
            threshold => '12.35',
        );

        $ac_left = Entity->get (id => $ac_left->id);

        if (! ( $ac_left->left_combination_id == $comb2->id &&
                $ac_left->comparator eq '>' &&
                $ac_left->right_combination->value eq '12.35' )) {
            die 'Fail in aggregate combination update'
        }

        expectedException {
            Entity->get(id => $old_constant_comb_id);
        } 'Kanopya::Exception::Internal::NotFound', 'Old constant combination has not been deleted';

        $old_constant_comb_id = $ac_right->left_combination_id;
        $ac_right->update(
            threshold => '-43.2',
            comparator => '>',
            left_combination_id => $comb2->id,
        );

        $ac_right = Entity->get (id => $ac_right->id);
        if (! ($ac_right->left_combination_id == $comb2->id &&
               $ac_right->comparator eq '>'&&
               $ac_right->right_combination->value eq '-43.2')) {
            die 'Fail in aggregate combination update';
       }

        expectedException {
            Entity->get(id => $old_constant_comb_id);
        } 'Kanopya::Exception::Internal::NotFound', 'Check old constant combination has been deleted';
    } 'Aggregate condition update'
}

sub test_nodemetric_condition_update {

    lives_ok {
        # Clustermetric
        my $cm = Entity::Clustermetric->new(
            clustermetric_service_provider_id => $service_provider->id,
            clustermetric_indicator_id => ($indic1->id),
            clustermetric_statistics_function_name => 'mean',
            clustermetric_window_time => '1200',
        );

        #  Nodemetric combination
        my $ncomb = Entity::Combination::NodemetricCombination->new(
            service_provider_id             => $service_provider->id,
            nodemetric_combination_formula  => 'id'.($indic1->id),
        );

        # Aggregate Combination
        my $comb = Entity::Combination::AggregateCombination->new(
            service_provider_id             =>  $service_provider->id,
            aggregate_combination_formula   => 'id'.($cm->id),
        );

        my $nc_agg_th_right = Entity::NodemetricCondition->new(
            nodemetric_condition_service_provider_id => $service_provider->id,
            left_combination_id             => $comb->id,
            nodemetric_condition_comparator => '>',
            nodemetric_condition_threshold  => '-1.2',
        );

        my $nc_agg_th_left = Entity::NodemetricCondition->new(
            nodemetric_condition_service_provider_id => $service_provider->id,
            nodemetric_condition_threshold  => '-1.4',
            nodemetric_condition_comparator => '<',
            right_combination_id            => $comb->id,
        );

        my $nc_mix_1 = Entity::NodemetricCondition->new(
            nodemetric_condition_service_provider_id => $service_provider->id,
            left_combination_id             => $ncomb->id,
            nodemetric_condition_comparator => '<',
            right_combination_id            => $comb->id,
        );

        my $old_constant_combination_id = $nc_agg_th_right->right_combination_id;

        $nc_agg_th_right->update (
            nodemetric_condition_service_provider_id => $service_provider->id,
            left_combination_id             => $ncomb->id,
            nodemetric_condition_comparator => '>',
            nodemetric_condition_threshold  => '2.4',
        );

        $nc_agg_th_right = Entity->get (id => $nc_agg_th_right->id);

        if (! ( $nc_agg_th_right->left_combination_id == $ncomb->id &&
                $nc_agg_th_right->nodemetric_condition_comparator eq '>' &&
                $nc_agg_th_right->right_combination->value eq '2.4')) {
            die 'Fail in nodemetric condition update'
        }

        expectedException {
            Entity->get(id => $old_constant_combination_id);
        } 'Kanopya::Exception::Internal::NotFound', 'Old constant combination has not been deleted';

        $old_constant_combination_id = $nc_agg_th_left->left_combination_id;

        $nc_agg_th_left->update (
            nodemetric_condition_service_provider_id => $service_provider->id,
            nodemetric_condition_threshold  => '2.7',
            nodemetric_condition_comparator => '>',
            left_combination_id            => $comb->id,
        );

        $nc_agg_th_left = Entity->get (id => $nc_agg_th_left->id);

        if (! ( $nc_agg_th_left->left_combination_id == $comb->id &&
                $nc_agg_th_left->nodemetric_condition_comparator eq '>' &&
                $nc_agg_th_left->right_combination->value eq '2.7' )) {
            die 'Fail in nodemetric condition update'
        }

        expectedException {
            Entity->get(id => $old_constant_combination_id);
        } 'Kanopya::Exception::Internal::NotFound', 'Old constant combination has not been deleted';
    } 'Nodemetric condition update';
}
