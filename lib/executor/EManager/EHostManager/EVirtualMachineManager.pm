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

package EManager::EHostManager::EVirtualMachineManager;
use base "EManager::EHostManager";

use strict;
use warnings;

use Log::Log4perl "get_logger";

my $log = get_logger("executor");
my $errmsg;

sub getFreeHost {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [ "ram", "core", "interfaces" ]);

    $log->info("Looking for a virtual host");
    my $host = eval{
        return $self->createVirtualHost(
                   core   => $args{core},
                   ram    => $args{ram},
                   ifaces => $args{interfaces},
               );
    };
    if ($@) {
        $errmsg = "Virtual Machine Manager component <" . $self->getAttr(name => 'component_id') .
                  "> No capabilities to host this vm core <$args{core}> and ram <$args{ram}>:\n" . $@;
        # We can't create virtual host for some reasons (e.g can't meet constraints)
        throw Kanopya::Exception::Internal(error => $errmsg);
    }    

    return $host;
}

1;
