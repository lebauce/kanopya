#!/usr/bin/perl


use strict;
use warnings;
use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Data::Dumper;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'alert_on_undef_values.log', layout=>'%F %L %p %m%n'});
my $log = get_logger("");

use Kanopya::Database;
use Aggregator;
use RulesEngine;
use Entity::ServiceProvider::Externalcluster;
use Entity::Component::MockMonitor;
use Entity::Metric::Clustermetric;
use Entity::Metric::Combination::NodemetricCombination;

Kanopya::Database::authenticate( login =>'admin', password => 'K4n0pY4' );

Kanopya::Database::beginTransaction;

my ($coll_indic1, $coll_indic2);
my $service_provider;
my $aggregator;
my $rulesengine;

eval{
    $aggregator  = Aggregator->new();
    $rulesengine = RulesEngine->new();
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

    # Create node 1
    Node->new(
        node_hostname => 'node_1',
        service_provider_id   => $service_provider->id,
        monitoring_state    => 'up',
    );

    # Create node 2
    Node->new(
        node_hostname => 'node_2',
        service_provider_id   => $service_provider->id,
        monitoring_state    => 'up',
    );

    # Get indicators
    $coll_indic1 = Entity::CollectorIndicator->find(
        hash => {
            collector_manager_id        => $mock_monitor->id,
            'indicator.indicator_oid'   => 'Memory/PercentMemoryUsed',
        }
    );

    $coll_indic2 = Entity::CollectorIndicator->find(
        hash => {
            collector_manager_id        => $mock_monitor->id,
            'indicator.indicator_oid'   => 'Memory/Pool Paged Bytes'
        }
    );

    my $cm = Entity::Metric::Clustermetric->new(
                 clustermetric_service_provider_id => $service_provider->id,
                 clustermetric_indicator_id => ($coll_indic1->id),
                 clustermetric_statistics_function_name => 'mean',
                 clustermetric_window_time => '1200',
             );

    my $cm2 = Entity::Metric::Clustermetric->new(
                 clustermetric_service_provider_id => $service_provider->id,
                 clustermetric_indicator_id => ($coll_indic2->id),
                 clustermetric_statistics_function_name => 'sum',
                 clustermetric_window_time => '1200',
              );

    # Create nodemetric rule objects
    my $ncomb1 = Entity::Metric::Combination::NodemetricCombination->new(
                     service_provider_id => $service_provider->id,
                     nodemetric_combination_formula => 'id'.($coll_indic1->id),
                 );

    # Create nodemetric rule objects
    my $ncomb2 = Entity::Metric::Combination::NodemetricCombination->new(
                     service_provider_id => $service_provider->id,
                     nodemetric_combination_formula => 'id'.($coll_indic2->id),
                 );

    my $nc1 = Entity::NodemetricCondition->new(
        nodemetric_condition_service_provider_id => $service_provider->id,
        left_combination_id => $ncomb1->id,
        nodemetric_condition_comparator => '<',
        nodemetric_condition_threshold => '0',
    );

    my $nc2 = Entity::NodemetricCondition->new(
        nodemetric_condition_service_provider_id => $service_provider->id,
        left_combination_id => $ncomb2->id,
        nodemetric_condition_comparator => '<',
        nodemetric_condition_threshold => '0',
    );

    my $nr1 = Entity::Rule::NodemetricRule->new(
        service_provider_id => $service_provider->id,
        formula => 'id'.$nc1->id,
        state => 'enabled'
    );

    my $nr2 = Entity::Rule::NodemetricRule->new(
        service_provider_id => $service_provider->id,
        formula => 'id'.$nc2->id,
        state => 'enabled'
    );

    test_alerts_aggregator();
    test_alerts_orchestrator();
    test_rrd_remove();

    Kanopya::Database::rollbackTransaction;
};
if($@) {
    my $error = $@;
    print $error."\n";
    Kanopya::Database::rollbackTransaction;
    fail('Exception occurs');


}

sub test_rrd_remove {
    my @cms = Entity::Metric::Clustermetric->search (hash => {
                  clustermetric_service_provider_id => $service_provider->id
              });

    my @cm_ids = map {$_->id} @cms;
    while (@cms) { (pop @cms)->delete(); };

    my @acs = Entity::Metric::Combination::AggregateCombination->search (hash => {
                  service_provider_id => $service_provider->id
              });

    if (! (scalar @acs == 0)) {die 'Check all aggregate combinations are deleted';}

    my @ars = Entity::Rule::AggregateRule->search (hash => {
        service_provider_id => $service_provider->id
    });

    if (! (scalar @acs == 0)) {die 'Check all aggregate rules are deleted';}

    my $one_rrd_remove = 0;
    for my $cm_id (@cm_ids) {
        if (defined open(FILE,'/var/cache/kanopya/monitor/timeDB_'.$cm_id.'.rrd')) {
            $one_rrd_remove++;
        }
        close(FILE);
    }
    if (! ($one_rrd_remove == 0)) {die "Check all have been removed, still $one_rrd_remove rrd";}
}

sub test_alerts_aggregator {

    lives_ok {
        # More complex config:
        #        node1 node2
        # indic1  50    10
        # indic2  50    null

        my $mock_conf  = "{'default':{'const':10},"
                    . "'nodes':{'node_1':{'const':50}},'indics':{'Memory/Pool Paged Bytes':{'const':null}}}";

        $service_provider->addManagerParameter (
            manager_type    => 'CollectorManager',
            name            => 'mockmonit_config',
            value           => $mock_conf
        );

        my @alerts = Alert->search(hash=>{
            entity_id => $service_provider->id,
        });

        if (@alerts > 0) {
            die 'Some alert already present';
        }

        sleep 2;
        $aggregator->update();

        @alerts = Alert->search (hash => { entity_id => $service_provider->id });

        if (! (scalar @alerts == 1)) { die 'No alert created' };
        my $first_alert = pop @alerts;
        my $alert_msg = "Indicator RAM pool paged (Memory/Pool Paged Bytes) was not retrieved from collector for node node_2";

        if (! ($first_alert->alert_message eq $alert_msg)) {die 'Wrong alert message'}
        if (! ($first_alert->alert_active == 1)) {die 'Alert is not active'};
        if (! ($first_alert->trigger_entity_id == $coll_indic2->indicator->id)) {die 'Wrong trigger entity'};

        sleep 2;
        $aggregator->update();

        @alerts = Alert->search (hash => { entity_id => $service_provider->id });

        if (! (scalar @alerts == 1)) { die 'Wrong alert number, got '.(scalar @alerts).' instead of 1' };

        my $alert = pop @alerts;

        if (! ($alert->alert_message eq $alert_msg)) { die 'Wrong alert message'}
        if (! ($alert->alert_active == 1)) { die 'Alert is not active'}
        if (! ($alert->trigger_entity_id == $coll_indic2->indicator->id)) {die 'Wrong trigger entity'};


        $mock_conf  = "{'default':{'const':10},"
                    . "'nodes':{'node_1':{'const':50}},'indics':{'Memory/Pool Paged Bytes':{'const':100}}}";

        $service_provider->addManagerParameter(
            manager_type    => 'CollectorManager',
            name            => 'mockmonit_config',
            value           => $mock_conf
        );

        sleep 2;
        $aggregator->update();

        @alerts = Alert->search (hash => { entity_id => $service_provider->id });

        if (! (scalar @alerts == 1)) {die 'Check no more alert created (got '.(scalar @alerts).')'};
        $alert = pop @alerts;

        if (! ($alert->alert_message eq $alert_msg)) {die 'Wrong alert message'}
        if (! ($alert->alert_active == 0)) {die 'Alert not unactive'};
        if (! ($alert->trigger_entity_id == $coll_indic2->indicator->id)) {die 'Wrong trigger entity'};

        $mock_conf  = "{'default':{'const':10},"
                    . "'nodes':{'node_1':{'const':50}},'indics':{'Memory/Pool Paged Bytes':{'const':null}}}";

        $service_provider->addManagerParameter(
            manager_type    => 'CollectorManager',
            name            => 'mockmonit_config',
            value           => $mock_conf
        );

        sleep(2);
        $aggregator->update();

        @alerts = Alert->search(hash => { entity_id => $service_provider->id }, order_by => 'alert_id asc');
        if (! (scalar @alerts == 2)) {die 'One and only one alert must have been created';}

        $alert = pop @alerts;
        if ($alert->alert_id == $first_alert->alert_id) {die 'Not a new alert id';}
        if (! ($alert->alert_message eq $alert_msg)) {die 'Wrong alert message';}
        if (! ($alert->alert_active == 1)) {die 'Alert should be active ('.($alert->alert_active).')';}
        if (! ($alert->trigger_entity_id == $coll_indic2->indicator->id)) {die 'Wrong trigger entity'};

        $alert = pop @alerts;

        if (! ($alert->alert_message eq $alert_msg)) {die 'Check alert message';}
        if (! ($alert->alert_active == 0)) {die 'Check old alert still not active';}
        if (! ($alert->alert_id == $first_alert->alert_id)) {die 'Check first alert id';}
        if (! ($alert->trigger_entity_id == $coll_indic2->indicator->id)) {die 'Wrong trigger entity'};
    } 'Triggering alert with aggregator';
};

sub test_alerts_orchestrator {

    lives_ok {
        my @alerts = Alert->search(hash => { entity_id => $service_provider->id });
        while (@alerts) { (pop @alerts)->delete() };

        @alerts = Alert->search(hash => { entity_id => $service_provider->id });

        my $agg_alert_msg = "Indicator RAM pool paged (Memory/Pool Paged Bytes) was not retrieved from collector for node node_2";
        my $orch_alert_msg = "Indicator RAM pool paged (Memory/Pool Paged Bytes) was not retrieved from DataCache for node node_2";


        if (! (scalar @alerts == 0)) {die 'Check no alerts';}

        my $mock_conf  = "{'default':{'const':10},"
                         . "'nodes':{'node_1':{'const':50}},'indics':{'Memory/Pool Paged Bytes':{'const':100}}}";

        $service_provider->addManagerParameter (
            manager_type => 'CollectorManager',
            name         => 'mockmonit_config',
            value        => $mock_conf
        );

        sleep(2);
        $aggregator->update();

        @alerts = Alert->search(hash => { entity_id => $service_provider->id });
        if (! (scalar @alerts == 0)) {
            my $wrong_alert = pop @alerts;
            die 'Some alerts after aggregator: '.$wrong_alert->alert_message;
        }

        $rulesengine->oneRun();

        @alerts = Alert->search(hash => { entity_id => $service_provider->id });

        if (! (scalar @alerts == 0)) {
            my $wrong_alert = pop @alerts;
            die 'Some alerts after orchestrator: '.$wrong_alert->alert_message;
        }

        $mock_conf  = "{'default':{'const':10},"
                    . "'nodes':{'node_1':{'const':50}},'indics':{'Memory/Pool Paged Bytes':{'const':null}}}";

        $service_provider->addManagerParameter (
            manager_type    => 'CollectorManager',
            name            => 'mockmonit_config',
            value           => $mock_conf
        );

        sleep(2);
        $aggregator->update();

        @alerts = Alert->search(hash => { entity_id => $service_provider->id });

        if (! (scalar @alerts == 1)) {die 'One and only one alert';}

        my $agg_alert = pop @alerts;

        if (! ($agg_alert->alert_message eq $agg_alert_msg)) {die 'Wrong alert message';}
        if (! ($agg_alert->alert_active == 1)){die 'Alert should be active';}
        if (! ($agg_alert->trigger_entity_id == $coll_indic2->indicator_id)) {die 'Wrong trigger entity';}

        $rulesengine->oneRun();

        @alerts = Alert->search(hash => { entity_id => $service_provider->id }, order_by => 'alert_id asc');

        if (! (scalar @alerts == 2)) {die 'Two alerts';}

        my $orch_alert = pop @alerts;

        if (! ($orch_alert->alert_message eq $orch_alert_msg)) {die 'Wrong alert message';}
        if (! ($orch_alert->alert_active == 1)) {die 'Alert should be active';}
        if (! ($orch_alert->trigger_entity_id == $coll_indic2->id)) {die 'Wrong trigger entity'};

        my $alert = pop @alerts;

        if (! ($alert->id eq $agg_alert->id)) {die 'Must be same alert id';}
        if (! ($alert->alert_message eq $agg_alert_msg)) {die 'Wrong alert message';}
        if (! ($alert->alert_active == 1)) {die 'Alert should be still active';}
        if (! ($alert->trigger_entity_id == $coll_indic2->indicator_id)) {die 'Wrong trigger entity'};

        $rulesengine->oneRun();

        @alerts = Alert->search(hash => { entity_id => $service_provider->id });
        if (! (scalar @alerts == 2)) {die 'Check no more alert created'};

        $alert = pop @alerts;
        if (! ($alert->id == $orch_alert->id)) {die 'Check same id';}
        if (! ($alert->alert_active == 1)) {die 'Check alert is still active';}

        $alert = pop @alerts;
        if (! ($alert->id == $agg_alert->id)) {die 'Check same id';}
        if (! ($alert->alert_active == 1)) {die 'Check alert is still active';}

        $mock_conf  = "{'default':{'const':10},"
                    . "'nodes':{'node_1':{'const':50}},'indics':{'Memory/Pool Paged Bytes':{'const':100}}}";

        $service_provider->addManagerParameter (
            manager_type    => 'CollectorManager',
            name            => 'mockmonit_config',
            value           => $mock_conf
        );

        sleep(2);
        $aggregator->update();

        @alerts = Alert->search(hash => { entity_id => $service_provider->id });
        if (! (scalar @alerts == 2)) {die 'Check no more alert created'};

        $alert = pop @alerts;
        if (! ($alert->id == $orch_alert->id)) {die 'Check same id';}
        if (! ($alert->alert_active == 1)) {die 'Check alert is still active';}

        $alert = pop @alerts;
        if (! ($alert->id == $agg_alert->id)) {die 'Check same id';}
        if (! ($alert->alert_active == 0)) {die 'Check alert is still active';}

        $rulesengine->oneRun();

        @alerts = Alert->search(hash => { entity_id => $service_provider->id });
        if (! (scalar @alerts == 2)) {die 'Check no more alert created'};

        $alert = pop @alerts;
        if (! ($alert->id == $orch_alert->id)) {die 'Check same id';}
        if (! ($alert->alert_active == 0)) {die 'Check alert is still active';}

        $alert = pop @alerts;
        if (! ($alert->id == $agg_alert->id)) {die 'Check same id';}
        if (! ($alert->alert_active == 0)) {die 'Check alert is still active';}

        $mock_conf  = "{'default':{'const':10},"
                    . "'nodes':{'node_1':{'const':50}},'indics':{'Memory/Pool Paged Bytes':{'const':null}}}";

        $service_provider->addManagerParameter (
            manager_type    => 'CollectorManager',
            name            => 'mockmonit_config',
            value           => $mock_conf
        );

        sleep(2);
        $aggregator->update();

        @alerts = Alert->search(hash => { entity_id => $service_provider->id });
        if (! (scalar @alerts == 3)) {die 'Check no more alert created'};

        my $third_alert = pop @alerts;

        if (! ($third_alert->alert_message eq $agg_alert_msg)) {die 'Wrong alert message';}
        if (! ($third_alert->alert_active == 1)) {die 'Alert should be still active';}
        if (! ($third_alert->trigger_entity_id == $coll_indic2->indicator_id)) {die 'Wrong trigger entity'};

        $alert = pop @alerts;
        if (! ($alert->id == $orch_alert->id)) {die 'Check same id';}
        if (! ($alert->alert_active == 0)) {die 'Check alert is still active';}

        $alert = pop @alerts;
        if (! ($alert->id == $agg_alert->id)) {die 'Check same id';}
        if (! ($alert->alert_active == 0)) {die 'Check alert is still active';}

        $rulesengine->oneRun();

        @alerts = Alert->search(hash => { entity_id => $service_provider->id });
        if (! (scalar @alerts == 4)) {die 'Check no more alert created'};

        my $fourth_alert = pop @alerts;

        if (! ($fourth_alert->alert_message eq $orch_alert_msg)) {die 'Wrong alert message';}
        if (! ($fourth_alert->alert_active == 1)) {die 'Alert should be still active';}
        if (! ($fourth_alert->trigger_entity_id == $coll_indic2->id)) {die 'Wrong trigger entity'};

        $alert = pop @alerts;
        if (! ($alert->id == $third_alert->id)) {die 'Check same id';}
        if (! ($alert->alert_active == 1)) {die 'Check alert is still active';}

        $alert = pop @alerts;
        if (! ($alert->id == $orch_alert->id)) {die 'Check same id';}
        if (! ($alert->alert_active == 0)) {die 'Check alert is still active';}

        $alert = pop @alerts;
        if (! ($alert->id == $agg_alert->id)) {die 'Check same id';}
        if (! ($alert->alert_active == 0)) {die 'Check alert is still active';}
    } 'Triggering alert with aggregator and rules engine';
};

