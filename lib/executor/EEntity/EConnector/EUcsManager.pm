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

package EEntity::EConnector::EUcsManager;
use base "EEntity::EConnector";

use strict;
use warnings;
use General;
use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("executor");
my $errmsg;

sub startHost {
	my $self = shift;
	my %args = @_;

	General::checkParams(args => \%args, required => ['cluster', 'host']);

    $self->_getEntity()->startHost(%args);
}

sub stopHost {
	my $self = shift;
	my %args = @_;

	General::checkParams(args => \%args, required => ['cluster', 'host']);

    $self->_getEntity()->stopHost(%args);
}

sub postStart {
}

1;
