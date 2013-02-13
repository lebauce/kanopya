#!/usr/bin/perl -w

=head1 SCOPE

Data Model

=head1 PRE-REQUISITE

=cut

use strict;
use warnings;
use Test::More 'no_plan';
use Test::Exception;
use Data::Dumper;
use Kanopya::Tools::Execution;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({
    level=>'DEBUG',
    file=>'data_model.log',
    layout=>'%F %L %p %m%n'
});

use Administrator;
use Entity::ServiceProvider::Outside::Externalcluster;
use Externalnode;
use Entity::Connector::MockMonitor;
use Entity::Clustermetric;
use Entity::Combination::AggregateCombination;
use Entity::Combination::NodemetricCombination;

use Entity::DataModel;
use Entity::DataModel::LinearRegression;
use List::MoreUtils;
use List::Util;

use Aggregator;
use Executor;

my $testing = 0;

my $service_provider;
my $external_cluster_mockmonitor;
my $node_1;
my $indic_1;
my $node_data_model;
my $service_data_model;
my $comb;

my @timestamps = ( 1360605400,
                   1360605410,
                   1360605420,
                   1360605430,
                   1360605440,);

my @data_values = ( 57.743673592,
                    42.898686612,
                    45.779966765,
                    36.385597934,
                    41.833077548,);

# construct data hash table
my $data;
my $ea = List::MoreUtils::each_array( @timestamps, @data_values );
while (my ($ts,$dv) = $ea->()) { $data->{$ts} = $dv; }

main();

sub main {
    Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
    my $adm = Administrator->new;

    if ($testing == 1) {
        $adm->beginTransaction;
    }

    setup();

    test_configure();
    test_predict();
    test_R_squared();
    test_operation_execute();

    clean();

    if ($testing == 1) {
        $adm->rollbackTransaction;
    }
}

sub clean {
    $service_provider->delete();
    $external_cluster_mockmonitor->delete();
}

sub test_operation_execute {
    lives_ok {
        my $aggregator = Aggregator->new();
        my $executor   = Executor->new();

        my $start_time = time();
        my $end_time   = $start_time + 60;

        while (time() < $end_time) {
            $aggregator->update();
            sleep(3);
        }

        $comb->computeDataModel( start_time => $start_time, end_time => $end_time );
        Kanopya::Tools::Execution->executeAll();

        # Check if datamodel has been created
        my $data_model = Entity::DataModel->find( hash => {
                             combination_id => $comb->id,
                             start_time     => $start_time,
                             end_time       => $end_time,
                         });

    } 'Test select DataModel creation from combination via operation';
}

sub test_R_squared {
    lives_ok {
        my ($ts, $data_model) = $service_data_model->predict(
                                    start_time => 1,
                                    end_time => 10,
                                    sampling_period => 1,
                                );

        my $Rsquared = $service_data_model->computeRSquared( data       => \@data_values,
                                                             data_model => $data_model, );
        if ($Rsquared - 0.974688777619551 > 10**(-5)) {
            die 'Wrong Rsquared computation';
        }
    } 'Test linear regression Rsquared';
}

sub test_predict {
    lives_ok {

        my $timestamps = [1360605410,1360605430,1360605500,1360605600,1360606000,1360607000,];

        my $predictions = $service_data_model->predict(timestamps => $timestamps);

        my @expected_values = ( '48.7616285668',
                                '41.0947724136',
                                '14.2607758774001',
                                '-24.0735048885998',
                                '-177.410627952599',
                                '-560.753435612598',);

        my $sum = List::Util::sum (List::MoreUtils::pairwise {abs($a - $b)} @{$predictions}, @expected_values);

        if ( $sum > 10**(-5) ) {
            die 'Wrong prediction 1 (sum = '.$sum.')';
        }

        my $predictions_2 = $node_data_model->predict( start_time      => 1360605400,
                                                       end_time        => 1360606400,
                                                       sampling_period => 100,);

        my @expected_values_2 = ( '48.2011724483333',
                                  '15.6357290583334',
                                  '-16.9297143316665',
                                  '-49.4951577216664',
                                  '-82.0606011116663',
                                  '-114.626044501666',
                                  '-147.191487891666',
                                  '-179.756931281666',
                                  '-212.322374671666',
                                  '-244.887818061666',
                                  '-277.453261451666',);

        $sum = List::Util::sum (List::MoreUtils::pairwise {abs($a - $b)} @{$predictions_2}, @expected_values_2);

        if ( $sum > 10**(-5) ) {
            die 'Wrong prediction (sum = '.$sum.')';
        }
    } 'Test linear regression prediction';
}

sub test_configure {

    lives_ok {
        $service_data_model->configure(data => $data);
        my $pp = $service_data_model->param_preset->load;

        if ($pp->{a} != -0.383342807659999 &&
            $pp->{b} != 52.5950566434 &&
            $pp->{rSquared} != 0.583983776748798) {

            print ($pp->{a}.' != -0.383342807659999'."\n");
            print ($pp->{b}.' != 52.5950566434'."\n");
            print ($pp->{rSquared}.' != 0.583983776748798'."\n");
            die 'Wrong linear regretion configuration 1';
        }

        $node_data_model->configure(
            data => $data,
            start_time => 1360605410,
            end_time  => 1360605430,
        );

        $pp = $node_data_model->param_preset->load;

        if ($pp->{a} != 0.325654433899999 &&
            $pp->{b} != 44.9446281093333 &&
            $pp->{rSquared} != 0.457851461964588) {

            print ($pp->{a}.' != -0.325654433899999'."\n");
            print ($pp->{b}.' != 44.9446281093333'."\n");
            print ($pp->{rSquared}.' != 0.457851461964588'."\n");
            die 'Wrong linear regretion configuration 1';
        }
    } 'Test linear regression configuration'
}

sub setup {

    srand(1);
    $service_provider = Entity::ServiceProvider::Outside::Externalcluster->new(
                            externalcluster_name => 'Test Service Provider',
                        );

    $external_cluster_mockmonitor = Entity::ServiceProvider::Outside::Externalcluster->new(
                                        externalcluster_name => 'Test Monitor',
                                    );

    my $mock_monitor = Entity::Connector::MockMonitor->new(
                           service_provider_id => $external_cluster_mockmonitor->id,
                       );

    $service_provider->addManager(
        manager_id      => $mock_monitor->id,
        manager_type    => 'collector_manager',
        no_default_conf => 1,
    );

    # Create node 1
    $node_1 = Externalnode->new(
                  externalnode_hostname => 'node_1',
                  service_provider_id   => $service_provider->id,
                  externalnode_state    => 'up',
              );

    # Get indicators
    $indic_1 = Entity::CollectorIndicator->find (
                   hash => {
                       collector_manager_id        => $mock_monitor->id,
                       'indicator.indicator_oid'   => 'Memory/PercentMemoryUsed'
                   }
               );

   # Clustermetric
    my $cm = Entity::Clustermetric->new(
                 clustermetric_service_provider_id      => $service_provider->id,
                 clustermetric_indicator_id             => ($indic_1->id),
                 clustermetric_statistics_function_name => 'sum',
                 clustermetric_window_time              => '1200',
             );

    # Combination
    $comb = Entity::Combination::AggregateCombination->new(
                service_provider_id           =>  $service_provider->id,
                aggregate_combination_formula => 'id'.($cm->id),
            );

    #  Nodemetric combination
    my $ncomb = Entity::Combination::NodemetricCombination->new(
                    service_provider_id            => $service_provider->id,
                    nodemetric_combination_formula => 'id'.($indic_1->id),
                );

#    my $temp = Entity::DataModel->new(combination_id => $comb->id);

    $node_data_model = Entity::DataModel::LinearRegression->new(
                           node_id        => $node_1->id,
                           combination_id => $ncomb->id,
                       );

    $service_data_model = Entity::DataModel::LinearRegression->new(
                              combination_id => $comb->id,
                          );
}
