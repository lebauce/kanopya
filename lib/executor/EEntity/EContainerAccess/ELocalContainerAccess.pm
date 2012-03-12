#    Copyright © 2011 Hedera Technology SAS
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

package EEntity::EContainerAccess::ELocalContainerAccess;
use base "EEntity::EContainerAccess";

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Operation;

my $log = get_logger("executor");

sub new {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'container' ]);

    $args{data} = {};

    my $self = $class->SUPER::new(%args);

    $self->{container} = $args{container};

    bless $self, $class;
    return $self;
}

=head2 connect

    desc: Creating open-iscsi node, and wait for the device appeared.

=cut

sub connect {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'econtext' ]);

    my $device = $self->{container}->_getEntity->getAttr(name => 'container_device');

    $log->info("Return file path (<$device>).");
    return $device;
}

=head2 disconnect

    desc: Deleting open-iscsi node.

=cut

sub disconnect {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'econtext' ]);
}

1;
