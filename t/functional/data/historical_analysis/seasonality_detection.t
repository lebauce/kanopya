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

use Log::Log4perl qw(:easy);
Log::Log4perl -> easy_init({
    level => 'DEBUG',
    file => __FILE__.'.log',
    layout => '%F %L %p %m%n'
});

use Utils::TimeSerieAnalysis;
use Kanopya::Tools::TimeSerie;
use Entity::Metric::Combination::AggregateCombination;
use DataModelSelector;
use Node;
use Entity::CollectorIndicator;
use Entity::Metric::Clustermetric;
use Entity::Component::MockMonitor;
use Entity::ServiceProvider::Externalcluster;
use DataModel;
use Kanopya::Database;

my $path = '/opt/kanopya/t/functional/data/timeserie_data/';
my $path_predict = '/opt/kanopya/t/functional/data/timeserie_predict/';

use constant MODEL_CLASSES   => ['AnalyticRegression::LinearRegression',
                                 'AnalyticRegression::LogarithmicRegression',
                                 'RDataModel::AutoArima'];
main();

sub main {

    Kanopya::Database::authenticate( login =>'admin', password => 'K4n0pY4' );
    Kanopya::Database::beginTransaction;
    get_values_fromCSV();
    get_timeserie_data_fromCSV();
    split_data();
    compute_ACF();
    confidence_autocorrelation();
    detect_peaks();
    detect_periodicity();
    find_seasonality_DSP();
    find_seasonality_ACF();
    find_seasonality();
    forecast();
    Kanopya::Database::rollbackTransaction;
}


sub get_values_fromCSV {

    lives_ok {
        #Historical data
        my $file = $path.'test_values.csv';
        my $data_values = Kanopya::Tools::TimeSerie->getValuesfromCSV('file' => $file, 'sep' => ';');
        #Expected values
        my @expected_values = (315.42, 316.31, 316.50 , 317.56, 318.13);

        if ($#{$data_values}+1 == 5) {
            foreach my $i (0..$#$data_values) {
                if ($data_values->[$i] != $expected_values[$i]) {
                    diag ($data_values->[$i]." != ". $expected_values[$i]);
                    die 'Wrong values from a CSV file with headers';
                }
            }
        }
        else {
            diag ($#{$data_values}+1 .' != 5');
            die 'Wrong values from a CSV file with headers';
        }
    } 'Read values from a CSV file with headers';

}

sub get_timeserie_data_fromCSV {

    lives_ok {
        #Historical data
        my $file = $path.'test_data.csv';
        my $data = Kanopya::Tools::TimeSerie->getTimeserieDatafromCSV('file' => $file, 'sep' => ';');
        #Expected values
        my %expected_values = ( 5901 => 315.42,
                                5902 => 316.31,
                                5903 => 316.50,
                                5904 => 317.56,
                                5905 => 318.13 );

         if (scalar (keys %{$data}) == 5) {
            foreach my $key (keys %{$data}) {
                if ( exists $expected_values{$key}) {
                    if ( $data->{$key} != $expected_values{$key} ) {
                    diag ($data->{$key}." != ". $expected_values{$key});
                    die 'Wrong time serie from a CSV file with headers';
                    }
                }
                else {
                    diag ($key." not in common");
                    die 'Wrong time serie from a CSV file with headers';
                }
            }
        }
        else {
            diag (scalar (keys %{$data}).' != 5');
            die 'Wrong time serie from a CSV file with headers';
        }
    } 'Read a time serie from a CSV file with headers';

}

sub split_data {

    lives_ok {

        #Historical data
        my $file = $path.'test_data.csv';
        my $data = Kanopya::Tools::TimeSerie->getTimeserieDatafromCSV('file' => $file, 'sep' => ';');

        my %temp = %{Utils::TimeSerieAnalysis->splitData('data' => $data)};
        my ($times, $data_values) = ($temp{timestamps_ref}, $temp{values_ref});

        #Expected values
        my @expected_values = ( 315.42, 316.31, 316.50, 317.56, 318.13);

        if ($#{$data_values}+1 == 5) {
            foreach my $i (0..$#$data_values) {
                if ($data_values->[$i] != $expected_values[$i]) {
                    diag ($data_values->[$i]." != ". $expected_values[$i]);
                    die 'Wrong split of a hash table into two arrays';
                }
            }
        }
        else {
            diag ($#{$data_values}+1 .' != 5');
            die 'Wrong split of a hash table into two arrays';
        }

    } 'Split time serie hash table into time stamp array and values array';

}

sub compute_ACF {

    lives_ok {

        #data values
        my $file        = $path.'data_values_co2.csv';
        my $data_values = Kanopya::Tools::TimeSerie->getValuesfromCSV ('file' => $file);

        #Expected values of the acf
        $file = $path.'acf_co2.csv';
        my $expected_values = Kanopya::Tools::TimeSerie->getValuesfromCSV ('file' => $file);

        my $lag = int (($#$data_values+1)/2 + 1);

        my $acf = Utils::TimeSerieAnalysis->computeACF('data_values' => $data_values,'lag'=> $lag);

        #We expect 235 values
        if ($#{$acf}+1 == 235) {
            foreach my $i (0..$#$acf) {
                if ( abs($acf->[$i] - $expected_values->[$i]) > 10**(-5) ) {
                    diag ($acf->[$i]." != ".$expected_values->[$i]);
                    die 'Wrong autocorrelation calculation';
                }
            }
        }
        else {
            diag ($#{$acf}+1 .' != 235');
            die 'Wrong autocorrelation calculation';
        }

    } 'Compute autocorrelation values';
}


sub confidence_autocorrelation {

    lives_ok {

        #data values
        my $file        = $path.'data_values_co2.csv';
        my $data_values = Kanopya::Tools::TimeSerie->getValuesfromCSV ('file' => $file);

        my $IC = Utils::TimeSerieAnalysis->confidenceAutocorrelation('data_values' => $data_values);

        #Test the value of the confidence interval IC
        if (abs($IC - 0.09245003) > 10**(-5)) {
            diag ($IC.' != 0.09245003');
            die 'Wrong confidence autocorrelation calculation';
        }

    } 'Compute confidence autocorrelation';
}

sub detect_peaks {

    lives_ok {

        #The values for which the peaks are detected
        my $file = $path.'acf_co2.csv';
        my $tab  = Kanopya::Tools::TimeSerie->getValuesfromCSV ('file' => $file);

        #The confidence interval
        my $IC = 0.09245003;

        my $peaks = Utils::TimeSerieAnalysis->detectPeaks ('IC' => $IC,'tab' => $tab);

        my @expected_values = (10, 22, 34, 46, 58, 69, 81, 93, 105, 129, 141);

        if ($#{$peaks}+1 == 11) {
            foreach my $i (0..$#$peaks) {
                if ($peaks->[$i] != $expected_values[$i]) {
                    diag ($peaks->[$i]." != ".$expected_values[$i]);
                    die 'Wrong detection of peaks calculation';
                }
            }
        }
        else {
            diag ($#{$peaks}+1 .' != 11');
            die 'Wrong detection of peaks calculation';
        }

    } 'Compute detection of peaks';

}

sub detect_periodicity {

    lives_ok {

        #The values of the autocorrelation function
        my $file = $path.'acf_co2.csv';
        my $acf  = Kanopya::Tools::TimeSerie->getValuesfromCSV ('file' => $file);
        #The positions (array index) of the peaks of the @acf array
        my @peaks = (10, 22, 34, 46, 58, 69, 81, 93, 105, 129, 141);

        #We search for periodic peaks of $peaks[$pos]
        my $pos = 0;

        my ($multiple, $peak)=
            Utils::TimeSerieAnalysis->detectPeriodicity ('pos' => $pos,'acf' => $acf, 'peaks' => \@peaks);

        if ($multiple != 9  || $peak != 12) {
            diag ($multiple.' != 9')          if ($multiple != 9);
            diag ($peak.' != 12')             if ($peak != 12);
            die 'Wrong detection of periodicity of a given peak';
        }
    } 'Detection of periodicity of a given peak';

}

sub find_seasonality_DSP {

    lives_ok {

        #data values
        my $file        = $path.'data_values_co2.csv';
        my $data_values = Kanopya::Tools::TimeSerie->getValuesfromCSV ('file' => $file);
        my $seasonal    = Utils::TimeSerieAnalysis->findSeasonalityDSP('data_values' => $data_values);

        if ( $seasonal != 12 ) {
            diag ($seasonal.' != 12');
            die 'Wrong Calculation of seasonality by using Spectral Density';
        }
    } 'Compute seasonality by using Spectral Density';

}

sub find_seasonality_ACF {

    lives_ok {

        #data values
        my $file = $path.'data_values_co2.csv';
        my $data_values = Kanopya::Tools::TimeSerie->getValuesfromCSV ('file' => $file);

        my $seasons = Utils::TimeSerieAnalysis->findSeasonalityACF('data_values' => $data_values);

        #The expected values of the seasonalities
        my @expected_values  = (12, 23, 35, 47, 70, 82, 94, 106, 130, 142);

        #We expect 10 values
        if ($#{$seasons}+1 == 10) {
            foreach my $i (0..$#$seasons) {
                if ($seasons->[$i] != $expected_values[$i]) {
                    diag ($seasons->[$i]." != ".$expected_values[$i]);
                    die 'Wrong calculation of seasonalities by using autocorrelation';
                }
            }
        }
        else {
            diag ($#{$seasons}+1 .' != 10');
            die 'Wrong calculation of seasonalities by using autocorrelation';

        }
    } 'Compute seasonalities by using autocorrelation';

}

sub find_seasonality {

    lives_ok {

        #The data used for the test
        my $file    = $path.'data_no_seasonality.csv';
        my $seasons = find_seasonality_data('file' => $file, 'sep' => ';');

        #There is no seasonality for this example
        if ($#$seasons+1 != 0) {
            diag($#$seasons+1 .' != 0');
            die 'Wrong calculation of seasonality in the case where it not exists';
        }
    } 'Compute seasonality in the case where it not exists';

    lives_ok {

        #The data used for the test

        my $file = $path.'nhtemp.csv';
        my $seasons = find_seasonality_data('file' => $file, 'sep' => ';');

        #There is no seasonality for this example
        if ($#$seasons+1 != 0) {
            diag($#$seasons+1 .' != 0');
            die 'Wrong calculation of seasonality in the case where it not exists : nhtemp';
        }
    } 'Compute seasonality in the case where it not exists : nhtemp';

    lives_ok {

        #The data used for the test
        my $file = $path.'BJsales.csv';
        my $seasons = find_seasonality_data('file' => $file, 'sep' => ';');

        #There is no seasonality for this example
        if ($#$seasons+1 != 0) {
            diag($#$seasons+1 .' != 0');
            die 'Wrong calculation of seasonality in the case where it not exists : BJsales';
        }
    } 'Compute seasonality in the case where it not exists : BJsales';

    lives_ok {

        #The data used for the test
        my $file = $path.'data_seasonality=6.csv';
        my $seasons = find_seasonality_data('file' => $file, 'sep' => ';');

        my $expected_value = 6;

        if ($#$seasons+1 != 1 || $seasons->[0] != $expected_value) {
            diag($#$seasons+1 .' != 1') if ($#$seasons+1 != 1);
            diag($seasons->[0].' !=6')  if ($seasons->[0] != $expected_value);
            die('Wrong calculation of seasonalities when season=6');
        }

    } 'Compute seasonalities when season=6';

    lives_ok {

        # The data used for the test
        my $file    = $path.'data_seasonality=10.csv';
        my $seasons = find_seasonality_data('file' => $file, 'sep' => ';');

        my $expected_value = 10;

        if ( $#{$seasons}+1 != 1 || $seasons->[0] != $expected_value ) {
            diag($#$seasons+1 .' != 1') if ($#$seasons+1 != 1);
            diag($seasons->[0].' !=10') if ($seasons->[0] != $expected_value);
            die 'Wrong calculation of seasonalities when Season=10';
        }
    } 'Compute seasonalities when Season=10';

    lives_ok {

        #The data used for the test
        my $file = $path.'lynx.csv';
        my $seasons = find_seasonality_data('file' => $file, 'sep' => ';');
        my @expected_values = (10, 38);

        if ($#{$seasons}+1 == 2) {
            foreach my $i (0..$#$seasons) {
                if ($seasons->[$i] != $expected_values[$i]) {
                    diag ($seasons->[$i]." != ". $expected_values[$i]);
                    die 'Wrong calculation of seasonalities when Season=10 : lynx';
                }
            }
        }
        else {
            diag ($#{$seasons}+1 .' != 2');
            die 'Wrong calculation of seasonalities when Season=10 : lynx';
        }

    } 'Compute seasonalities when Season=10 : lynx';

    lives_ok {

        #The data used for the test
        my $file = $path.'data_seasonality=53.csv';
        my $seasons = find_seasonality_data('file' => $file, 'sep' => ';');
        my $expected_value = 53;

        #We have only one seasonality (equal to 53)
        if ($#$seasons+1 != 1 || $seasons->[0] != $expected_value) {
            diag($#$seasons+1 . ' != 1')    if ($#$seasons+1 != 1);
            diag($seasons->[0]. ' != 53')   if ($seasons->[0] != $expected_value);
            die 'Wrong calculation of seasonalities when Season=53';
        }

    } 'Compute seasonalities when Season=53';

    lives_ok {

        #The data used for the test
        my $file = $path.'sin_additive.csv';
        my $seasons = find_seasonality_data('file' => $file, 'sep' => ';');

        #The expected values of the seasonalities
        my $expected_value = 10;

        if ( $#{$seasons}+1 != 1 || $seasons->[0] != $expected_value ) {
            diag($#$seasons+1 . ' != 1')    if ($#$seasons+1 != 1);
            diag($seasons->[0]. ' != 10')   if ($seasons->[0] != $expected_value);
            die 'Wrong calculation of additive seasonalities : sinus function';
        }
    } 'Compute additive seasonalities : sinus function';

    lives_ok {

        #The data used for the test
        my $file = $path.'data_co2.csv';
        my $seasons = find_seasonality_data('file' => $file, 'sep' => ';');

        #The expected values of the seasonalities
        my $expected_value = 12;

        if ( $#{$seasons}+1 != 1 || $seasons->[0] != $expected_value ) {
            diag($#$seasons+1 . ' != 1')    if ($#$seasons+1 != 1);
            diag($seasons->[0]. ' != 12')   if ($seasons->[0] != $expected_value);
            die 'Wrong calculation of additive seasonalities : co2';
        }
    } 'Compute additive seasonalities : co2';

    lives_ok {

        #The data used for the test
        my $file = $path.'data_seasonality=132.csv';
        my $seasons = find_seasonality_data('file' => $file, 'sep' => ';');

        my @expected_values = (132,3);

        if ($#{$seasons}+1 == 2) {
            foreach my $i (0..$#$seasons) {
                if ($seasons->[$i] != $expected_values[$i]) {
                    diag ($seasons->[$i]." != ". $expected_values[$i]);
                    die 'Wrong calculation of seasonalities when there is noise : sinus';
                }
            }
        }
        else {
            diag ($#{$seasons}+1 .' != 2');
            die 'Wrong calculation of seasonalities when there is noise : sinus';
        }
    } 'Compute seasonalities when there is noise : sinus';

    lives_ok {

        #The data used for the test
        my $file = $path.'sin_no_noise.csv';
        my $seasons = find_seasonality_data('file' => $file, 'sep' => ';');

        my @expected_values = (130,125);

        if ($#{$seasons}+1 == 2) {
            foreach my $i (0..$#$seasons) {
                if ($seasons->[$i] != $expected_values[$i]) {
                    diag ($seasons->[$i]." != ". $expected_values[$i]);
                    die 'Wrong calculation of seasonalities when there is no noise : sinus';
                }
            }
        }
        else {
            diag ($#{$seasons}+1 .' != 2');
            die 'Wrong calculation of seasonalities when there is no noise : sinus';
        }
    } 'Compute seasonalities when there is no noise : sinus';


    lives_ok {

        #The data used for the test
        my $file = $path.'sin_noise.csv';
        my $seasons = find_seasonality_data('file' => $file, 'sep' => ';');

        my @expected_values = (13, 12);

        if ($#{$seasons}+1 == 2) {
            foreach my $i (0..$#$seasons) {
                if ($seasons->[$i] != $expected_values[$i]) {
                    diag ($seasons->[$i]." != ". $expected_values[$i]);
                    die 'Wrong calculation of seasonalities when there is noise : sinus (2)';
                }
            }
        }
        else {
            diag ($#{$seasons}+1 .' != 2');
            die 'Wrong calculation of seasonalities when there is noise : sinus (2)';
        }
    } 'Compute seasonalities when there is noise : sinus (2)';

    lives_ok {

        #The data used for the test
        my $file = $path.'AirPassengers.csv';
        my $seasons = find_seasonality_data('file' => $file, 'sep' => ';');
        my $expected_value = 12;

        if ( $#{$seasons}+1 != 1 || $seasons->[0] != $expected_value ) {
            diag($#$seasons+1 . ' != 1')    if ($#$seasons+1 != 1);
            diag($seasons->[0]. ' != 12')   if ($seasons->[0] != $expected_value);
            die 'Wrong calculation of multiplicative seasonalities : Air Passengers';
        }
    } 'Compute multiplicative seasonalities : AirPassengers';


    lives_ok {

        #The data used for the test
        my $file = $path.'multi_seasonal.csv';
        my $seasons = find_seasonality_data('file' => $file, 'sep' => ';');

        my @expected_values = (38,11);

        if ($#{$seasons}+1 == 2) {
            foreach my $i (0..$#$seasons) {
                if ($seasons->[$i] != $expected_values[$i]) {
                    diag ($seasons->[$i]." != ". $expected_values[$i]);
                    die 'Wrong calculation of seasonalities when there is two seasonalities';
                }
            }
        }
        else {
            diag ($#{$seasons}+1 .' != 2');
            die 'Wrong calculation of seasonalities when there is two seasonalities';
        }
    } 'Compute multiple seasonalities';

   lives_ok {

        #The data used for the test
        my $file = $path.'multi_seasonal_2.csv';
        my $seasons = find_seasonality_data('file' => $file, 'sep' => ';');

        my @expected_values = (114,10);

        if ($#{$seasons}+1 == 2) {
            foreach my $i (0..$#$seasons) {
                if ($seasons->[$i] != $expected_values[$i]) {
                    diag ($seasons->[$i]." != ". $expected_values[$i]);
                    die 'Wrong calculation of seasonalities when there is two seasonalities';
                }
            }
        }
        else {
            diag ($#{$seasons}+1 .' != 2');
            die 'Wrong calculation of seasonalities when there is two seasonalities';
        }

    } 'Compute multiple seasonalities (2)';

    lives_ok {

        #The data used for the test
        my $file = $path.'multi_seasonal_2_times2.csv';
        my $seasons = find_seasonality_data('file' => $file, 'sep' => ';');

        my @expected_values = (114,10);

        if ($#{$seasons}+1 == 2) {
            foreach my $i (0..$#$seasons) {
                if ($seasons->[$i] != $expected_values[$i]) {
                    diag ($seasons->[$i]." != ". $expected_values[$i]);
                    die 'Wrong calculation of seasonalities when there is two seasonalities';
                }
            }
        }
        else {
            diag ($#{$seasons}+1 .' != 2');
            die 'Wrong calculation of seasonalities when there is two seasonalities';
        }

    } 'Compute multiple seasonalities (3)';

   lives_ok {

        #The data used for the test
        my $file = $path.'downward_trend.csv';
        my $seasons = find_seasonality_data('file' => $file, 'sep' => ';');

        my $expected_value = 2;


        if ( $#{$seasons}+1 != 1 || $seasons->[0] != $expected_value ) {
            diag($#$seasons+1 . ' != 1')    if ($#$seasons+1 != 1);
            diag($seasons->[0]. ' != 2')    if ($seasons->[0] != $expected_value);
            die 'Wrong calculation of seasonalities with downward trend';
        }
    } 'Compute seasonalities with downward trend';

   lives_ok {

        #The data used for the test
        my $file = $path.'sin_positive_seasonality=31.csv';
        my $seasons = find_seasonality_data('file' => $file, 'sep' => ';');

        my @expected_values = (31,29);

        if ($#{$seasons}+1 == 2) {
            foreach my $i (0..$#$seasons) {
                if ($seasons->[$i] != $expected_values[$i]) {
                    diag ($seasons->[$i]." != ". $expected_values[$i]);
                    die 'Wrong calculation of seasonalities when there is only positive values : sinus';
                }
            }
        }
        else {
            diag ($#{$seasons}+1 .' != 2');
            die 'Wrong calculation of seasonalities when there is only positive values : sinus';
        }
    } 'Compute seasonalities when there is only positive values : sinus';

   lives_ok {

        #The data used for the test
        my $file = $path.'sin_positive_seasonality=31_times7_times4.csv';
        my $seasons = find_seasonality_data('file' => $file, 'sep' => ';');
        my @expected_values = (222,32);

        if ($#{$seasons}+1 == 2) {
            foreach my $i (0..$#$seasons) {
                if ($seasons->[$i] != $expected_values[$i]) {
                    diag ($seasons->[$i]." != ". $expected_values[$i]);
                    die 'Wrong calculation of multiple seasonalities when there is only positive values :
                         sinus';
                }
            }
        }
        else {
            diag ($#{$seasons}+1 .' != 2');
            die 'Wrong calculation of multiple seasonalities when there is only positive values : sinus';
        }
    } 'Compute multiple seasonalities when there is only positive values : sinus';

    lives_ok {

        #The data used for the test
        my $file = $path.'sin_positive_seasonality=31_times7_times3.csv';
        my $seasons = find_seasonality_data('file' => $file, 'sep' => ';');

        my @expected_values = (222,42);

        if ($#{$seasons}+1 == 2) {
            foreach my $i (0..$#$seasons) {
                if ($seasons->[$i] != $expected_values[$i]) {
                    diag ($seasons->[$i]." != ". $expected_values[$i]);
                    die 'Wrong calculation of multiple seasonalities when there is only positive values :
                         sinus (2)';
                }
            }
        }
        else {
            diag ($#{$seasons}+1 .' != 2');
            die 'Wrong calculation of multiple seasonalities when there is only positive values : sinus (2)';
        }
    } 'Compute multiple seasonalities when there is only positive values : sinus (2)';


    lives_ok {

        #The data used for the test
        my $file = $path.'complexSeasonality.csv';
        my $seasons = find_seasonality_data('file' => $file, 'sep' => ';');

        my $expected_value = 6;

        if ( $#{$seasons}+1 != 1 || $seasons->[0] != $expected_value ) {
            diag($#$seasons+1 . ' != 1')    if ($#$seasons+1 != 1);
            diag($seasons->[0]. ' != 6')    if ($seasons->[0] != $expected_value);
            die 'Wrong calculation of complex seasonalities';
        }
    } 'Complex seasonalities : sinus + cosinus';


    lives_ok {

        #The data used for the test
        my $file = $path.'complexSeasonality+trend+level.csv';
        my $seasons = find_seasonality_data('file' => $file, 'sep' => ';');

        my $expected_value = 6;

        if ( $#{$seasons}+1 != 1 || $seasons->[0] != $expected_value ) {
            diag($#$seasons+1 . ' != 1')    if ($#$seasons+1 != 1);
            diag($seasons->[0]. ' != 6')    if ($seasons->[0] != $expected_value);
            die 'Wrong calculation of complex seasonalities with trend and level';
        }
    } 'Complex seasonalities (sinus + cosinus) with trend and level';

}

sub find_seasonality_data{
    my %args = @_;
    my $data    = Kanopya::Tools::TimeSerie->getTimeserieDatafromCSV('file' => $args{'file'},
                                                                     'sep'  => $args{'sep'}
                                                                    );
    my $values  = Utils::TimeSerieAnalysis->splitData('data' => $data)->{values_ref};
    my $seasons = Utils::TimeSerieAnalysis->findSeasonality('data' => $values);

    return $seasons;
}


sub forecast {

    my ($service_provider, $mock_monitor) = setup();
    my $name_func = 'sum';

    lives_ok {
        my $t = 1364897079;
        my %prec = ( 'X' => 0.1);
        my $cm = createCombinationMetric ('service_provider' => $service_provider,
                                          'mock_monitor'     => $mock_monitor,
                                          'name_func'        => $name_func,
                                          'window_time'      => 20000);

        my $comb = linkTimeSerietoAggregateCombination ('cm'               => $cm,
                                                        'func'             => "sin(X)",
                                                        'season'           => { X => 10 },
                                                        'precision'        => \%prec,
                                                        'time'             => $t,
                                                        'rows'             => 8000,
                                                        'service_provider' => $service_provider);


        my $timeserie = $comb->evaluateTimeSerie(start_time => $t-8000+1,
                                                 stop_time  => $t);


        my $args = DataModelSelector->autoPredictData(timeserie             => $timeserie,
                                                      predict_end_tstamps   => $t+8500,
                                                      predict_start_tstamps => $t+1,
                                                      model_list            => MODEL_CLASSES);

        if ($args->{data_model} ne 'DataModel::RDataModel::AutoArima') {
            die 'Wrong data model got <' . $args->{data_model}
                . '> expect <DataModel::RDataModel::AutoArima>';
        }

        my $timestamps = $args->{'timestamps'};
        my $prediction = $args->{'values'};

        my $file = $path_predict.'predict_season=10.csv';
        my $expected_values = Kanopya::Tools::TimeSerie->getTimeserieDatafromCSV('file' => $file, 'sep' => ';');

        if (($#$timestamps) == (scalar keys(%{$expected_values}))) {
            foreach my $i (0..$#$timestamps) {
                if (abs($prediction->[$i] - $expected_values->{$timestamps->[$i]})> 10**(-5)) {
                    diag ($prediction->[$i]." != ". $expected_values->{$timestamps->[$i]});
                    die 'Wrong prediction when season=10 and i='.$i;
                }
            }
        }
        else {
            diag (($#$timestamps) .' != '. (scalar keys(%{$expected_values})));
            die 'Wrong prediction when season=10';
        }

    } 'Prediction when Season=10';

    lives_ok {

        my $t = 1362151970;
        my %prec = ( 'X' => 0.1 );
        my $cm = createCombinationMetric ('service_provider' => $service_provider,
                                          'mock_monitor'     => $mock_monitor,
                                          'name_func'        => $name_func,
                                          'window_time'      => 1200);

        my $comb = linkTimeSerietoAggregateCombination ('cm'               => $cm,
                                                        'func'             => "sin(X)",
                                                        'season'           => {X => 53},
                                                        'precision'        => \%prec,
                                                        'rows'             => 300,
                                                        'time'             => $t,
                                                        'service_provider' => $service_provider);

        my $timeserie = $comb->evaluateTimeSerie(start_time => $t-250,
                                                 stop_time  => $t);

        my $args = DataModelSelector->autoPredictData(timeserie => $timeserie,
                                                      predict_start_tstamps => $t+1,
                                                      predict_end_tstamps   => $t+320,
                                                      model_list            => MODEL_CLASSES);
        my $timestamps = $args->{'timestamps'};
        my $prediction = $args->{'values'};

        if ($args->{data_model} ne 'DataModel::RDataModel::AutoArima') {
            die 'Wrong data model got <' . $args->{data_model}
                . '> expect <DataModel::RDataModel::AutoArima>';
        }

        my $file = $path_predict.'predict_season=53.csv';
        my $expected_values = Kanopya::Tools::TimeSerie->getTimeserieDatafromCSV('file' => $file, 'sep' => ';');

        if (($#$timestamps+1) == (scalar keys(%{$expected_values}))) {
            foreach my $i (0..$#$timestamps) {
                if (abs($prediction->[$i] - $expected_values->{$timestamps->[$i]})> 10**(-5)) {
                    diag ($prediction->[$i]." != ". $expected_values->{$timestamps->[$i]});
                    die 'Wrong prediction when season=53';
                }
            }
        }
        else {
            diag (($#$timestamps+1) .' != '. (scalar keys(%{$expected_values})));
            die 'Wrong prediction when season=53';
        }
    } 'Prediction when Season=53';

    lives_ok {
        my $t = 1362151970;
        my %prec = ( 'X' => 0.1 );
        my $cm = createCombinationMetric ('service_provider' => $service_provider,
                                          'mock_monitor'     => $mock_monitor,
                                          'name_func'        => $name_func,
                                          'window_time'      => 5000);

        my $comb = linkTimeSerietoAggregateCombination ('cm'               => $cm,
                                                        'func'             => "5*sin(2*3.14*X)+X",
                                                        'precision'        => \%prec,
                                                        'time'             => $t,
                                                        'rows'             => 5000,
                                                        'service_provider' => $service_provider);

        my $timeserie = $comb->evaluateTimeSerie(start_time => $t-5000,
                                                 stop_time  => $t);

        my $args = DataModelSelector->autoPredictData(timeserie => $timeserie,
                                                      predict_start_tstamps => $t+1,
                                                      predict_end_tstamps   => $t+5500,
                                                      model_list            => MODEL_CLASSES);

        my $timestamps = $args->{'timestamps'};
        my $prediction = $args->{'values'};

        if ($args->{data_model} ne 'DataModel::AnalyticRegression::LinearRegression') {
            die 'Wrong data model got <' . $args->{data_model}
                . '> expect <DataModel::AnalyticRegression::LinearRegression>';
        }

        my $file = $path_predict.'predict_season_additive.csv';
        my $expected_values = Kanopya::Tools::TimeSerie->getTimeserieDatafromCSV(
                                  'file' => $file,
                                  'sep' => ';'
                              );

        if (($#$timestamps+1) == (scalar keys(%{$expected_values}))) {
            foreach my $i (0..$#$timestamps) {
                if (abs($prediction->[$i] - $expected_values->{$timestamps->[$i]})> 10**(-5)) {
                    diag ($prediction->[$i]." != ". $expected_values->{$timestamps->[$i]});
                    die 'Wrong prediction with additive seasonalities';
                }
            }
        }
        else {
            diag (($#$timestamps+1) .' != '. (scalar keys(%{$expected_values})));
            die 'Wrong prediction with additive seasonalities';
        }
    } 'Prediction with additive seasonalities';


    lives_ok {
        my $t = 1362151970;
        my %prec = ( 'X' => 3 );
        my $cm = createCombinationMetric ('service_provider' => $service_provider,
                                          'mock_monitor'     => $mock_monitor,
                                          'name_func'        => $name_func,
                                          'window_time'      => 1200);

        my $comb = linkTimeSerietoAggregateCombination ('cm'               => $cm,
                                                        'func'             => "5*sin(2*3.14*X)+0.05*rand(50)",
                                                        'srand'            => 1,
                                                        'rows'             => 500,
                                                        'precision'        => \%prec,
                                                        'time'             => $t,
                                                        'service_provider' => $service_provider);

        my $timeserie = $comb->evaluateTimeSerie(start_time => $t-300+1,
                                                 stop_time  => $t);

        my $args = DataModelSelector->autoPredictData(timeserie => $timeserie,
                                                      predict_start_tstamps => $t,
                                                      predict_end_tstamps   => $t+350,
                                                      model_list            => MODEL_CLASSES);

        my $timestamps = $args->{'timestamps'};
        my $prediction = $args->{'values'};

        my $file = $path_predict.'predict_noise.csv';
        my $expected_values = Kanopya::Tools::TimeSerie->getTimeserieDatafromCSV('file' => $file, 'sep' => ';');

        if (($#$timestamps+1) == (scalar keys(%{$expected_values}))) {
            foreach my $i (0..$#$timestamps) {
                if (abs($prediction->[$i] - $expected_values->{$timestamps->[$i]})> 10**(-5)) {
                    diag ($prediction->[$i]." != ". $expected_values->{$timestamps->[$i]});
                    die 'Wrong prediction when there is noise : sinus';
                }
            }
        }
        else {
            diag (($#$timestamps+1) .' != '. (scalar keys(%{$expected_values})));
            die 'Wrong prediction when there is noise : sinus';
        }
    } 'Prediction when there is noise : sinus';


   lives_ok {
        my $t = 1364921543;
        my %prec = ( 'X' => 0.5 );
        my $cm = createCombinationMetric ('service_provider' => $service_provider,
                                          'mock_monitor'     => $mock_monitor,
                                          'name_func'        => $name_func,
                                          'window_time'      => 1200);

        my $comb = linkTimeSerietoAggregateCombination ('cm'               => $cm,
                                                        'func'             => "50*sin(2*3.14*X)+(400-X)",
                                                        'rows'              => 250,
                                                        'precision'        => \%prec,
                                                        'time'             => $t,
                                                        'service_provider' => $service_provider);

        my $timeserie = $comb->evaluateTimeSerie(start_time => $t-250+1,
                                                 stop_time  => $t);

        my $args = DataModelSelector->autoPredictData(timeserie             => $timeserie,
                                                      predict_start_tstamps => $t+1,
                                                      predict_end_tstamps   => $t+300,
                                                      model_list            => MODEL_CLASSES);

        my $timestamps = $args->{'timestamps'};
        my $prediction = $args->{'values'};

        if ($args->{data_model} ne 'DataModel::RDataModel::AutoArima') {
            die 'Wrong data model got <' . $args->{data_model}
                . '> expect <DataModel::RDataModel::AutoArima>';
        }

        my $file = $path_predict.'predict_downward_trend.csv';
        my $expected_values = Kanopya::Tools::TimeSerie->getTimeserieDatafromCSV('file' => $file, 'sep' => ';');

        if (($#$timestamps+1) == (scalar keys(%{$expected_values}))) {
            foreach my $i (0..$#$timestamps) {
                if (abs($prediction->[$i] - $expected_values->{$timestamps->[$i]})> 10**(-3)) {
                    diag ("index <$i>".$prediction->[$i]." != ". $expected_values->{$timestamps->[$i]});
                    die 'Wrong prediction with downward trend';
                }
            }
        }
        else {
            diag (($#$timestamps+1) .' != '. (scalar keys(%{$expected_values})));
            die 'Wrong prediction with downward trend';
        }

    } 'Prediction with downward trend';

}

sub setup {
    my $service_provider = Entity::ServiceProvider::Externalcluster->new(
                                           externalcluster_name => 'Service Provider Test 4',);

    my $external_cluster_mockmonitor = Entity::ServiceProvider::Externalcluster->new(
                                           externalcluster_name => 'Monitor Test 4',);

    my $mock_monitor = Entity::Component::MockMonitor->new(
                                           service_provider_id => $external_cluster_mockmonitor->id,);

    $service_provider->addManager(manager_id      => $mock_monitor->id,
                                  manager_type    => 'CollectorManager',
                                  no_default_conf => 1,
                                 );
    return ($service_provider, $mock_monitor);
}

sub createCombinationMetric {
    my %args = @_;
    my $service_provider = $args{'service_provider'};
    my $mock_monitor     = $args{'mock_monitor'};
    my $name_func        = $args{'name_func'};
    my $window_time      = $args{'window_time'};

    # Get indicators
    my $indic = Entity::CollectorIndicator->find (
                                                  hash => {
                                                   collector_manager_id        => $mock_monitor->id,
                                                   'indicator.indicator_oid'   => 'Memory/PercentMemoryUsed'
                                                    }
                                                  );

   # Clustermetric
    my $cm = Entity::Metric::Clustermetric->new(
                 clustermetric_service_provider_id      => $service_provider->id,
                 clustermetric_indicator_id             => ($indic->id),
                 clustermetric_statistics_function_name => $name_func,
                 clustermetric_window_time              => $window_time
             );

    return $cm;

}

sub linkTimeSerietoAggregateCombination {
    my %args = @_;
    my $time_serie = Kanopya::Tools::TimeSerie->new();
    #get on parameter args func rows and step

    $time_serie->generate(func      => $args{'func'},
                          srand     => $args{'srand'},
                          rows      => $args{'rows'},
                          step      => $args{'step'},
                          precision => $args{'precision'},
                          season    => $args{'season'},
                          'time'    => $args{'time'}
                          );

    $time_serie->store();
    $time_serie->linkToMetric( metric => $args{'cm'} );

    # Combination
    my $comb = Entity::Metric::Combination::AggregateCombination->new(
                   service_provider_id           =>  $args{'service_provider'}->id,
                   aggregate_combination_formula => 'id'.($args{'cm'}->id)
               );
    return $comb;
}
