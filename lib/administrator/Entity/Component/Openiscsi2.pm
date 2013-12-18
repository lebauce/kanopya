# Openiscsi2.pm -open iscsi component (iscsi client) (Adminstrator side)
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
# Created 5 august 2010

package Entity::Component::Openiscsi2;
use base "Entity::Component";

use strict;
use warnings;

use Kanopya::Exceptions;

use Hash::Merge qw(merge);
use Log::Log4perl "get_logger";

my $log = get_logger("");

use constant ATTR_DEF => {};

sub getAttrDef { return ATTR_DEF; }

sub getPuppetDefinition {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, require => [ 'host' ]);

    my $host_params   = $args{host}->node->service_provider->getManagerParameters(
        manager_type => 'HostManager'
    );

    my $initiatorname = '';
    if ($host_params->{deploy_on_disk}) {
        $initiatorname    = $args{host}->host_initiatorname;
    }

    return merge($self->SUPER::getPuppetDefinition(%args), {
        openiscsi => {
            classes => {
                "kanopya::openiscsi" => {
                    initiatorname => $initiatorname
                }
            }
        }
    } );
}

1;
