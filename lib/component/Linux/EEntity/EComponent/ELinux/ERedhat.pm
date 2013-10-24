#    Copyright © 2012 Hedera Technology SAS
#
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

package EEntity::EComponent::ELinux::ERedhat;
use base 'EEntity::EComponent::ELinux';

use strict;
use warnings;
use Log::Log4perl 'get_logger';
use Data::Dumper;

use Kanopya::Config;

my $log = get_logger("");
my $errmsg;

sub service {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'services', 'mount_point' ]);

    for my $service (@{$args{services}}) {
        if (defined $args{command}) {
            system("chroot $args{mount_point} service " . $service . " " . $args{command});
        }
        if (defined $args{state}) {
            system("chroot $args{mount_point} chkconfig " . $service . " " . $args{state});
        }
    }
}

sub customizeInitramfs {
    my ($self, %args) = @_;

    General::checkParams(args     =>\%args,
                         required => [ 'initrd_dir', 'cluster', 'host' ]);

    $self->SUPER::customizeInitramfs(%args);

    my $kanopya_dir = Kanopya::Config::getKanopyaDir();
    my $cmd = "cp -R $kanopya_dir/tools/deployment/system/initramfs-tools/scripts/* " . $args{initrd_dir} . "/scripts";
    $self->_host->getEContext->execute(command => $cmd);
}

sub _writeNetConf {
    my ($self, %args) = @_;

    General::checkParams(
        args     => \%args,
        required => [ 'cluster', 'host', 'mount_point', 'ifaces', 'econtext' ]
    );

    for my $iface (@{ $args{ifaces} }) {
        my $file = $self->generateNodeFile(
            cluster       => $args{cluster},
            host          => $args{host},
            file          => '/etc/sysconfig/network-scripts/ifcfg-' . $iface->{name},
            template_dir  => '/templates/components/redhat',
            template_file => 'ifcfg.tt',
            data          => { interface => $iface }
        );

        $args{econtext}->send(
            src  => $file,
            dest => $args{mount_point} . '/etc/sysconfig/network-scripts/ifcfg-' . $iface->{name}
        );

        $file = $self->generateNodeFile(
            cluster       => $args{cluster},
            host          => $args{host},
            file          => '/etc/sysconfig/network',
            template_dir  => 'redhat',
            template_file => 'network.tt',
            data          => { hostname => $args{host}->node->node_hostname }
        );

        $args{econtext}->send(
            src  => $file,
            dest => $args{mount_point} . '/etc/sysconfig/network'
        );

        if ($iface->{vlans}) {
            my $template_file = 'ifcfg-vlan.tt';
            foreach my $vlan (@{ $iface->{vlans} }) {
                my %vlan_infos;
                my $vlan_id = 'vlan' . $vlan->vlan_number;
                $vlan_infos{iface_name} = $iface->{name};

                my $file = $self->generateNodeFile(
                    cluster       => $args{cluster},
                    host          => $args{host},
                    file          => '/etc/sysconfig/network/ifcfg-' . $vlan_id,
                    template_dir  => '/templates/components/redhat',
                    template_file => $template_file,
                    data          => { interface => \%vlan_infos }
                );

                $args{econtext}->send(
                    src  => $file,
                    dest => $args{mount_point} . '/etc/sysconfig/network/ifcfg-' . $vlan_id
                );
            }
        }
    }
}

1;

