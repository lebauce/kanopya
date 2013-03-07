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

Utility class providing several measures for evaluating the accuracy of a theorical dataset, compared to 
known real experimental values.

@since 2013-Mar-05 

=end classdoc

=cut

package Utils::Accuracy;

use strict;
use warnings;
use General;

=pod

=begin classdoc

Measure the accuracy of a theorical dataset compared to real/experimental values (so they must be known), 
using different kinds of measures.

@param theorical_data_ref A reference to the theorical dataset (must be stored in an array). 
@param real_data_ref A reference to the real dataset (must be stored in an array).

@return A ref to a hash containing several accuracy measures ('me', 'mae', 'mse', 'rmse').

=end classdoc

=cut

sub accuracy {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['theorical_data_ref', 'real_data_ref']);

    my $datasets_length = $self->_checkLength(theorical_data_ref => $args{theorical_data_ref},
                                              real_data_ref      => $args{real_data_ref});

    my @theorical = @{$args{theorical_data_ref}};
    my @real      = @{$args{real_data_ref}};

    my $e_total  = 0;
    my $ae_total = 0;
    my $se_total = 0;

    for my $i (0..$#theorical) {
        my $e = $real[$i] - $theorical[$i];
        $e_total  += $e;
        $ae_total += abs($e);
        $se_total += $e ** 2;
    }

    my $me   = $e_total / $datasets_length;
    my $mae  = $ae_total / $datasets_length;
    my $mse  = $se_total / $datasets_length;
    my $rmse = sqrt($mse);

    my %measures = (
        me   => $me,
        mae  => $mae,
        mse  => $mse,
        rmse => $rmse,
    );
    return \%measures;
}

=pod

=begin classdoc

Ensure that a theorical dataset and a experimental one have the same length (otherwise the accuracy of the 
theorical one cannot be measured). If they do, returns this length, else throws an exception.

@param theorical_data_ref A reference to the theorical dataset (must be stored in an array). 
@param real_data_ref A reference to the real dataset (must be stored in an array).

@return The datasets length, if it is the same.

=end classdoc

=cut

sub _checkLength {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['theorical_data_ref', 'real_data_ref']
                         );

    my $theorical_length    = scalar(@{$args{theorical_data_ref}});
    my $experimental_length = scalar(@{$args{real_data_ref}});

    if ($theorical_length != $experimental_length) {
        throw Kanopya::Exception(error => 'Accuracy : trying to compare two different-sized dataset.');
    }
    else {
        return $theorical_length;
    }
}

1;