=head1 SCOPE

STL Forecast

=head1 PRE-REQUISITE

=cut

use strict;
use warnings;

use Test::More 'no_plan';
use Kanopya::Tools::TestUtils 'expectedException';
use Test::Exception;

use Log::Log4perl qw(:easy);
Log::Log4perl -> easy_init({
    level => 'DEBUG',
    file => __FILE__.'.log',
    layout => '%F %L %p %m%n'
});

use Entity::DataModel::RDataModel::StlForecast;

main();

sub main {
    checkExceptions();
    checkPredict();
}

sub checkPredict {
    lives_ok {
        # The data used for the test
        my @data = (5, 12, 13, 15, 13, 12, 5, 12, 13, 15, 13, 12, 5, 12, 13, 15, 13, 12);

        # Expected values (manually computed from R)
        my @expected_values = (5, 12, 13, 15, 13);
        my $forecast = Entity::DataModel::RDataModel::StlForecast->predict(
            data => \@data,
            freq     => 6,
            predict_end => 23,
        );
        my @forecasted_values = @{$forecast};
        for my $index (0..scalar(@expected_values) - 1) {
            unless ($expected_values[$index] == $forecasted_values[$index]) {
                die ("StlForecast : Incorrect value returned in the forecast " .
                     " ($expected_values[$index] expected, got $forecasted_values[$index])");
            }
        }
    } 'Testing outputs of the StlForecast predict method'
}

sub checkExceptions {

    throws_ok {
        my @data = (5, 12, 13, 15, 13, 12);

        Entity::DataModel::RDataModel::StlForecast->predict(
            data        => \@data,
            freq        => 6,
            predict_end => 8,
        );
    } 'Kanopya::Exception::Internal::IncorrectParam',
      'StlForecast predict method called with a dataset which contains less than two period';

    throws_ok {
        my @data = (5, 12, 13, 15, 13, 12, 5, 12, 13, 15, 13, 12, 5, 12, 13, 15, 13, 12);

        Entity::DataModel::RDataModel::StlForecast->predict(
            data => \@data,
            freq     => 6,
            predict_end => 8,
        );
    } 'Kanopya::Exception::Internal::IncorrectParam',
      'StlForecast predict method called for forecasting a value before the last value of the ' .
      'dataset';

    throws_ok {
        my @data = (5, 12, 13, 15, 13, 12, 5, 12, 13, 15, 13, 12, 5, 12, 13, 15, 13, 12);

        Entity::DataModel::RDataModel::StlForecast->predict(
            data => \@data,
            freq     => 1,
            predict_end => 25,
        );
    } 'Kanopya::Exception::Internal::IncorrectParam',
      'StlForecast predict method called for forecasting a non seasonal time serie ';


    throws_ok {
        my @data = (5, 12, 13, 15, 13, 12, 5, 12, 13, 15, 13, 12, 5, 12, 13, 15, 13, 12);

        Entity::DataModel::RDataModel::StlForecast->predict(
            data => \@data,
            freq       => 8,
            predict_start => 5,
            predict_end => 25,
        );
    } 'Kanopya::Exception::Internal::IncorrectParam',
      'predict start before end of time serie';
}
