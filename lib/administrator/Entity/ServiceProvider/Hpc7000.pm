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

package Entity::ServiceProvider::Hpc7000;
use base 'Entity::ServiceProvider';

use strict;
use warnings;

use constant ATTR_DEF => {
};

sub getAttrDef { return ATTR_DEF; }

sub method {
    return {
        synchronize => {
            description => 'synchronize Kanopya with the HPC device.'
        }
    };
}

sub synchronize {
    my $self   = shift;
    my $hpcmgr = $self->getComponent(name => 'HpcManager');

    $hpcmgr->synchronize();
}

1;
