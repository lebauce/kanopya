#    Copyright © 2013 Hedera Technology SAS
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
package EEntity::EComponent::ECeph::ECephMon;
use base "EEntity::EComponent";

use strict;
use warnings;

sub preStartNode {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'cluster', 'host' ]);

    if (!$self->ceph_mon_secret) {
        my $secret = `ceph-authtool /dev/stdout --name=mon. --gen-key | grep "key =" | cut -f 2 -d '='`;
        $secret =~ s/^\s+|\s+$//g;
        $self->ceph_mon_secret($secret);
    }
}

1;
