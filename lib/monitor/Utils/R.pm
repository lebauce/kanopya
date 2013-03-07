#    Copyright © 2013 Hedera Technology SAS
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

=pod

=begin classdoc

Utilitary class which provides useful methods for using R objects (extracted with Statistics::R) into Perl.
In particular forecast objects from the forecast package.

=end classdoc

=cut

package Utils::R;

use strict;
use warnings;
use General;
use Data::Dumper;

use constant FORECAST => {
    # Number of columns in a R forecast object (if not special frequency)
    COLUMNS_NUMBER      => 6,

    # The size of the first information row in the R forecast object
    FIRST_ROW_SIZE      => 6,

    # The index of the column where is situated the forecasted value in the R forecast object
    # (if not special frequency)
    FORECAST_COLUMN     => 1,

    # The printed width of columns when giving a string representation of the R forecast object
    COLUMN_PRINT_WIDTH  => 12,

    # Frequencies including a double column label (ex: 1 Q4, Jul 2, ...)
    DOUBLE_LABEL_FREQS  => {
        4  => 1,
        12 => 1,
    },
};

use constant ACF => {
    # Index of the first element of the acf array returned by R
    # It corresponds to acf[1] since acf[0] is useless
    INDEX_NUMBER        => 6,

    # Number of elements of the R acf object that contains useful information (array index, acf value)
    NUMBER_USEFUL_DATA  => 2,
};


=pod

=begin classdoc

Convert a forecast object extracted from R into a Perl-usable format (simple array containing the forecasts).

@param R_forecast_ref a ref to the forecast object (from the forecast package) extracted from R.

@return the forecasteds values (array ref).

=end classdoc

=cut

sub convertRForecast{
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['R_forecast_ref', 'freq']);

    my $cols_number              = FORECAST->{'COLUMNS_NUMBER'};
    my $first_row_size           = FORECAST->{'FIRST_ROW_SIZE'};
    my $forecast_column          = FORECAST->{'FORECAST_COLUMN'};
    my %double_label_frequencies = %{FORECAST->{'DOUBLE_LABEL_FREQS'}};

    # Raw R data
    my @R_forecast_raw = @{$args{R_forecast_ref}};

    # If this information row is present, we remove it (The structure of the following code is for helping
    # debug if needed)
    if ($R_forecast_raw[0] eq 'Point') {
        for (0..$first_row_size-1) {
            my $shift = shift(@R_forecast_raw);
            if (("$shift" eq "Lo") || ("$shift" eq "Hi")) {
                $shift = "$shift" . " " .  shift(@R_forecast_raw);
            }
        }
    }

    my @forecasts;

    # True if the given freq is a special freq, ie which implies a 2-columns label
    my $special_freq = exists($double_label_frequencies{$args{freq}});

    my $rows_number = $special_freq ? @R_forecast_raw / ($cols_number + 1)
                    :                 @R_forecast_raw / ($cols_number)
                    ;

    for my $row (0..$rows_number - 1) { 
        my $index = $special_freq ? (($cols_number + 1) * $row) + $forecast_column + 1
                   :                (($cols_number) * $row) + $forecast_column
                   ;
        push(@forecasts, $R_forecast_raw[$index]);
    }

    return \@forecasts;
}

=pod

=begin classdoc

Print the R forecast object with a table representation.

@param R_forecast_ref A ref to the forecast object extracted from R.

@optional no_print If defined and true, the method will not print anything (used for testing that there is
                no execution bug in the method without filling the console up with useless informations).

=end classdoc

=cut

sub printPrettyRForecast{
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['R_forecast_ref', 'freq'],
                         optional => { 'no_print' => undef});

    my $cols_number               = FORECAST->{'COLUMNS_NUMBER'};
    my $first_row_size            = FORECAST->{'FIRST_ROW_SIZE'};
    my $column_print_width        = FORECAST->{'COLUMN_PRINT_WIDTH'};
    my %double_label_frequencies = %{FORECAST->{'DOUBLE_LABEL_FREQS'}};

    # Raw R data
    my @R_forecast_raw = @{$args{R_forecast_ref}};

    # If the first row (information row) is present, we print it and remove it
    unless (defined($args{no_print}) && $args{no_print}) {
        print (" " x $column_print_width);
    }
    if ($R_forecast_raw[0] eq 'Point') {
        for (0..$first_row_size-1) {
            my $shift = shift(@R_forecast_raw);
            if (("$shift" eq "Lo") || ("$shift" eq "Hi")) {
                $shift = "$shift" . " " .  shift(@R_forecast_raw);
            }
            unless (defined($args{no_print}) && $args{no_print}) {
                print("$shift" . " " x ($column_print_width - length($shift)));
            }
        }
        unless (defined($args{no_print}) && $args{no_print}) {
            print("\n");
        }
    }

    my @forecasts;

    # True if the given freq is a special freq, ie which implies a 2-columns label
    my $special_freq = exists($double_label_frequencies{$args{freq}});

    my $rows_number = $special_freq ? @R_forecast_raw / ($cols_number + 1)
                    :                 @R_forecast_raw / ($cols_number)
                    ;

    for my $row (0..$rows_number-1) {
        for my $col (0..$cols_number) {
            if (($col == 0) && !($special_freq) && !defined($args{no_print}) && !($args{no_print})) {
                print (" " x $column_print_width);
            }
            unless ((($col == $cols_number) && !($special_freq))) {
                my $current = $special_freq ? $R_forecast_raw[ (($cols_number + 1) * $row) + $col ]
                            :                 $R_forecast_raw[ (($cols_number) * $row) + $col ]
                            ;
                unless (defined($args{no_print}) && $args{no_print}) {
                    print("$current" . " " x ($column_print_width - length($current)));
                }
            }
        }
        unless (defined($args{no_print}) && $args{no_print}) {
            print("\n");
        }
    }
}

=pod

=begin classdoc

Convert an object extracted from R into a Perl-usable format (simple array containing the acf).

@param R_acf_ref a ref to the acf object extracted from R.

@return the acf values (array ref).

=end classdoc

=cut

sub convertRacf {
    my ($class, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['R_acf_ref']
                        );
    my @acf;
    my $index_acf = 0;

    for (my $index = ACF->{'INDEX_NUMBER'}; $index <= $#{$args{'R_acf_ref'}}; $index++) {
        # To extract only the values of the acf
        if ( $index % ACF->{'NUMBER_USEFUL_DATA'} != 0 ) {
            $acf[$index_acf] = $args{'R_acf_ref'}->[$index];
            $index_acf++;
        }
    }

    return \@acf;
}
1;
