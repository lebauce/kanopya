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

package Entity::Component::Physicalhoster0;
use base "Entity::Component";
use base "Manager::HostManager";

use strict;
use warnings;

use Entity::Powersupplycard;
use Manager::HostManager;
use Kanopya::Exceptions;

use Log::Log4perl "get_logger";
use Data::Dumper;
use IO::Socket;

my $log = get_logger("administrator");
my $errmsg;

use constant ATTR_DEF => {};

sub getAttrDef { return ATTR_DEF; }

sub methods {
    return {
        'getHostType' => {
            'description' => 'Return the type of managed hosts.',
            'perm_holder' => 'entity',
        },
    }
}

sub getBootPolicies {
    return (Manager::HostManager->BOOT_POLICIES->{pxe_iscsi},
            Manager::HostManager->BOOT_POLICIES->{pxe_nfs});
}

sub getHostType {
    return "Physical host";
}

=head2 getPolicyParams

=cut

sub getPolicyParams {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'policy_type' ]);

    if ($args{policy_type} eq 'hosting') {
        return [ { name => 'cpu', label => 'Required CPU number', pattern => '^[0-9]+$' },
                 { name => 'ram', label => 'Required RAM amount', pattern => '^[0-9]+$' },
                 { name => 'ram_unit', label => 'RAM unit', values => [ 'M', 'G' ] } ];
    }
    return [];
}

sub getConf {
    return {};
}

sub setConf {
}

sub getRemoteSessionURL {
    return "";
}

1;
