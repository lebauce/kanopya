#    Copyright © 2011 Hedera Technology SAS
#
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

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

=pod
=begin classdoc

Base class for component test classes. Give utilities for writing test suites.

=end classdoc
=cut

package Kanopya::Test;

use strict;
use warnings;

use General;

use Test::More;


=pod
=begin classdoc

Wait the operation termination and report errors if occurs

=end classdoc
=cut

sub waitOperartion {
    my ($class, %args) = @_;

    General::checkParams(args => \%args,
                         required => [ 'operation' ],
                         optional => { 'timeout' => 600 });

    # Set timeout to 10 min
    my $timeout = time + $args{timeout};
    while (time < $timeout) {
        if ($args{operation}->workflow->state eq "done") {
            diag("Operation <" . $args{operation}->label . "> done.");
            last;
        }
        elsif ($args{operation}->workflow->state eq "cancelled") {
            my $exception = $args{operation}->param_preset->load()->{exception};

            diag("Operation <" . $args{operation}->label . "> failed.");
            throw Kanopya::Exception::Test(
                      error => defined($exception)
                                   ? $exception
                                   : "Operation <" . $args{operation}->label . "> failed."
                  );
        }
        diag("Operation <" . $args{operation}->label . "> still running.");
        sleep 2;
    }
}


=pod
=begin classdoc

Run the complete test suite for a component. Must be implemented un sub-classes.

=end classdoc
=cut

sub runTestSuite {
    my ($class, %args) = @_;

    throw Kanopya::Exception::NotImplemented();
}

1;
