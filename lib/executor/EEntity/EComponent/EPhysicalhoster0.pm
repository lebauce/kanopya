# Copyright © 2011 Hedera Technology SAS
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

package EEntity::EComponent::EPhysicalhoster0;
use base "EEntity::EComponent";

use strict;
use warnings;

use General;
use Entity::Powersupplycard;

use Log::Log4perl "get_logger";
my $log = get_logger("executor");
my $errmsg;


=head2 createHost

=cut

sub createHost {
    my $self = shift;
    my %args  = @_;

    General::checkParams(args     => \%args,
                         required => [ "processormodel_id", "host_core", "kernel_id",
                                       "hostmodel_id", "host_mac_address",
                                       "host_serial_number", "host_ram" ]);

    if (defined $args{erollback}) { delete $args{erollback}; }
    if (defined $args{econtext})  { delete $args{econtext}; }

    my $host = $self->_getEntity()->addHost(%args);

    #TODO: insert erollback ?
    return $host;
}

=head2 removeHost

=cut

sub removeHost {
    my $self = shift;
    my %args  = @_;

    General::checkParams(args     => \%args,
                         required => [ "host" ]);

    my $host = $self->_getEntity()->delHost(%args);

    #TODO: insert erollback ?
}

1;
