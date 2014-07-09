#    Copyright © 2014 Hedera Technology SAS
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

Generic class used to compute formula values

=end classdoc
=cut

package Formula;
use strict;
use warnings;


=pod
=begin classdoc

Compute the value of a given formula , wrt the values of its variables

@param formula String Mathematical formula in which variable
               are represented by the value idX
               where X is an int. (e.g. 'id12 + id43')

@param values hashref {X => V} where X is an integer
              corresponding to a variable of the formula
              and V its values (e.g. {12 => 7, 43 => 5})

@return scalar the value of the formula. Return undef if one value is undef

=end classdoc
=cut

sub compute {
    my ($class, %args) = @_;
    General::checkParams(args => \%args, required => ['values', 'formula']);

    # return undef if one value is missing or undef
    map {(! defined  $args{values}->{$_}) ? return undef : 1 ;} $args{formula} =~ m/id(\d+)/g;

    # replace values in formula
    $args{formula} =~ s/id(\d+)/$args{values}->{$1}/g;

    return eval($args{formula});

}


=pod
=begin classdoc

Compute List of values (one value per timestamp) of a given formula
wrt the values of its variables for each timestamp

@param formula String Mathematical formula in which variable
               are represented by the value idX
               where X is an int. (e.g. 'id12 + id43')

@param values hashref {X => {T => V} where X is an integer
              corresponding to a variable of the formula
              T are timestamps
              and V the value for the givent timestamp
              (e.g. {12 => {1404901772 => 7,
                            1404901872 => 8,}
                     43 => {1404901772 => 5,
                            1404901872 => 6,})

@return hashref {T => V } the value V of the formula for each timestamp T.
        Return undef if one value is undef

=end classdoc
=cut

sub computeTimeSerie {
    my ($class, %args) = @_;
    General::checkParams(args => \%args, required => ['values', 'formula']);


    # Merge all the timestamps keys in one arrays
    my @timestamps;
    foreach my $id (keys %{$args{values}}) {
       @timestamps = (@timestamps, (keys %{$args{values}->{$id}}));
    }

    @timestamps = keys %{ {map { $_ => 1 } @timestamps} };

    my $output = {};

    foreach my $timestamp (@timestamps) {
        my $ts_values = {};
        foreach my $id (keys %{$args{values}}) {
            $ts_values->{$id} = $args{values}->{$id}->{$timestamp};
        }

        $output->{$timestamp} = $class->compute(formula => $args{formula},
                                                values => $ts_values);
    }

    return $output;
}


=pod
=begin classdoc

Compute list of values of a given formula , wrt the values of its variables

@param formula String Mathematical formula in which variable
               are represented by the value idX
               where X is an int. (e.g. 'id12 + id43')

@param values hashref {X => V} where X is an integer
              corresponding to a variable of the formula
              and V its values (e.g. {12 => 7, 43 => 5})

@return scalar the value of the formula. Return undef if one value is undef

=end classdoc
=cut


sub computeTimeSeries {
    my ($class, %args) = @_;
    General::checkParams(args => \%args, required => ['values', 'formula']);

    my $output = {};
    for my $id (keys (%{$args{values}})) {
        $output->{$id} = Formula->computeTimeSerie(values => $args{values}->{$id},
                                                   formula => $args{formula});
    }
    return $output;
}


=pod
=begin classdoc

Extract variable ids from a given formula

@param formula a given mathematical formula (e.g. 'id12 + id43')

@return array of dependant ids

=end classdoc
=cut

sub getDependentIds {
    my ($class, %args) = @_;
    General::checkParams(args => \%args, required => ['formula']);

    my %ids = map { $_ => undef } ($args{formula} =~ m/id(\d+)/g);
    return keys %ids;
}
1;