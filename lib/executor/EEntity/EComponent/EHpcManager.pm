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

package EEntity::EComponent::EHpcManager;
use base "EEntity::EComponent";
use base "EManager::EHostManager";

use strict;
use warnings;

=head2 get_blades

    Desc: retrieve informations about the HPC blades

=cut

sub get_blades {
    my $self = shift;
}

=head2 synchronize

    Desc: synchronize hpc7000 information with kanopya database

=cut

sub synchronize {
    my $self = shift;
    my %args = @_;

    my @blades = $self->get_blades();

    foreach my $blade (@blades) {
    }
}

1;
