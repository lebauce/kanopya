# Copyright © 2011-2012 Hedera Technology SAS
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

package EEntity::EHost::EHostMock;
use base "EEntity::EHost";

use strict;
use warnings;

use Log::Log4perl "get_logger";

my $log = get_logger("");
my $errmsg;

sub checkUp {
    my ($self, %args) = @_;

    $log->info("Mock: return 1 to simulate a host up.");
    return 1;
}

sub halt {
    my ($self, %args) = @_;

    $log->info("Mock: doing nothing instead of halting the host.");
    return 1;
}

1;
