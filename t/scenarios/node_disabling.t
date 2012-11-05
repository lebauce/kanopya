#!/usr/bin/perl


use strict;
use warnings;
use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Data::Dumper;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'/vagrant/node_disabling.log', layout=>'%F %L %p %m%n'});


lives_ok {
    use Administrator;
    use Orchestrator;
    use Aggregator;
    use Entity::ServiceProvider::Outside::Externalcluster;
    use Entity::Connector::MockMonitor;
    use Entity::Combination::NodemetricCombination;
    use Entity::NodemetricCondition;
    use Entity::NodemetricRule;
    use VerifiedNoderule;
    use Entity::Clustermetric;
    use Entity::Combination::AggregateCombination;
    use Entity::CollectorIndicator;
} 'All uses';

Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
my $adm = Administrator->new;
$adm->beginTransaction;

my $acomb1;
my $nrule1;
my @indicators;

eval{

    my $aggregator = Aggregator->new();
    my $orchestrator = Orchestrator->new();

    # Create externalcluster with a mock monitor
    my $external_cluster_mockmonitor = Entity::ServiceProvider::Outside::Externalcluster->new(
            externalcluster_name => 'Test Monitor',
    );

    my $mock_monitor = Entity::Connector::MockMonitor->new(
            service_provider_id => $external_cluster_mockmonitor->id,
    );

    my $service_provider = Entity::ServiceProvider::Outside::Externalcluster->new(
            externalcluster_name => 'Test Service Provider',
    );

    lives_ok{
        $service_provider->addManager(
            manager_id   => $mock_monitor->id,
            manager_type => 'collector_manager',
        );
    } 'Add mock monitor to service provider';

    # Create two nodes
    my $node1 = Externalnode->new(
        externalnode_hostname => 'test_node_1',
        service_provider_id   => $service_provider->id,
        externalnode_state    => 'up',
    );

    my $node2 = Externalnode->new(
        externalnode_hostname => 'test_node_2',
        service_provider_id   => $service_provider->id,
        externalnode_state    => 'up',
    );

    my $node3 = Externalnode->new(
        externalnode_hostname => 'test_node_3',
        service_provider_id   => $service_provider->id,
        externalnode_state    => 'up',
    );

    @indicators = Entity::CollectorIndicator->search (hash => {collector_manager_id => $mock_monitor->id});
    my $agg_rule_ids  = service_rule_objects_creation(indicators => \@indicators);
    my $node_rule_ids = node_rule_objects_creation(indicators => \@indicators);


    ok (!defined $acomb1->computeLastValue, 'no values before launching aggregator');
    $aggregator->update();
    ok ($acomb1->computeLastValue == 3, '3 nodes in aggregator');

    $node3->disable();

    sleep(5);
    $aggregator->update();

    # Reload object to get changes
    $node3 = Externalnode->get(id => $node3->id);

    ok ( $node3->externalnode_state eq 'disabled',
        'Disabling node 3'
    );

    ok ($acomb1->computeLastValue == 2, '2 nodes in aggregator');

    $node3->enable();

    $node3 = Externalnode->get(id => $node3->id);

    ok ( !($node3->externalnode_state eq 'disabled'),
        'Unabling node 3'
    );
    $aggregator->update();
    ok ($acomb1->computeLastValue == 3, '3 nodes in aggregator');

    $orchestrator->manage_aggregates();

    lives_ok {
        VerifiedNoderule->find(hash => {
            verified_noderule_externalnode_id    => $node1->id,
            verified_noderule_nodemetric_rule_id => $nrule1->id,
            verified_noderule_state              => 'verified',
        });
        VerifiedNoderule->find(hash => {
            verified_noderule_externalnode_id    => $node2->id,
            verified_noderule_nodemetric_rule_id => $nrule1->id,
            verified_noderule_state              => 'verified',
        });
        VerifiedNoderule->find(hash => {
            verified_noderule_externalnode_id    => $node3->id,
            verified_noderule_nodemetric_rule_id => $nrule1->id,
            verified_noderule_state              => 'verified',
        });
    } 'Check node rule are all verified';

    $node3->disable();

    dies_ok {
        VerifiedNoderule->find(hash => {
            verified_noderule_externalnode_id    => $node3->id,
            verified_noderule_nodemetric_rule_id => $nrule1->id,
            verified_noderule_state              => 'verified',
        });
    } 'Disabled node 3 and check rule not verified';

    $orchestrator->manage_aggregates();

    dies_ok {
        VerifiedNoderule->find(hash => {
            verified_noderule_externalnode_id    => $node3->id,
            verified_noderule_nodemetric_rule_id => $nrule1->id,
            verified_noderule_state              => 'verified',
        });
    } 'Run orchestrator, disabled node 3 and check rule not verified';
    $adm->rollbackTransaction;
};
if($@) {
    $adm->rollbackTransaction;
    my $error = $@;
    print $error."\n";
}

sub service_rule_objects_creation {
    lives_ok {

        my $service_provider = Entity::ServiceProvider::Outside::Externalcluster->find(
            hash => {externalcluster_name => 'Test Service Provider'}
        );

        my $cm1 = Entity::Clustermetric->new(
            clustermetric_service_provider_id => $service_provider->id,
            clustermetric_indicator_id => ((pop @indicators)->id),
            clustermetric_statistics_function_name => 'count',
            clustermetric_window_time => '1200',
        );

        $acomb1 = Entity::Combination::AggregateCombination->new(
            service_provider_id             =>  $service_provider->id,
            aggregate_combination_formula   => 'id'.($cm1->id),
        );

    } 'Create aggregate rules objects';
}

sub node_rule_objects_creation {
    lives_ok {
        my $service_provider = Entity::ServiceProvider::Outside::Externalcluster->find(
            hash => {externalcluster_name => 'Test Service Provider'}
        );

        # Create nodemetric rule objects
        my $ncomb1 = Entity::Combination::NodemetricCombination->new(
            service_provider_id             => $service_provider->id,
            nodemetric_combination_formula  => 'id'.((pop @indicators)->id).' + id'.((pop @indicators)->id),
        );

        my $nc1 = Entity::NodemetricCondition->new(
            nodemetric_condition_service_provider_id => $service_provider->id,
            left_combination_id => $ncomb1->id,
            nodemetric_condition_comparator => '>',
            nodemetric_condition_threshold => '0',
        );

        $nrule1 = Entity::NodemetricRule->new(
            nodemetric_rule_service_provider_id => $service_provider->id,
            nodemetric_rule_formula => 'id'.$nc1->id,
            nodemetric_rule_state => 'enabled'
        );

    } 'Create node rules objects';
}
