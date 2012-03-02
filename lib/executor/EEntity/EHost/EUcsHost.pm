#    Copyright © 2011-2012 Hedera Technology SAS
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

package EEntity::EHost::EUcsHost;
use base "EEntity::EHost";

use strict;
use warnings;

use Operation;

use Log::Log4perl "get_logger";
my $log = get_logger("executor");

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new(%args);

    return $self;
}

sub start{
    my $self = shift;
    my %args = @_;

    throw Kanopya::Exception::NotImplemented();
}

sub stop {
	my $self = shift;
    my %args = @_;

    throw Kanopya::Exception::NotImplemented();
}

sub postStart {
	my $self = shift;

    throw Kanopya::Exception::NotImplemented();
}

1;
