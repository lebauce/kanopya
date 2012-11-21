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

package EEntity::EContainerAccess::EIscsiContainerAccess::EIscsiContainerAccessMock;
use base "EEntity::EContainerAccess::EIscsiContainerAccess";

use strict;
use warnings;

use Log::Log4perl "get_logger";

my $log = get_logger("");

my $fakedevice = "/tmp/EIscsiContainerAccessMock";

sub connect {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'econtext' ]);

    # Create a fake file to return it as the device
    my $cmd = "dd if=/dev/zero of=$fakedevice bs=1 count=1 seek=" . $self->container->container_size;
    $args{econtext}->execute(command => $cmd);

    $log->info("Mock: returning <$fakedevice> as fake device.");
    return $fakedevice;
}

=head2 disconnect

    desc: Deleting open-iscsi node.

=cut

sub disconnect {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'econtext' ]);

    $log->info("Mock: rdoing nothing instead of disconnecting the device.");
}

1;
