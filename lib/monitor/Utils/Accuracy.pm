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

use constant {
    ME  => 'me',
    MAE => 'mae',
};

=pod

=begin classdoc

Measure the accuracy of a theorical dataset compared to real/experimental values (so they must be known).

@param theorical_data_ref A reference to the theorical dataset (must be stored in an array). 
@param real_data_ref A reference to the real dataset (must be stored in an array).
@param measure The measure used ('mae', 'mse', 'rmse', )

@return The accuracy measured.

=end classdoc

=cut

sub accuracy {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['theorical_data_ref', 'real_data_ref'],
                         optional => { 'measure' => ME});

    $self->_checkLength(theorical_data_ref => $args{theorical_data_ref},
                        real_data_ref      => $args{real_data_ref});

    my $accuracy = ($args{measure} eq ME)  ? $self->_me(theorical_data_ref => $args{theorical_data_ref},
                                                         real_data_ref     => $args{real_data_ref})

                 : ($args{measure} eq MAE) ? $self->_mae(theorical_data_ref => $args{theorical_data_ref},
                                                         real_data_ref      => $args{real_data_ref})

                 :                           undef
                 ;
}

=pod

=begin classdoc

Measure the accuracy performing the ME (Mean Error).

@param theorical_data_ref A reference to the theorical dataset (must be stored in an array). 
@param real_data_ref A reference to the real dataset (must be stored in an array).

@return The MAE.

=end classdoc

=cut

sub _me {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['theorical_data_ref', 'real_data_ref']);

    my @theorical = @{$args{theorical_data_ref}};
    my @real      = @{$args{real_data_ref}};

    my $total     = 0;

    for my $i (0..$#theorical) {
        $total += $real[$i] - $theorical[$i];
    }

    return $total / scalar(@theorical);
}

=pod

=begin classdoc

Measure the accuracy performing the MAE (Mean Absolute Error).

@param theorical_data_ref A reference to the theorical dataset (must be stored in an array). 
@param real_data_ref A reference to the real dataset (must be stored in an array).

@return The MAE.

=end classdoc

=cut

sub _mae {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['theorical_data_ref', 'real_data_ref']);

    my @theorical = @{$args{theorical_data_ref}};
    my @real      = @{$args{real_data_ref}};

    my $total     = 0;

    for my $i (0..$#theorical) {
        $total += abs($real[$i] - $theorical[$i]);
    }

    return $total / scalar(@theorical);
}

=pod

=begin classdoc

Ensure that a theorical dataset and a experimental one have the same length (otherwise the accuracy of the 
theorical one cannot be measured). If they don't, throws an exception.

@param theorical_data_ref A reference to the theorical dataset (must be stored in an array). 
@param real_data_ref A reference to the real dataset (must be stored in an array).

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
}

1;