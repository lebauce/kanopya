#    Copyright © 2011 Hedera Technology SAS
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

=pod

=begin classdoc

Concrete class for iscsi container accesses. Iscsi container accesses are disk exports provided
by components that use the Iscsi protocol to give access to remote disks. It extends base 
container by specifying usual configuration for Iscsi exports.

@since    2012-Feb-23
@instance hash
@self     $self

=end classdoc

=cut

package Entity::ContainerAccess::IscsiContainerAccess;
use base "Entity::ContainerAccess";

use strict;
use warnings;

use constant ATTR_DEF => {
    iomode => {
        pattern         => '^.*$',
        is_mandatory    => 1,
        is_extended     => 0,
        description     => 'iSCSI export I/O mode (read only, writeback, ...)',
    },
    typeio => {
        pattern         => '^.*$',
        is_mandatory    => 1,
        is_extended     => 0,
        description     => 'Type of the exported disk (diskio, fileio depending on whether it is a disk or a file)',
    },
    lun_name => {
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_extended     => 0,
        description     => 'This LUN name will be concatenated to the IQN',
    }
};

sub getAttrDef { return ATTR_DEF; }

1;
