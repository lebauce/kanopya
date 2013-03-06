=head1 SCOPE

DataModel

=head1 PRE-REQUISITE

=cut

use strict;
use warnings;
 
use Test::More 'no_plan';
use Kanopya::Tools::TestUtils 'expectedException';
use Test::Exception;

use Entity::DataModel::AutoArima;

main();

sub main {
    checkExceptions();
    checkPredict();
}

sub checkPredict {
    lives_ok {
        # The data used for the test
        my %data = (
            1  => 5,
            2  => 12,
            3  => 13,
            4  => 15,
            5  => 13,
            6  => 12,
            7  => 5,
            8  => 12,
            9  => 13,
            10 => 15,
            11 => 13,
            12 => 12,
            13 => 5,
            14 => 12,
            15 => 13,
            16 => 15,
            17 => 13,
            18 => 12,
        );

        # Expected values (manually computed from R)
        my @expected_values = (5, 12, 13, 15, 13);

        # Data format 1 (hash)
        my $forecast_1 = Entity::DataModel::AutoArima->predict(data_ref => \%data,
                                                               freq     => 6,
                                                               end_time => 23,
                                                       );
        my @forecasted_values = @{$forecast_1->{'values'}};
        for my $index (0..scalar(@expected_values) - 1) {
            unless ($expected_values[$index] == $forecasted_values[$index]) {
                die ("AutoArima : Incorrect value returned in the forecast ($expected_values[$index] expected, 
                      got $forecasted_values[$index]) - Hash format");
            }
        }

        # Data format 2 (pairs)
        my $forecast_2 = Entity::DataModel::AutoArima->predict(data_ref    => \%data,
                                                               freq        => 6,
                                                               end_time    => 23,
                                                               data_format => 'pair',
                                            );
        my @pairs_array = @{$forecast_2};
        for my $index (0..scalar(@expected_values) - 1) {
            my $forecasted_value = ${$pairs_array[$index]}[1];
            unless ($expected_values[$index] == $forecasted_value) {
                die ("AutoArima : Incorrect value returned in the forecast ($expected_values[$index] expected, 
                      got $forecasted_values[$index]) - Pair format");
            }
        }
    } 'Testing outputs of the AutoArima predict method'
}

sub checkExceptions {

    throws_ok {
        my %data = (
            1 => 5,
            2 => 12,
            3 => 13,
            4 => 15,
            5 => 13,
            6 => 12,
        );
        Entity::DataModel::AutoArima->predict(
            data_ref => \%data,
            freq     => 6,
            end_time => 8,
        );
    } 'Kanopya::Exception',
      'AutoArima predict method called with a dataset which contains less than two period';

    throws_ok {
        my %data = (
            1  => 5,
            2  => 12,
            3  => 13,
            4  => 15,
            5  => 13,
            6  => 12,
            7  => 5,
            8  => 12,
            9  => 13,
            10 => 15,
            11 => 13,
            12 => 12,
            13 => 5,
            14 => 12,
            15 => 13,
            16 => 15,
            17 => 13,
            18 => 12,
        );
        Entity::DataModel::AutoArima->predict(
            data_ref => \%data,
            freq     => 6,
            end_time => 8,
        );
    } 'Kanopya::Exception',
      'AutoArima predict method called for forecasting a value before the last value of the dataset';
}