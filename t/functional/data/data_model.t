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
use Kanopya::Tools::TimeSerie;
use Kanopya::Tools::TestUtils 'expectedException';

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({
    level=>'DEBUG',
    file=>'data_model.log',
    layout=>'%F %L %p %m%n'
});

use BaseDB;
use Entity::ServiceProvider::Externalcluster;
use Node;
use Entity::Component::MockMonitor;
use Entity::Clustermetric;
use Entity::Combination::AggregateCombination;
use Entity::Combination::NodemetricCombination;

use Entity::DataModel;
use Entity::DataModel::LinearRegression;
use Entity::DataModel::LogarithmicRegression;

use List::MoreUtils;
use List::Util;

use Aggregator;
use Executor;

my $testing = 1;

my $service_provider;
my $external_cluster_mockmonitor;
my $node_1;
my $indic_1;
my $node_data_model;
my $service_data_model;
my $service_data_log_model;
my $comb;
my $cm;

main();

sub main {
    BaseDB->authenticate( login =>'admin', password => 'K4n0pY4' );

    if ($testing == 1) {
        BaseDB->beginTransaction;
    }

    setup();

    logarithmic_regression_configure();
    logarithmic_regression_predict();

    linear_regression_configure ();
    linear_regression_predict();
    test_R_squared();
    select_best_model_operation();

    clean();

    if ($testing == 1) {
        BaseDB->rollbackTransaction;
    }
}

sub clean {
    $service_provider->delete();
    $external_cluster_mockmonitor->delete();
}

sub select_best_model_operation {
    # TODO factorize code

    lives_ok {
        my $executor   = Executor->new();

        my $time_serie = Kanopya::Tools::TimeSerie->new();

        $time_serie->generate(func => 'X + rand(10)',
                              srand => 1,
                              rows => 100,
                              step => 60);

        $time_serie->store();
        $time_serie->linkToMetric( metric => $cm );

        map {$_->delete() } Entity::DataModel->search( hash => { combination_id => $comb->id, });

        $comb->computeDataModel( start_time => time() - 100*60, end_time => time() );

        Kanopya::Tools::Execution->executeAll();

        # Check if datamodel has been created
        my @models = Entity::DataModel->search( hash => {
                             combination_id => $comb->id,
                         });

        if ((scalar @models) != 1) {die 'Just one data model must have been created got:'.(scalar @models)}

        my $model = (pop @models);

        my $pred = $model->predict(start_time      => time() - 10*60,
                                   end_time        => time() + 10*60,
                                   sampling_period => 100,);

        if (! $model->isa('Entity::DataModel::LinearRegression')) {
            die 'Wrong Linear Regresssion';
        }
        $model->delete();
    } 'Select best model is linear regression';

    lives_ok {
        my $time_serie = Kanopya::Tools::TimeSerie->new();

        $time_serie->generate(func => 'log(X)',
                              srand => 1,
                              rows => 100,
                              step => 60,
                              precision => {
                                 X => 0.1
                              });

        $time_serie->store();
        $time_serie->linkToMetric( metric => $cm );

        $comb->computeDataModel( start_time => time() - 100*60, end_time => time() );

        Kanopya::Tools::Execution->executeAll();

        # Check if datamodel has been created
        my @models = Entity::DataModel->search( hash => {
                             combination_id => $comb->id,
                  });

        if ((scalar @models) != 1) {die 'Just one data model must have been created got:'.(scalar @models)}

        my $model = (pop @models);

        my $pred = $model->predict(start_time      => time() - 10*60,
                                   end_time        => time() + 10*60,
                                   sampling_period => 100,);

        $model->delete();

    } 'Select best model is logarithmic regression';
}

sub test_R_squared {
    lives_ok {
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

        my $data;
        my $ea = List::MoreUtils::each_array( @timestamps, @data_values );
        while (my ($ts,$dv) = $ea->()) { $data->{$ts} = $dv; }

        my $pred = $service_data_model->predict(
                                    start_time => 1,
                                    end_time => 10,
                                    sampling_period => 1,
                                );

        my $Rsquared = $service_data_model->computeRSquared( data       => \@data_values,
                                                             data_model => $pred->{values}, );
        if ($Rsquared - 0.974688777619551 > 10**(-5)) {
            die 'Wrong Rsquared computation';
        }
    } 'Linear regression Rsquared';
}

sub logarithmic_regression_predict {
    lives_ok {
        my $timestamps = [1360605540, 1360605550, 1360605560, 1360605570, 1360605580, 1360605590, 1360605600, 1360605610,1360606000,1360607000,];
        my $predictions = $service_data_log_model->predict(timestamps => $timestamps);

        my @expected_values = ('2.28648922262471',
                               '14.2019256162136',
                               '17.415095491243',
                               '19.3503937957755',
                               '20.7396853466509',
                               '21.8242141470061',
                               '22.7139268202061',
                               '23.46826956028',
                               '32.7640981019322',
                               '38.4958739180753',
        );

        my $sum = List::Util::sum (List::MoreUtils::pairwise {abs($a - $b)} @{$predictions->{values}}, @expected_values);

        if ( $sum > 10**(-5) ) {
            die 'Wrong prediction 1 (sum = '.$sum.')';
        }

        my $pair_predictions = $service_data_log_model->predict(timestamps => $timestamps, data_format => 'pair', time_format => 'ms');

        my $ea = List::MoreUtils::each_array( @$timestamps, @expected_values, @$pair_predictions);

        while (my ($ts,$value,$pair) = $ea->()) {
            # Do not compare two floats exactly !
            if ( (($ts*1000) != $pair->[0]) || (($value - $pair->[1]) > 10**(-5))) {
                die 'Wrong linear prediction in pair format or ms format:'.
                    ($ts*1000).' != '.($pair->[0])." OR $value != ".($pair->[1]);
            }
        }

    } 'Logarithmic regression prediction';
}

sub linear_regression_predict {
    lives_ok {

        my $timestamps = [1360605410,1360605430,1360605500,1360605600,1360606000,1360607000,];

        my $predictions = $service_data_model->predict(timestamps => $timestamps);

        my @expected_values = ( '48.7616285668',
                                '41.0947724136',
                                '14.2607758774001',
                                '-24.0735048885998',
                                '-177.410627952599',
                                '-560.753435612598',);

        my $sum = List::Util::sum (List::MoreUtils::pairwise {abs($a - $b)} @{$predictions->{values}}, @expected_values);

        # Do not compare two floats exactly !
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

        $sum = List::Util::sum (List::MoreUtils::pairwise {abs($a - $b)} @{$predictions_2->{values}}, @expected_values_2);

        # Do not compare two floats exactly !
        if ( $sum > 10**(-5) ) {
            die 'Wrong prediction (sum = '.$sum.')';
        }

        my $pair_predictions = $service_data_model->predict(timestamps => $timestamps, data_format => 'pair', time_format => 'ms');

        my $ea = List::MoreUtils::each_array( @$timestamps, @expected_values, @$pair_predictions);

        while (my ($ts,$value,$pair) = $ea->()) {
            # Do not compare two floats exactly !
            if ( (($ts*1000) != $pair->[0]) || (($value - $pair->[1]) > 10**(-5))) {
                die 'Wrong linear prediction in pair format or ms format:'.
                    ($ts*1000).' != '.($pair->[0])." OR $value != ".($pair->[1]);
            }
        }
    } 'Linear regression prediction';
}

sub logarithmic_regression_configure {

    lives_ok{
        my @timestamps = ( 1360605540, 1360605550, 1360605560, 1360605570, 1360605580, 1360605590, 1360605600, 1360605610, );
        my @data_values = ( 5, 10, 15, 18, 20, 23, 25, 26);

        # construct data hash table
        my $data;
        my $ea = List::MoreUtils::each_array( @timestamps, @data_values );
        while (my ($ts,$dv) = $ea->()) { $data->{$ts} = $dv; }

        $service_data_log_model->configure(data => $data);

        my $pp = $service_data_log_model->param_preset->load;
        if ($pp->{a} != 4.96912293408187 || $pp->{b} != 2.28648922262471) {
            die 'Wrong logarithmic regression configuration '.
                ($pp->{a}).' != 4.96912293408187 || '.($pp->{b}).' != 2.28648922262471';
        }

        $service_data_log_model->configure(data => $data, start_time => 1360605545);

        print ($service_data_log_model->label."\n");

        $pp = $service_data_log_model->param_preset->load;
        if ($pp->{a} != 3.80640059030539 || $pp->{b} != 8.3519668674633) {
            die 'Wrong logarithmic regression configuration';
        }

        $service_data_log_model->configure(data => $data, start_time => 1360605535);

        $pp = $service_data_log_model->param_preset->load;
        if ($pp->{a} != 4.96912293408187 || $pp->{b} != 2.28648922262471) {
            die 'Wrong logarithmic regression configuration';
        }
    } 'Logarithmic regression configuration';
}

sub linear_regression_configure {
    lives_ok {
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

        my $data;
        my $ea = List::MoreUtils::each_array( @timestamps, @data_values );
        while (my ($ts,$dv) = $ea->()) { $data->{$ts} = $dv; }

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
    } 'Linear regression configuration'
}

sub setup {

    srand(1);
    $service_provider = Entity::ServiceProvider::Externalcluster->new(
                            externalcluster_name => 'Test Service Provider',
                        );

    $external_cluster_mockmonitor = Entity::ServiceProvider::Externalcluster->new(
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
    $node_1 = Node->new(
                  node_hostname         => 'node_1',
                  service_provider_id   => $service_provider->id,
                  monitoring_state      => 'up',
              );

    # Get indicators
    $indic_1 = Entity::CollectorIndicator->find (
                   hash => {
                       collector_manager_id        => $mock_monitor->id,
                       'indicator.indicator_oid'   => 'Memory/PercentMemoryUsed'
                   }
               );

   # Clustermetric
    $cm = Entity::Clustermetric->new(
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

    lives_ok {
        $node_data_model = Entity::DataModel::LinearRegression->new(
                               node_id        => $node_1->id,
                               combination_id => $ncomb->id,
                           );

        $service_data_model = Entity::DataModel::LinearRegression->new(
                                  combination_id => $comb->id,
                              );

        $service_data_log_model = Entity::DataModel::LogarithmicRegression->new(
                                      combination_id => $comb->id,
                                  );

        expectedException {
            Entity::DataModel::LinearRegression->new(
                combination_id => $ncomb->id,
            );
        } 'Kanopya::Exception', 'Exception NodemetriCombination LinearRegression created without node_id';
    } 'DataModel creation'
}

