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

use Entity::Component::Linux::LinuxMount;

use Log::Log4perl 'get_logger';
use Data::Dumper;

my $log = get_logger("");
my $errmsg;

sub insertDefaultExtendedConfiguration {
    my $self = shift;
    
    my @default_conf = (
        {
            linux_mount_device => 'devpts',
            linux_mount_point => '/dev/pts',
            linux_mount_filesystem => 'devpts',
            linux_mount_options => 'mode=0620,gid=5',
            linux_mount_dumpfreq => '0',
            linux_mount_passnum => '0'
        },
        {
            linux_mount_device => 'tmpfs',
            linux_mount_point => '/dev/shm',
            linux_mount_filesystem => 'tmpfs',
            linux_mount_options => 'defaults',
            linux_mount_dumpfreq => '0',
            linux_mount_passnum => '0'
        },
        {
            linux_mount_device => 'proc',
            linux_mount_point => '/proc',
            linux_mount_filesystem => 'proc',
            linux_mount_options => 'defaults',
            linux_mount_dumpfreq => '0',
            linux_mount_passnum => '0'
        },
        {
            linux_mount_device => 'sysfs',
            linux_mount_point => '/sys',
            linux_mount_filesystem => 'sysfs',
            linux_mount_options => 'defaults',
            linux_mount_dumpfreq => '0',
            linux_mount_passnum => '0'
        },
    );

    foreach my $row (@default_conf) {
        Entity::Component::Linux::LinuxMount->new(linux_id => $self->id,
                                                  %$row);
    }
}

1;
