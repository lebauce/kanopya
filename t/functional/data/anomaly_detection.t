  #!/usr/bin/perl -w

=head1 SCOPE

TODO

=head1 PRE-REQUISITE

TODO

=cut

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
use Node;
use Entity::Metric::Clustermetric;
use Kanopya::Tools::TimeSerie;
use AnomalyDetector;
use TryCatch;

Log::Log4perl->easy_init({
    level  => 'INFO',
    file   => __FILE__ . '.log',
    layout => '%d [ %H - %P ] %p -> %M - %m%n'
});

my $testing = 1;

my $an = AnomalyDetector->new();
my $cm;
my $cluster = ();
my $mock_cluster;

main();

sub main {

    if ($testing == 1) {
        Kanopya::Database::beginTransaction;
    }
    setup();
    clustermetric_anomaly();
    anomaly_detector();
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

    $cluster->addManager(
        manager_id      => $mockmonitor->id,
        manager_type    => 'CollectorManager',
        no_default_conf => 1,
    );

    my $host = Entity::Host->new(host_serial_number => 'AnomalyDetectionTestHost1',
                              host_manager_id    => Entity::Component::Physicalhoster0->find()->id);

    my $node = Node->new(node_hostname       => 'AnomalyDetectionTestNode1',
                         service_provider_id => $cluster->id,
                         monitoring_state    => 'up',
                         host_id             => $host->id,
                         node_state          => 'in:'.time(),);

    my $indicator = Entity::Indicator->find(hash => {indicator_oid => '.1.3.6.1.4.1.2021.4.5.0'});

    my $collector_indicator = $mockmonitor->find(
                                  related => 'collector_indicators',
                                  hash    => {indicator_id => $indicator->id},
                              );

    $cm = Entity::Metric::Clustermetric->new(
              clustermetric_service_provider_id      => $cluster->id,
              clustermetric_statistics_function_name => 'sum',
              clustermetric_indicator_id             => $collector_indicator->id,
              clustermetric_service_provider_id      => $cluster->id,
          );
}

sub clustermetric_anomaly {

    $anomaly = Entity::Metric::Anomaly->new(related_metric_id => $cm->id);

    lives_ok {
        my $values = {
            values     => [0..50],
            timestamps => [0..50],
        };

        my $val = $anomaly->computeAnomaly(values => $values);

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

        my $val = $anomaly->computeAnomaly(values => $values);

        if (! defined $val->{value}) {
            die 'computeAnomaly should be defined';
        }

        if ($val->{value} < 10**-2) {
            die 'computeAnomaly should not be close to 0';
        }

    } 'test clustermetric anomaly';

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
    } 'Test anomaly storage'
}


sub anomaly_detector {
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

     } 'Test anomaly detector main loop'
}


sub clean {
    try { Entity::ServiceProvider::remove($cluster); }
    try { Entity::ServiceProvider::remove($cluster); }
    try { $anomaly->remove(); }
}
1;
