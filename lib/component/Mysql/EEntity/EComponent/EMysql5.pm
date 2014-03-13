#    Copyright © 2011 Hedera Technology SAS
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
package EEntity::EComponent::EMysql5;
use base "EEntity::EComponent";

use strict;

sub isUp {
    my ($self, %args) = @_;

    General::checkParams( args => \%args, required => [ 'cluster', 'host' ] );
    my $result = $self->SUPER::isUp(%args);
    if($result) {
        my $cmd = "mysqladmin flush-hosts";
        $args{host}->getEContext->execute(command => $cmd);
    }
}

1;
