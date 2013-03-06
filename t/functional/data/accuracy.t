=head1 SCOPE

DataModel

=head1 PRE-REQUISITE

=cut

use strict;
use warnings;
 
use Test::More 'no_plan';
use Kanopya::Tools::TestUtils 'expectedException';
use Test::Exception;

use Utils::Accuracy;

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

        Utils::Accuracy->accuracy(theorical_data_ref => \@theorical,
                                  real_data_ref      => \@real);
    } 'Kanopya::Exception',
      'Accuracy : accuracy method called with two different-sized datasets';
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

    # MAE
    lives_ok {
        my $expected_me = 0.80;
        my $computed_me = Utils::Accuracy->accuracy(theorical_data_ref => \@theorical,
                                                     real_data_ref     => \@real,
                                                     measure           => 'me');
        if (abs($expected_me - $computed_me) > $delta) {
            die ("Accuracy : Wrong value returned by ME measure ($expected_me expected, $computed_me 
                  computed)");
        }
    } "Accuracy : testing ME accuracy measure";

    # ME
    lives_ok {
        my $expected_mae = 2.80;
        my $computed_mae = Utils::Accuracy->accuracy(theorical_data_ref => \@theorical,
                                                     real_data_ref      => \@real,
                                                     measure            => 'mae');
        if (abs($expected_mae - $computed_mae) > $delta) {
            die ("Accuracy : Wrong value returned by MAE measure ($expected_mae expected, $computed_mae 
                  computed)");
        }
    } "Accuracy : testing MAE accuracy measure";
}