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
use Kanopya::Config;

use Log::Log4perl 'get_logger';
my $log = get_logger("");

sub configureNode {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'mount_point', 'host' ]);

    $log->info("Configuring system for iSCSI");
 
    # generation of /etc/iscsi/initiatorname.iscsi (needed to start the iscsid daemon)
    my $data = { initiatorname => $args{host}->host_initiatorname };
    my $file = $self->generateNodeFile(
        host          => $args{host},
        file          => '/etc/iscsi/initiatorname.iscsi',
        template_dir  => 'components/open-iscsi',
        template_file => 'initiatorname.iscsi.tt',
        data          => $data,
        mount_point   => $args{mount_point}
    );
    
    $self->_host->getEContext->execute(
        command => "touch $args{mount_point}/etc/iscsi.initramfs"
    );

    my $initiatorname = $args{host}->host_initiatorname;
    $self->_host->getEContext->execute(
        command => "echo \"InitiatorName=$initiatorname\" > " .
        "$args{mount_point}/etc/initiatorname.iscsi"
    );
}

1;
