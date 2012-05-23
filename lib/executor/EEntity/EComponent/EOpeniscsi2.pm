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
package EEntity::EComponent::EOpeniscsi2;
use base "EEntity::EComponent";

use strict;
use General;

sub addNode {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['mount_point', 'host']);
 
    $args{mount_point} .= '/etc';

    # generation of /etc/iscsi/initiatorname.iscsi (needed to start the iscsid daemon)
    my $data = { initiatorname => $args{host}->getAttr(name => 'host_initiatorname')};
    $self->generateFile(mount_point  => $args{mount_point},
                        template_dir => "/templates/components/open-iscsi",
                        input_file   => "initiatorname.iscsi.tt",
                        output       => '/iscsi/initiatorname.iscsi',
                        data         => $data);
    
    # TODO move internal/Kanopya_omitted_iscsid template generation here
}

1;
