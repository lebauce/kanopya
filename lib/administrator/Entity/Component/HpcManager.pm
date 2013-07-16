# copyright © 2013 hedera technology sas
#
# this program is free software: you can redistribute it and/or modify
# it under the terms of the gnu affero general public license as
# published by the free software foundation, either version 3 of the
# license, or (at your option) any later version.
#
# this program is distributed in the hope that it will be useful,
# but without any warranty; without even the implied warranty of
# merchantability or fitness for a particular purpose.  see the
# gnu affero general public license for more details.
#
# you should have received a copy of the gnu affero general public license
# along with this program.  if not, see <http://www.gnu.org/licenses/>.

package Entity::Component::HpcManager;
use base "Entity::Component";
use base "Manager::HostManager";

use warnings;

use constant ATTR_DEF => {
    host_type => {
        is_virtual => 1
    }
};

sub getAttrDef { return ATTR_DEF; }

$DB::single = 1;

1;
