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
use base 'EEntity::EComponent';

use strict;
use warnings;
use General;

sub addNode {
    my ($self, %args) = @_;
    
    General::checkParams(args => \%args, required => ['mount_point', 'host']);
 
    # generation of /etc/iscsi/initiatorname.iscsi (needed to start the iscsid daemon)
    my $cluster = $self->_getEntity->getServiceProvider;
    my $data = { initiatorname => $args{host}->getAttr(name => 'host_initiatorname')};
    
    my $file = $self->generateNodeFile(
        cluster       => $cluster,
        host          => $args{host},
        file          => '/etc/iscsi/initiatorname.iscsi',
        template_dir  => '/templates/components/open-iscsi',
        template_file => 'initiatorname.iscsi.tt',
        data          => $data
    );
    
    $self->getExecutorEContext->send(
        src  => $file,
        dest => $args{mount_point}.'/etc/iscsi',
    );
    
    # TODO move internal/Kanopya_omitted_iscsid template generation here
}

1;
