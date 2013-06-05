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

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

package Entity::Interface;
use base "Entity";

use Kanopya::Exceptions;

use Entity::Iface;
use Entity::Poolip;
use Entity::Network;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    service_provider_id => {
        pattern      => '^\d+$',
        is_mandatory => 1,
    },
    bonds_number => {
        pattern      => '^\d+$',
        is_mandatory => 0,
    },
    interface_name => {
        label        => 'Name',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1
    },
    netconf_interfaces => {
        label        => 'Network configurations',
        type         => 'relation',
        relation     => 'multi',
        link_to      => 'netconf',
        is_mandatory => 0,
        is_editable  => 1,
    }
};

sub getAttrDef { return ATTR_DEF; }

sub hasRole {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'role' ]);

    my @roles = map { $_->netconf_role->netconf_role_name } $self->netconfs;

    return scalar grep { $_ eq $args{role} } @roles;
}

1;
