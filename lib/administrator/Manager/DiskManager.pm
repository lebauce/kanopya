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

package Manager::DiskManager;
use base "Manager";

use strict;
use warnings;

use Kanopya::Exceptions;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("administrator");
my $errmsg;

=head2 checkDiskManagerParams

=cut

sub checkDiskManagerParams {}

=head2 getFreeSpace

    Desc : Implement getFreeSpace from DiskManager interface.
           This function return the free space on the volume group.
    args :

=cut

sub getFreeSpace {
    throw Kanopya::Exception::NotImplemented();
}

=head2 createDisk

    Desc : Implement createDisk from DiskManager interface.
           This function enqueue a ECreateDisk operation.
    args :

=cut

sub createDisk {
    throw Kanopya::Exception::NotImplemented();
}

=head2 removeDisk

    Desc : Implement removeDisk from DiskManager interface.
           This function enqueue a ERemoveDisk operation.
    args :

=cut

sub removeDisk {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "container" ]);

    $log->debug("New Operation RemoveDisk with attrs : " . %args);
    Operation->enqueue(
        priority => 200,
        type     => 'RemoveDisk',
        params   => {
            context => {
                container => $args{container},
            }
        },
    );
}

1;
