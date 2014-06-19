  #!/usr/bin/perl -w

=head1 SCOPE

TODO

=head1 PRE-REQUISITE

TODO

=cut

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;

use Entity::Metric;

use Data::Dumper;
use TryCatch;
use Log::Log4perl qw(:easy get_logger);

use Kanopya::Database; Kanopya::Database::authenticate( login =>'admin', password => 'K4n0pY4' );

use Kanopya::Tools::Create;
use Entity::Component::MockMonitor;
use Entity::Component::Physicalhoster0;
use Entity::Host;
use Entity::Node;
use Entity::Metric::Clustermetric;
use Kanopya::Tools::TimeSerie;
use AnomalyDetector;
use TryCatch;
use Entity::Metric::Anomaly;
use Entity::AggregateCondition;
use Entity::Metric::Combination::AggregateCombination;
use Entity::Metric::Combination::ConstantCombination;
use Entity::Rule::AggregateRule;

Log::Log4perl->easy_init({
    level  => 'INFO',
    file   => __FILE__ . '.log',
    layout => '%d [ %H - %P ] %p -> %M - %m%n'
});

my $testing = 1;

my $an = AnomalyDetector->new();
my $cm;
my $nm;
my $cluster = ();
my $mock_cluster;
my ($cm_anomaly, $nm_anomaly);
my $collector_indicator;
main();

sub main {

    if ($testing == 1) {
        Kanopya::Database::beginTransaction;
    }
    setup();
    clustermetric_anomaly();
    nodemetric_anomaly();
    nm_anomaly_detector();
    cm_anomaly_detector();
    seasonality_algorithm();
    anomaly_rules();
    clean();
    if ($testing == 1) {
        Kanopya::Database::rollbackTransaction;
    }
}

sub setup {
    my $cluster_name = 'AnomalyDetectionTest';
    my $mock_cluster_name = 'AnomalyDetectionTestMock';

    $cluster = Kanopya::Tools::Create->createCluster(
                       cluster_conf => {cluster_name => $cluster_name},
                       no_execution => 1,
                   );

    $mock_cluster = Kanopya::Tools::Create->createCluster(
                        cluster_conf => {cluster_name => $mock_cluster_name},
                        no_execution => 1,
                    );

    my $mockmonitor = Entity::Component::MockMonitor->new(service_provider_id => $mock_cluster->id);

    my $manager = $cluster->addManager(
                      manager_id => $mockmonitor->id,
                      manager_type => 'CollectorManager',
                      no_default_conf => 1,
                  );

    my $host = Entity::Host->new(host_serial_number => 'AnomalyDetectionTestHost1',
                              host_manager_id    => Entity::Component::Physicalhoster0->find()->id);

    my $node = Entity::Node->new(node_hostname       => 'AnomalyDetectionTestNode1',
                                 service_provider_id => $cluster->id,
                                 monitoring_state    => 'up',
                                 host_id             => $host->id,
                                 node_state          => 'in:'.time());

    my $indicator = Entity::Indicator->find(hash => {indicator_oid => '.1.3.6.1.4.1.2021.4.5.0'});

    $collector_indicator = $mockmonitor->find(
                               related => 'collector_indicators',
                               hash    => {indicator_id => $indicator->id},
                           );

    $cm = Entity::Metric::Clustermetric->new(
              clustermetric_service_provider_id      => $cluster->id,
              clustermetric_statistics_function_name => 'sum',
              clustermetric_indicator_id             => $collector_indicator->id,
          );

    $nm = Entity::Metric::Nodemetric->find(
              nodemetric_node_id => $node->id,
              nodemetric_indicator_id => $collector_indicator->id
          );
}

sub clustermetric_anomaly {
    $cm_anomaly = Entity::Metric::Anomaly->new(related_metric_id => $cm->id);
    test_anomalie_linear_regression(anomaly => $cm_anomaly);
}

sub nodemetric_anomaly {
    $nm_anomaly = Entity::Metric::Anomaly->new(related_metric_id => $nm->id);
    test_anomalie_linear_regression(anomaly => $nm_anomaly);
}

sub seasonality_algorithm {
    lives_ok {
        my $clustermetric = Entity::Metric::Clustermetric->new(
                              clustermetric_service_provider_id      => $cluster->id,
                              clustermetric_statistics_function_name => 'sum',
                              clustermetric_indicator_id             => $collector_indicator->id,
                          );

        my $anomaly_default = Entity::Metric::Anomaly->new(related_metric_id => $clustermetric->id);
        my $time = time();
        my %function_conf = (func => 'sin(2*3.14159*X/288)', # Frequency 300*288 = daily
                           rows => 3000,
                           step => 300,
                           time => $time + 1000*300 );
        my $ts = Kanopya::Tools::TimeSerie->new();
        $ts->generatemetric(metric => $clustermetric, %function_conf);

        # default config
        my $v = $anomaly_default->computeAnomaly(
                    values => $clustermetric->fetch(output => 'arrays', samples => 288+30),
                );

        if ($v->{value} > 10 ** -5) {
            die 'Pure 1 day seasonality signal must have no anomaly with default params';
        }

        # period param
        $function_conf{func} = 'sin( 2 * 3.14159 * X / (2 * 288) )'; # 2 days seasonality
        $ts->generatemetric(metric => $clustermetric, %function_conf);

        $v = $anomaly_default->computeAnomaly(values => $clustermetric->fetch(output => 'arrays', samples => 288+30));

        if ($v->{value} < 10 ** -5) {
            die 'Pure 2 days seasonality signal analyses with 1 day seasonality detection must have anomaly';
        }

        $v = $anomaly_default->computeAnomaly(
                 values => $clustermetric->fetch(output => 'arrays', samples => 2*288+30),
                 params => {period => 2 * 24* 60 * 60},
             );

        if ($v->{value} > 10 ** -5) {
            die 'Pure 2 days seasonality signal analyses with 2 days seasonality detection must have no anomaly';
        }

        # num_periods param

        $function_conf{func} = 'sin( 2 * 3.14159 * X / (1 * 288) )'; # 1 day seasonality
        $ts->generatemetric(metric => $clustermetric, %function_conf);
        my $fetch = $clustermetric->fetch(output => 'arrays', samples => 2*288+30);

        for my $i (0..20) {
            $fetch->{values}->[-$i-288] = 0;
        }

        $v = $anomaly_default->computeAnomaly(values => $fetch);

        if ($v->{value} < 10 ** -5) {
            die 'Anomaly detected when analyzing 1 period';
        }

        $v = $anomaly_default->computeAnomaly(values => $fetch, params => {num_periods => 2});

        if ($v->{value} > 10 ** -5) {
            die 'Anomaly not detected when analyzing 2 periods';
        }

    } 'Seasonality algorithm';

    # my $anomaly_param = Entity::Metric::Anomaly->new(related_metric_id => $m->id, params => {num_periods => 2, period => 7*24*60*60});

}

sub test_anomalie_linear_regression {
    my %args = @_;
    my $anomaly = $args{anomaly};
    lives_ok {
        my $values = {
            values     => [0..50],
            timestamps => [0..50],
        };

        my $val = $anomaly->computeAnomaly(values => $values, method => 'AnomalyDetection::LinearRegression');

        if (! defined $val->{value}) {
            die 'computeAnomaly should be defined';
        }

        if ($val->{value} > 10**-5) {
            die 'computeAnomaly should be close to 0';
        }

        $values = {
            values     => [map {$_ % 2} (0..50)],
            timestamps => [0..50],
        };

        my $val = $anomaly->computeAnomaly(values => $values, method => 'AnomalyDetection::LinearRegression');

        if (! defined $val->{value}) {
            die 'computeAnomaly should be defined';
        }

        if ($val->{value} < 10**-2) {
            die 'computeAnomaly should not be close to 0';
        }

    } 'Anomaly Linear Regression';

    lives_ok {
        my $last_val = $anomaly->evaluate();

        if (defined $last_val) {
            die 'computeAnomaly should not be defined';
        }

        $anomaly->updateData(
            time             => time(),
            value            => 67,
            time_step        => $an->{config}->{time_step},
            storage_duration => $an->{config}->{storage_duration}
        );

        $last_val = $anomaly->evaluate();

        if (! defined $last_val) {
            die 'computeAnomaly should be defined';
        }
        if ($last_val ne 67) {
           die 'computeAnomaly wrong value stored';
        }
    } 'Anomaly storage'
}

sub nm_anomaly_detector {
    anomaly_detector(anomaly => $nm_anomaly);
}

sub cm_anomaly_detector {
    anomaly_detector(anomaly => $cm_anomaly);
}

sub anomaly_detector {
    my %args = @_;
    my $anomaly = $args{anomaly};
    lives_ok {
        $anomaly->resetData();

        my $last_val = $anomaly->evaluate();
        if (defined $last_val) {
            die 'computeAnomaly should not be defined';
        }

        my $ts = Kanopya::Tools::TimeSerie->new();

        my %fonction_conf = (func => 'X', # Frequency 300*288 = daily
                             rows => 50,
                             step => 300,
                             time => time());

        $ts->generatemetric(metric => $anomaly->related_metric, %fonction_conf);

        $an->update(anomalies => [$anomaly]);

        my $last_val = $anomaly->evaluate();

        if ($last_val > 10**-5) {
            die 'computeAnomaly should be close to zero'
        }

     } 'Anomaly detector main loop'
}


sub anomaly_rules {
        my $ts = Kanopya::Tools::TimeSerie->new();

        my %fonction_conf = (func => '67', # Frequency 300*288 = daily
                             rows => 50,
                             step => 300,
                             time => time() + 300);

        $ts->generatemetric(metric => $cm_anomaly, %fonction_conf);

        my $comb;
        my $true_cond;
        my $false_cond;

        lives_ok {
            my $values = $cm_anomaly->fetch(samples => 10);

            for my $value (values %$values) {
                if (! defined $value || $value ne 67) {
                    die 'Wrong value stored in anomaly';
                }
            }

            $comb = Entity::Metric::Combination::AggregateCombination->new(
                        service_provider_id => $cluster->id,
                        aggregate_combination_formula => 'id'.$cm_anomaly->id
                    );

            my $comb_value = $comb->evaluate();

            if (! defined $comb_value || $comb_value ne 67) {
                die 'Wrong value expected <67> got <' . $comb_value . '>';
            }

        } 'Combination of anomaly';

        lives_ok {
            my $comb_68 = Entity::Metric::Combination::ConstantCombination->new(
                                 value => 68,
                                 service_provider_id => $cluster->id
                             );

            $false_cond = Entity::AggregateCondition->new(
                                 left_combination_id => $comb->id,
                                 comparator => '>',
                                 right_combination_id => $comb_68->id,
                                 aggregate_condition_service_provider_id => $cluster->id,
                             );

            $true_cond = Entity::AggregateCondition->new(
                                left_combination_id => $comb->id,
                                comparator => '<',
                                right_combination_id => $comb_68->id,
                                aggregate_condition_service_provider_id => $cluster->id,
                            );

            my $true = $true_cond->evaluate();
            my $false = $false_cond->evaluate();

            if (! defined $true || $true ne 1) {
                die "True condition evaluation expected <1> got <$true>";
            }

            if (! defined $false || $false ne 0) {
                die "False condition evaluation expected <1> got <$true>";
            }
        } 'Condition on anomaly';

    lives_ok {
        my $rule_ok = Entity::Rule::AggregateRule->new(
                          formula => 'id'.$true_cond->id,
                          service_provider_id => $cluster->id
                      );

        my $rule_nok = Entity::Rule::AggregateRule->new(
                           formula => 'id'.$false_cond->id,
                           service_provider_id => $cluster->id
                       );

        my $ok = $rule_ok->evaluate();
        my $nok = $rule_nok->evaluate();

        if (! defined $ok->{$cluster->id} || $ok->{$cluster->id} ne 1) {
            die 'Rule ok evaluation expected <1> got <' . $ok->{$cluster->id} . '>';
        }

        if (! defined $nok->{$cluster->id} || $nok->{$cluster->id} ne 0) {
            die 'Rule nok evaluation expected <0> got <' . $nok->{$cluster->id} . '>';
        }
    } 'Rules on anomaly';
}

sub clean {
    try { Entity::ServiceProvider::remove($cluster); }
    try { Entity::ServiceProvider::remove($cluster); }
    try { $nm_anomaly->remove(); }
    try { $cm_anomaly->remove(); }
}
1;
