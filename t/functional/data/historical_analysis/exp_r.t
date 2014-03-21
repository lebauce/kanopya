=head1 SCOPE

ExpR

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

use DataModel::RDataModel::ExpR;

main();

sub main {
    checkPredict();
}

sub checkPredict {
    lives_ok {
        # The data used for the test
        my @data = (5, 12, 13, 15, 13, 12, 5, 12, 13, 15, 13, 12, 5, 12, 13, 15, 13, 12);

        # Expected values (manually computed from R)
        my @expected_values = (5, 12, 13, 15, 13);
        my $forecast = DataModel::RDataModel::ExpR->predict(
            data => \@data,
            freq     => 6,
            predict_end => 23,
        );
        my @forecasted_values = @{$forecast};
        for my $index (0..scalar(@expected_values) - 1) {
            unless ($expected_values[$index] == $forecasted_values[$index]) {
                die ("ExpR : Incorrect value returned in the forecast " .
                     " ($expected_values[$index] expected, got $forecasted_values[$index])");
            }
        }
    } 'Testing outputs of the ExpR predict method'
}
