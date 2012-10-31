#!/usr/bin/perl


use strict;
use warnings;
use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Data::Dumper;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'/tmp/alert_on_undef_values.log', layout=>'%F %L %p %m%n'});
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

my ($indic1, $indic2);
my $service_provider;
my $aggregator;
my $orchestrator;

eval{
    $aggregator   = Aggregator->new();
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

    # Create node 2
    Externalnode->new(
        externalnode_hostname => 'node_2',
        service_provider_id   => $service_provider->id,
        externalnode_state    => 'up',
    );

    # Get indicators
    $indic1 = CollectorIndicator->find (
        hash => {
            collector_manager_id        => $mock_monitor->id,
            'indicator.indicator_oid'   => 'Memory/PercentMemoryUsed',
        }
    );

    $indic2 = CollectorIndicator->find (
        hash => {
            collector_manager_id        => $mock_monitor->id,
            'indicator.indicator_oid'   => 'Memory/Pool Paged Bytes'
        }
    );

    my $cm = Clustermetric->new(
        clustermetric_service_provider_id => $service_provider->id,
        clustermetric_indicator_id => ($indic1->id),
        clustermetric_statistics_function_name => 'mean',
        clustermetric_window_time => '1200',
    );

    my $cm2 = Clustermetric->new(
        clustermetric_service_provider_id => $service_provider->id,
        clustermetric_indicator_id => ($indic2->id),
        clustermetric_statistics_function_name => 'sum',
        clustermetric_window_time => '1200',
    );

    # Create nodemetric rule objects
    my $ncomb1 = NodemetricCombination->new(
        nodemetric_combination_service_provider_id => $service_provider->id,
        nodemetric_combination_formula => 'id'.($indic1->id),
    );

    # Create nodemetric rule objects
    my $ncomb2 = NodemetricCombination->new(
        nodemetric_combination_service_provider_id => $service_provider->id,
        nodemetric_combination_formula => 'id'.($indic2->id),
    );

    my $nc1 = NodemetricCondition->new(
        nodemetric_condition_service_provider_id => $service_provider->id,
        nodemetric_condition_combination_id => $ncomb1->id,
        nodemetric_condition_comparator => '<',
        nodemetric_condition_threshold => '0',
    );

    my $nc2 = NodemetricCondition->new(
        nodemetric_condition_service_provider_id => $service_provider->id,
        nodemetric_condition_combination_id => $ncomb2->id,
        nodemetric_condition_comparator => '<',
        nodemetric_condition_threshold => '0',
    );

    my $nr1 = NodemetricRule->new(
        nodemetric_rule_service_provider_id => $service_provider->id,
        nodemetric_rule_formula => 'id'.$nc1->id,
        nodemetric_rule_state => 'enabled'
    );

    my $nr2 = NodemetricRule->new(
        nodemetric_rule_service_provider_id => $service_provider->id,
        nodemetric_rule_formula => 'id'.$nc2->id,
        nodemetric_rule_state => 'enabled'
    );

    test_alerts_aggregator();
    test_alerts_orchestrator();
    # $adm->rollbackTransaction;
    $adm->commitTransaction;
};
if($@) {
    $adm->rollbackTransaction;
    my $error = $@;
    print $error."\n";
    fail('Exception occurs');
}

sub test_alerts_aggregator {

    # More complex config:
    #        node1 node2
    # indic1  50    10
    # indic2  50    null

    my $mock_conf  = "{'default':{'const':10},"
                . "'nodes':{'node_1':{'const':50}},'indics':{'Memory/Pool Paged Bytes':{'const':null}}}";
    $service_provider->addManagerParameter (
        manager_type    => 'collector_manager',
        name            => 'mockmonit_config',
        value           => $mock_conf
    );

    is (scalar Alert->search (hash=>{}), 0, 'Check there is no alert');

    sleep 2;
    $aggregator->update ();

    my @alerts = Alert->search (hash=>{});
    is (scalar @alerts, 1, 'Check one alert has been created');
    my $first_alert = pop @alerts;

    my $alert_msg = "Indicator RAM pool paged(Memory/Pool Paged Bytes) was not retrieved by collector for node node_2";
    is ($first_alert->alert_message, $alert_msg, 'Check alert message');
    is ($first_alert->alert_active, 1, 'Check alert is active');

    sleep 2;
    $aggregator->update ();

    @alerts = Alert->search (hash=>{});
    is (scalar @alerts, 1, 'Check no more alert created');
    my $alert = pop @alerts;

    is ($alert->alert_message,$alert_msg,'Check alert message');
    is ($alert->alert_active,1,'Check alert is still active');

    $mock_conf  = "{'default':{'const':10},"
                . "'nodes':{'node_1':{'const':50}},'indics':{'Memory/Pool Paged Bytes':{'const':100}}}";
    $service_provider->addManagerParameter (
        manager_type    => 'collector_manager',
        name            => 'mockmonit_config',
        value           => $mock_conf
    );

    sleep 2;
    $aggregator->update ();

    @alerts = Alert->search (hash=>{});
    is (scalar @alerts, 1, 'Check no more alert created');
    $alert = pop @alerts;

    is ($alert->alert_message, $alert_msg, 'Check alert message');
    is ($alert->alert_active, 0, 'Check alert not active anymore');

    $mock_conf  = "{'default':{'const':10},"
                . "'nodes':{'node_1':{'const':50}},'indics':{'Memory/Pool Paged Bytes':{'const':null}}}";
    $service_provider->addManagerParameter(
        manager_type    => 'collector_manager',
        name            => 'mockmonit_config',
        value           => $mock_conf
    );

    sleep(2);
    $aggregator->update();

    @alerts = Alert->search(hash=>{}, order_by => 'alert_id asc');
    is (scalar @alerts, 2, 'Check one new alert created');

    $alert = pop @alerts;
    is ($alert->alert_message,$alert_msg,'Check alert message');
    is ($alert->alert_active,1,'Check new alert is active');

    $alert = pop @alerts;

    is ($alert->alert_message, $alert_msg, 'Check alert message');
    is ($alert->alert_active, 0, 'Check old alert still not active');
    is ($alert->alert_id, $first_alert->alert_id, 'Check first alert id');
};

sub test_alerts_orchestrator {

    my @alerts = Alert->search (hash => {});
    while (@alerts) { (pop @alerts)->delete() };

    is (scalar Alert->search (hash => {}), 0, 'Check no alerts');

    my $mock_conf  = "{'default':{'const':10},"
                . "'nodes':{'node_1':{'const':50}},'indics':{'Memory/Pool Paged Bytes':{'const':100}}}";

    $service_provider->addManagerParameter (
        manager_type    => 'collector_manager',
        name            => 'mockmonit_config',
        value           => $mock_conf
    );

    $orchestrator->manage_aggregates ();

    is(scalar Alert->search (hash => {}), 0, 'Check no alert after orchestrator');

    $mock_conf  = "{'default':{'const':10},"
                . "'nodes':{'node_1':{'const':50}},'indics':{'Memory/Pool Paged Bytes':{'const':null}}}";

    $service_provider->addManagerParameter (
        manager_type    => 'collector_manager',
        name            => 'mockmonit_config',
        value           => $mock_conf
    );

    $orchestrator->manage_aggregates ();

    @alerts = Alert->search (hash => {});
    is (scalar @alerts, 1, 'Check one alert');

    my $first_alert = pop @alerts;

    my $alert_msg = "Indicator RAM pool paged (Memory/Pool Paged Bytes) was not retrieved by collector for node node_2";
    is ($first_alert->alert_message, $alert_msg, 'Check alert message');
    is ($first_alert->alert_active, 1, 'Check alert is active');

    $orchestrator->manage_aggregates ();

    @alerts = Alert->search (hash=>{});
    is (scalar @alerts, 1, 'Check no more alert created');
    my $alert = pop @alerts;

    is ($alert->alert_message, $alert_msg, 'Check alert message');
    is ($alert->alert_active, 1, 'Check alert is still active');

    $mock_conf  = "{'default':{'const':10},"
                . "'nodes':{'node_1':{'const':50}},'indics':{'Memory/Pool Paged Bytes':{'const':100}}}";

    $service_provider->addManagerParameter (
        manager_type    => 'collector_manager',
        name            => 'mockmonit_config',
        value           => $mock_conf
    );

    $orchestrator->manage_aggregates ();

    @alerts = Alert->search (hash=>{});
    is (scalar @alerts, 1, 'Check no more alert created');
    $alert = pop @alerts;

    is ($alert->alert_message,$alert_msg,'Check alert message');
    is ($alert->alert_active,0,'Check alert not active anymore');

    $mock_conf  = "{'default':{'const':10},"
                . "'nodes':{'node_1':{'const':50}},'indics':{'Memory/Pool Paged Bytes':{'const':null}}}";

    $service_provider->addManagerParameter (
        manager_type    => 'collector_manager',
        name            => 'mockmonit_config',
        value           => $mock_conf
    );

    $orchestrator->manage_aggregates ();

    @alerts = Alert->search (hash=>{}, order_by => 'alert_id asc');
    is (scalar @alerts, 2, 'Check one new alert created');

    $alert = pop @alerts;
    is ($alert->alert_message, $alert_msg, 'Check alert message');
    is ($alert->alert_active, 1, 'Check new alert is active');

    $alert = pop @alerts;

    is ($alert->alert_message, $alert_msg, 'Check alert message');
    is ($alert->alert_active, 0, 'Check old alert still not active');
    is ($alert->alert_id, $first_alert->alert_id, 'Check first alert id');
};

