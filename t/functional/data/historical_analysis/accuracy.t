=head1 SCOPE

Accuracy

=head1 PRE-REQUISITE

=cut

use strict;
use warnings;
use Data::Dumper;
use Test::More 'no_plan';
use Test::Exception;

use Log::Log4perl qw(:easy);
Log::Log4perl -> easy_init({
    level => 'DEBUG',
    file => __FILE__.'.log',
    layout => '%F %L %p %m%n'
});

use Utils::TimeSerieAnalysis;

main();

sub main {
    testDifferentSizedDatasets();
    testAccuracyMeasures();
}


# Check that measuring the accuracy of two different-sized datasets throws an exception
sub testDifferentSizedDatasets {
    throws_ok {
        my @theorical = (
            1,
            2,
            3,
            4,
        );
        my @real = (
            1,
            2,
            3,
            4,
            5,
            6,
        );

        Utils::TimeSerieAnalysis->accuracy(theorical_data_ref => \@theorical,
                                           real_data_ref      => \@real);
    } 'Kanopya::Exception',
      'TimeSerieAnalysis : accuracy method called with two different-sized datasets';
}

# Check every accuracy measure using the same datasets, expected values have been computed from R
sub testAccuracyMeasures {

    # Theorical dataset
    my @theorical = (
        5,
        5,
        5,
        5,
        5,
        5,
        5,
        5,
        5,
        5,
    );

    # Real dataset
    my @real = (
        1,
        2,
        4,
        3,
        5,
        6,
        8,
        9,
        9,
        11,
    );

    # Delta for float value comparisons
    my $delta = 0.001;

    # Computed measures
        my %measure = %{Utils::TimeSerieAnalysis->accuracy(theorical_data_ref => \@theorical,
                                                           real_data_ref      => \@real)};

    # ME
    lives_ok {
        my $expected_me = 0.80;
        my $computed_me = $measure{me};
        if (abs($expected_me - $computed_me) > $delta) {
            die ("TimeSerieAnalysis : Wrong value returned by ME measure ($expected_me expected, $computed_me 
                  computed)");
        }
    } "TimeSerieAnalysis : testing ME accuracy measure";

    # MAE
    lives_ok {
        my $expected_mae = 2.80;
        my $computed_mae = $measure{mae};
        if (abs($expected_mae - $computed_mae) > $delta) {
            die ("TimeSerieAnalysis : Wrong value returned by MAE measure ($expected_mae expected," . 
                 "$computed_mae computed)");
        }
    } "TimeSerieAnalysis : testing MAE accuracy measure";

    # MSE
    lives_ok {
        my $expected_mse = 10.8;
        my $computed_mse = $measure{mse};
        if (abs($expected_mse - $computed_mse) > $delta) {
            die ("TimeSerieAnalysis : Wrong value returned by MSE measure ($expected_mse expected, " . 
                 "$computed_mse computed)");
        }
    } "TimeSerieAnalysis : testing MSE accuracy measure";

    # RMSE
    lives_ok {
        my $expected_rmse = 3.286335;
        my $computed_rmse = $measure{rmse};
        if (abs($expected_rmse - $computed_rmse) > $delta) {
            die ("TimeSerieAnalysis : Wrong value returned by RMSE measure ($expected_rmse expected, " .
                 "$computed_rmse computed)");
        }
    } "TimeSerieAnalysis : testing RMSE accuracy measure";
}