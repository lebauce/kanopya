#    Copyright 2012 Hedera Technology SAS
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

package Cisco::UCS::Ethernet;
use base "Cisco::UCS::Object";

use warnings;
use strict;

sub applyVLAN {
    my $self = shift;
    my %args = @_;

    if (not defined $self->{vnicEtherIf}) {
        $self->{vnicEtherIf} = [];
    }

    push @{$self->{vnicEtherIf}}, {
        defaultNet        => "no",
        name              => $args{name},
        rn                => "if-" . $args{name}
    };

    $self->update();
}

1;
