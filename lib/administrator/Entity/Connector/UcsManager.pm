# ActiveDirectory.pm AD connector
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
# Created 29 july 2012

package Entity::Connector::UcsManager;
use base "Entity::Connector";

use strict;
use warnings;

use Cisco::UCS;

use constant ATTR_DEF => {};

sub getAttrDef { return ATTR_DEF; }

sub connect {
         eval { Cisco::UCS->new(
            cluster  => "89.31.149.80",
            port     => 80,
            proto    => "http",
            username => "admin",
            passwd   => "Infidis2011"
        );
    }
}

sub get_service_profiles {
    my $self = shift;
    my $ucs = $self->connect();
    return $ucs->get_service_profiles(dn => "/sn");
}

1;
