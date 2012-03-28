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

package Cisco::UCS::VLAN;
use base "Cisco::UCS::Object";

sub create {
    my $class = shift;
    my %args = @_;

    if (not defined ($args{dn})) {
        $args{dn} = "fabric/lan/net-" . $args{name};
    }

    my $ucs = $args{ucs};
    delete $args{ucs};

    return $ucs->create(classId => "fabricVlan",
                        %args)
}

                                
1;
