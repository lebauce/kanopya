# Copyright © 2012 Hedera Technology SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

=pod

=begin classdoc

Kanopya test utility methods 

@since 17/12/12
@instance hash
@self $self

=end classdoc

=cut

package Kanopya::Tools::TestUtils;

use Exporter 'import';
@EXPORT_OK = qw(expectedException);

use strict;
use warnings;


=pod

=begin classdoc

Dies if code block does not throw the expected exception.
Code block represents a post condition of a test.


Sample usage:
 expectedException { Entity->get(id => -1) } 'Kanopya::Exception::Internal::NotFound', 'Entity -1 does not exist';

@param &code code block
@param $exception_class expecting exception class
@optional $msg post condition msg info

@return 1 or throws exception

=end classdoc

=cut

sub expectedException (&;$;$) {
    my ($code,$excep_class,$msg) = @_; 

    $msg = $msg || 'Eval post condition';

    eval {
        $code->();
    };
    if ($@) {
        my $error       = $@;
        my $error_ref   = ref $error;
        if (ref $error ne $excep_class) {
            die "$msg : Expecting '$excep_class' but got '$error_ref' : $error";
        }
    } else {
        die "$msg : Expecting '$excep_class' but no exception happens";
    }
}

1;
