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
use Utils::TimeSerieAnalysis;
use Kanopya::Tools::TimeSerie;

use Log::Log4perl qw(:easy);

Log::Log4perl -> easy_init({
    level => 'DEBUG',
    file => 'seasonality_detection.log',
    layout => '%F %L %p %m%n'
});

use BaseDB;

my $path = '/opt/kanopya/t/functional/data/timeserie_data/';

main();

sub main {

    BaseDB -> authenticate( login =>'admin', password => 'K4n0pY4' );
    data_model_split_data();
    data_model_compute_ACF();
    data_model_confidence_autocorrelation();
    data_model_detect_peaks();
    data_model_detect_periodicity();
    data_model_find_seasonality_DSP();
    data_model_find_seasonality_ACF();
    data_model_find_seasonality();
}

sub data_model_split_data {

    lives_ok {

        #Historical data
        my $file = $path.'test_split_data.csv';
        my $data = Kanopya::Tools::TimeSerie->getTimeserieDatafromCSV('file' => $file, 'sep' => ';');

        my ($times, $data_values) = Utils::TimeSerieAnalysis->splitData('data' => $data);

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

sub data_model_compute_ACF {

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


sub data_model_confidence_autocorrelation {

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

sub data_model_detect_peaks {

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

sub data_model_detect_periodicity {

    lives_ok {

        #The values of the autocorrelation function
        my $file = $path.'acf_co2.csv';
        my $acf  = Kanopya::Tools::TimeSerie->getValuesfromCSV ('file' => $file);
        #The positions (array index) of the peaks of the @acf array
        my @peaks = (10, 22, 34, 46, 58, 69, 81, 93, 105, 129, 141);

        #We search for periodic peaks of $peaks[$pos]
        my $pos = 0;

        my ($multiple, $min_max, $peak)=
        Utils::TimeSerieAnalysis->detectPeriodicity ('pos' => $pos,'acf' => $acf, 'peaks' => \@peaks);

        if ($multiple != 9 || abs ($min_max - 0.349859183) > 10**(-5) || $peak != 12) {
            diag ($multiple.' != 9')          if ($multiple != 9);
            diag ($min_max.' != 0.349859183') if (abs($min_max - 0.349859183) > 10**(-5));
            diag ($peak.' != 12')             if ($peak != 12);
            die 'Wrong detection of periodicity of a given peak';
        }
    } 'Detection of periodicity of a given peak';

}

sub data_model_find_seasonality_DSP {

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

sub data_model_find_seasonality_ACF {

    lives_ok {

        #data values
        my $file = $path.'data_values_co2.csv';
        my $data_values = Kanopya::Tools::TimeSerie->getValuesfromCSV ('file' => $file);

        my $seasons = Utils::TimeSerieAnalysis->findSeasonalityACF('data_values' => $data_values);

        #The expected values of the seasonalities
        my @expected_values  = (82, 94, 12, 106, 130, 23, 35, 142, 70, 47);

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

sub data_model_find_seasonality {

    lives_ok {

        #The data used for the test
        my $file = $path.'data_no_seasonality.csv';
        my $data = Kanopya::Tools::TimeSerie->getTimeserieDatafromCSV('file' => $file, 'sep' => ';');

        my $seasons = Utils::TimeSerieAnalysis->findSeasonality('data' => $data);

        #There is no seasonality for this example
        if ($#$seasons+1 != 0) {
            diag($#$seasons+1 .' != 0');
            die 'Wrong calculation of seasonality in the case where it not exists';
        }

    } 'Compute seasonality in the case where it not exists';

    lives_ok {

        #The data used for the test
        my $file = $path.'data_seasonality=6.csv';
        my $data = Kanopya::Tools::TimeSerie->getTimeserieDatafromCSV('file' => $file, 'sep' => ';');

        my $seasons = Utils::TimeSerieAnalysis->findSeasonality('data' => $data);
        my $expected_value = 6;

        if ($#$seasons+1 != 1 || $seasons->[0] != $expected_value) {
            diag($#$seasons+1 .' != 1') if ($#$seasons+1 != 1);
            diag($seasons->[0].' !=6')  if ($seasons->[0] != $expected_value);
            die('Wrong calculation of seasonalities when season=6');
        }
    } 'Compute seasonalities when season=6';

    lives_ok {

        # The data used for the test
        my $file = $path.'data_seasonality=10.csv';
        my $data = Kanopya::Tools::TimeSerie->getTimeserieDatafromCSV('file' => $file, 'sep' => ';');

        my $seasons        = Utils::TimeSerieAnalysis->findSeasonality('data' => $data);
        my $expected_value = 10;

        if ( $#{$seasons}+1 != 1 || $seasons->[0] != $expected_value ) {
            diag($#$seasons+1 .' != 1') if ($#$seasons+1 != 1);
            diag($seasons->[0].' !=10') if ($seasons->[0] != $expected_value);
            die 'Wrong calculation of seasonalities when Season=10';
        }
    } 'Compute seasonalities when Season=10';

    lives_ok {

        #The data used for the test
        my $file = $path.'data_seasonality=53.csv';
        my $data = Kanopya::Tools::TimeSerie->getTimeserieDatafromCSV('file' => $file, 'sep' => ';');

        my $seasons = Utils::TimeSerieAnalysis->findSeasonality('data' => $data);
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
        my $file = $path.'data_co2.csv';
        my $data = Kanopya::Tools::TimeSerie->getTimeserieDatafromCSV('file' => $file, 'sep' => ';');

        my $seasons=Utils::TimeSerieAnalysis->findSeasonality('data' => $data);

        #The expected values of the seasonalities
        my $expected_value = 12;

        if ( $#{$seasons}+1 != 1 || $seasons->[0] != $expected_value ) {
            diag($#$seasons+1 . ' != 1')    if ($#$seasons+1 != 1);
            diag($seasons->[0]. ' != 12')   if ($seasons->[0] != $expected_value);
            die 'Wrong calculation of additive seasonalities';
        }
    } 'Compute additive seasonalities';

    lives_ok {

        #The data used for the test
        my $file = $path.'data_seasonality=132.csv';
        my $data = Kanopya::Tools::TimeSerie->getTimeserieDatafromCSV('file' => $file, 'sep' => ';');

        my $seasons = Utils::TimeSerieAnalysis->findSeasonality('data' => $data);

        my @expected_values = (3, 132);

        if ($#{$seasons}+1 == 2) {
            foreach my $i (0..$#$seasons) {
                if ($seasons->[$i] != $expected_values[$i]) {
                    diag ($seasons->[$i]." != ". $expected_values[$i]);
                    die 'Wrong calculation of seasonalities when there is noise';
                }
            }
        }
        else {
            diag ($#{$seasons}+1 .' != 2');
            die 'Wrong calculation of seasonalities when there is noise';
        }
    } 'Compute seasonalities when there is noise';
}