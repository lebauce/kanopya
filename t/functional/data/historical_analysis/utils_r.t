=head1 SCOPE

Utils::R

=head1 PRE-REQUISITE

=cut

use strict;
use warnings;
use Test::More 'no_plan';
use Test::Exception;

use Log::Log4perl qw(:easy);
Log::Log4perl -> easy_init({
    level => 'DEBUG',
    file => __FILE__.'.log',
    layout => '%F %L %p %m%n'
});

use Utils::R;
use Statistics::R;


# The data used for the test
my @data = (5, 12, 13, 15, 13, 12, 5, 12, 13, 15, 13, 12, 5, 12, 13, 15, 13, 12);

# Frequency of the previous dataset
my $freq = 6;

# Horizon to compute
my $hor  = 5;

# Expected values (manually computed from R)
my @expected_values = (5, 12, 13, 15, 13);

main();

sub main {
    noExecutionBugInPrintPrettyRForecast();
    testConvertRForecast();
}

sub testConvertRForecast {
    lives_ok {
        # Create a communication bridge with R and start R
        my $R = Statistics::R->new();
    
        # Initialize the dataset
        $R->set('dataset', \@data);

        # Run R commands
        $R->run(q`library(forecast);`                                            # Load the forecast package
                . qq`time_serie <- ts(dataset, start=1, frequency=$freq);`       # Create the time serie
                . qq`forecast <- forecast(auto.arima(time_serie), h=$hor);`);    # fit and forecast with arima
    
        # Return the forecast computed by R
        my $R_forecast = $R->get('forecast');

        my @forecast = @{Utils::R->convertRForecast(R_forecast_ref => $R_forecast,
                                                    freq           => $freq,
                        )};

        if (scalar(@expected_values) == scalar(@forecast)) {
            for my $index (0..scalar(@expected_values) - 1) {
                unless ($forecast[$index] == $expected_values[$index]) {
                    die ("Incorrect value returned in the forecast ($expected_values[$index] expected, 
                          got $forecast[$index])");
                }
            }
        }
        else {
            die ("Wrong horizon used by R");
        }

   } 'Testing convertRForecast method';

   lives_ok {
       my @R_forecast_ref = ('Point','Forecast','Lo','80','Hi','80','Lo','95',
                          '5.716981','0.04158066','4.158066e-02','4.158066e-02','4.158066e-02',
                          '5.735849','-0.05837414','-5.837414e-02','-5.837414e-02','-5.837414e-02');

       my @forecast = @{Utils::R->convertRForecast(R_forecast_ref => \@R_forecast_ref,
                                                   freq           => $freq)};

       my @expected_forecast = ('0.04158066', '-0.05837414');

       if (scalar @forecast != scalar @expected_forecast) {
           die 'Wrong forecast size';
       }

       for (my $i=0; $i < (scalar @forecast); $i++) {
           if ($forecast[$i] ne $expected_forecast[$i]) {
               die 'Error forecast <' . $i .'>  : ' . $forecast[$i] . ' ne ' . $expected_forecast[$i];
           }
        }
    } 'Testing convertRForecast with 5 columns';

    lives_ok {
      my @R_forecast_ref = ('Point','Forecast','Lo','80','Hi','80','Lo','95','Hi','95',
                            'Jan','1961','446.7582','431.7435','461.7729','423.7953','469.7211',
                            'Feb','1961','420.7582','402.5878','438.9286','392.9690','448.5474',
                            'Mar','1961','448.7582','427.9043','469.6121','416.8649','480.6515',
                            'Apr','1961','490.7582','467.5287','513.9877','455.2318','526.2846');

       my @forecast = @{Utils::R->convertRForecast(R_forecast_ref => \@R_forecast_ref,
                                                   freq           => 12)};

       my @expected_forecast = ('446.7582', '420.7582', '448.7582', '490.7582');

       if (scalar @forecast != scalar @expected_forecast) {
           die 'Wrong forecast size';
       }

       for (my $i=0; $i < (scalar @forecast); $i++) {
           if ($forecast[$i] ne $expected_forecast[$i]) {
               die 'Error forecast <' . $i .'>  : ' . $forecast[$i] . ' ne ' . $expected_forecast[$i];
           }
        }
    } 'Testing convertRForecast with special double labels frequencies';

}

sub noExecutionBugInPrintPrettyRForecast {
    lives_ok {
        # Create a communication bridge with R and start R
        my $R = Statistics::R->new();

        # Initialize the dataset
        $R->set('dataset', \@data);

        # Run R commands
        $R->run(q`library(forecast);`                                            # Load the forecast package
                . qq`time_serie <- ts(dataset, start=1, frequency=$freq);`       # Create the time serie
                . qq`forecast <- forecast(auto.arima(time_serie), h=$hor);`);    # fit and forecast with arima
    
        # Return the forecast computed by R
        my $R_forecast = $R->get('forecast');

        Utils::R->printPrettyRForecast(R_forecast_ref => $R_forecast,
                                       freq           => $freq,
                                       no_print       => 1,
                  );
   } 'Testing printPrettyRForecast method (no execution bug)'
}