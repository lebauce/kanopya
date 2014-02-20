#    Copyright © 2013 Hedera Technology SAS
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

package  Entity::Component::Ceph::CephMon;
use base "Entity::Component";

use strict;
use warnings;

use Hash::Merge qw(merge);
use Log::Log4perl "get_logger";
my $log = get_logger("");

use constant ATTR_DEF => {
    ceph_mon_secret => {
        label          => 'Ceph MON secret',
        type           => 'string',
        pattern        => '^.*$',
        is_mandatory   => 0,
        is_editable    => 0  
    },
    ceph_id => {
        label       => 'Ceph component',
        type        => 'relation',
        relation    => 'single',
        is_editable => 1
    },
};

sub getAttrDef { return ATTR_DEF; }

sub getNetConf {
    return {
        cephmon => {
            port => 6789,
            protocols => [ 'tcp' ]
        }
    };
}

sub getPuppetDefinition {
    my ($self, %args) = @_;

    return merge($self->SUPER::getPuppetDefinition(%args), {
        cephmon => {
            classes => {
                'kanopya::ceph::mon' => {
                    mon_secret => $self->ceph_mon_secret,
                    mon_id => $args{host}->node->node_number - 1
                }
            }
        }
    } );
}

1;
