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


=end classdoc
=cut
package Formula;
use strict;
use warnings;

sub compute {
    my ($class, %args) = @_;
    General::checkParams(args => \%args, required => ['values', 'formula']);

    # return undef if one value is missing or undef
    map {(! defined  $args{values}->{$_}) ? return undef : 1 ;} $args{formula} =~ m/id(\d+)/g;

    # replace values in formula
    $args{formula} =~ s/id(\d+)/$args{values}->{$1}/g;
    my $res = undef;
    my $arrayString = '$res = ' . $args{formula};

    # Evaluate the logic formula
    eval $arrayString;

    return $res;
}

sub computeTimeSerie {
    my ($class, %args) = @_;
    General::checkParams(args => \%args, required => ['values', 'formula']);


    # Merge all the timestamps keys in one arrays
    my @timestamps;
    foreach my $cm_id (keys %{$args{values}}) {
       @timestamps = (@timestamps, (keys %{$args{values}->{$cm_id}}));
    }

    @timestamps = keys %{ {map { $_ => 1 } @timestamps} };

    my %rep;

    foreach my $timestamp (@timestamps) {
        my $ts_values = {};
        foreach my $cm_id (keys %{$args{values}}) {
            $ts_values->{$cm_id} = $args{values}->{$cm_id}->{$timestamp};
        }

        $rep{$timestamp} = $class->compute(formula => $args{formula},
                                           values  => $ts_values);
    }

    return \%rep;
}

sub getDependentIds {
    my ($class, %args) = @_;
    General::checkParams(args => \%args, required => ['formula']);

    my %ids = map { $_ => undef } ($args{formula} =~ m/id(\d+)/g);
    return keys %ids;
}
1;