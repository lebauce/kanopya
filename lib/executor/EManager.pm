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

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

=pod

=begin classdoc

TODO

=end classdoc

=cut

package EManager;

use strict;
use warnings;

use Kanopya::Exceptions;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");


=pod
=begin classdoc

Try to increase the number of current consumers of the manager.
Concrete managers could override this method and raise an exceptions
if the manager has reach the maximum of simultaneous users.

=end classdoc
=cut

sub increaseConsumers {
    my ($self, %args) = @_;

    # Use the following block to raise exception in concrete implementation of increaseConsumers.
    #throw Kanopya::Exception::Execution::InvalidState(
    #          error => "The xxxx manager has reach the maximum amount of consumers"
    #      );
}


=pod
=begin classdoc

Decrease the number of current consumers of the manager.

=end classdoc
=cut

sub decreaseConsumers {
    my ($self, %args) = @_;
}

1;
