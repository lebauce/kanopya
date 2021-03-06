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

package EEntity::EComponent::EPhysicalhoster0::EPhysicalhoster0Mock;
use base "EEntity::EComponent::EPhysicalhoster0";

use strict;
use warnings;

use Log::Log4perl "get_logger";
my $log = get_logger("");
my $errmsg;

sub startHost {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "host" ]);

    $log->info("Mock: doing nothing instead of starting the host.");
}

1;
