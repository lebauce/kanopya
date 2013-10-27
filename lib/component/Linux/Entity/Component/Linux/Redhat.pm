#    Copyright © 2012 Hedera Technology SAS
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
package Entity::Component::Linux::Redhat;
use base 'Entity::Component::Linux';

use strict;
use warnings;

use LinuxMount;

use Hash::Merge qw(merge);
use Log::Log4perl 'get_logger';

my $log = get_logger("");

sub getAttrDef { return { }; }

sub getPuppetDefinition {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'cluster', 'host' ]);

    return merge($self->SUPER::getPuppetDefinition(%args), {
        redhat => {
            manifest => $self->instanciatePuppetResource(
                            name => "openstack::repo",
                            params => {
                                stage => "system"
                            }
                        )
        }
    } );
}

1;
