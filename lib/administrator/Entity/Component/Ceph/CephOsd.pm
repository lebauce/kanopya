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

package  Entity::Component::Ceph::CephOsd;
use base "Entity::Component";

use strict;
use warnings;

use Hash::Merge qw(merge);
use Log::Log4perl "get_logger";
my $log = get_logger("");

use constant ATTR_DEF => {
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
        cephosd => {
            # The first OSD runs on port 6800
            port => 6800,
            protocols => [ 'tcp' ]
        }
    };
}

sub getPuppetDefinition {
    my ($self, %args) = @_;

    my $devices = {};
    for my $harddisk ($args{host}->harddisks) {
        $devices->{$harddisk->harddisk_device} = { };
    }

    return merge($self->SUPER::getPuppetDefinition(%args), {
        cephosd => {
            classes => {
                "kanopya::ceph::osd" => {
                    devices => $devices
                },
            }
        }
    } );
}

1;
