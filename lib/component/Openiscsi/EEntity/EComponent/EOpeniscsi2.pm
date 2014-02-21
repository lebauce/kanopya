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

sub addNode {
    my ($self, %args) = @_;
    
    General::checkParams(args => \%args, required => ['mount_point', 'host', 'container_access']);

    $log->info("Configuring system for iSCSI");
 
    # generation of /etc/iscsi/initiatorname.iscsi (needed to start the iscsid daemon)
    my $cluster = $self->service_provider;
    my $data = { initiatorname => $args{host}->host_initiatorname };
    
    my $file = $self->generateNodeFile(
        cluster       => $cluster,
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

sub _generateKanopyaHalt {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "cluster", "host", "mount_point", "targetname", "container_access" ]);

    my $vars = {
        target       => $args{targetname},
        nas_ip       => $args{container_access}->container_access_ip,
        nas_port     => $args{container_access}->container_access_port,
        data_exports => $self->getConf()->{openiscsi2_targets}
    };

    my $file = $self->generateNodeFile(
        cluster       => $args{cluster},
        host          => $args{host},
        file          => '/etc/init.d/Kanopya_halt',
        template_dir  => 'components/open-iscsi',
        template_file => 'KanopyaHalt.tt',
        data          => $vars,
        mode          => 755,
        mount_point   => $args{mount_point}
    );

    $self->_host->getEContext->send(
        src  => Kanopya::Config::getKanopyaDir() . '/templates/internal/Kanopya_omitted_iscsid',
        dest => "$args{mount_point}/etc/init.d/Kanopya_omitted_iscsid",
        mode => 755
    );
}

1;
