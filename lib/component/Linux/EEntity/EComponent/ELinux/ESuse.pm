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

=pod

=begin classdoc

TODO

=end classdoc

=cut

package EEntity::EComponent::ELinux::ESuse;
use base 'EEntity::EComponent::ELinux';

use strict;
use warnings;
use Log::Log4perl 'get_logger';
use Data::Dumper;

my $log = get_logger("");
my $errmsg;

sub _generateHostname {
    my ($self, %args) = @_;

    $self->SUPER::_generateHostname(%args, path => "/etc/HOSTNAME");
}

sub _writeNetConf {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'cluster', 'host', 'mount_point', 'ifaces', 'econtext' ]);

    for my $iface (@{ $args{ifaces} }) {

        my $template_file;

        if ($iface->{type} eq 'master') {
            foreach my $slave (@{ $iface->{slaves} }) {
                $template_file = 'ifcfg-bonded-slave.tt';
                my $file = $self->generateNodeFile(
                    cluster       => $args{cluster},
                    host          => $args{host},
                    file          => '/etc/sysconfig/network/ifcfg-' . $slave->iface_name,
                    template_dir  => 'components/suse',
                    template_file => $template_file,
                    data          => { interface => ''},
                    mount_point   => $args{mount_point}
                );
            }
            $template_file = 'ifcfg-bonded-master.tt';
        }
        else {
            $template_file = 'ifcfg.tt';
        }

        my $file = $self->generateNodeFile(
            cluster       => $args{cluster},
            host          => $args{host},
            file          => '/etc/sysconfig/network/ifcfg-' . $iface->{name},
            template_dir  => 'components/suse',
            template_file => $template_file,
            data          => { interface => $iface },
            mount_point   => $args{mount_point}
        );

        if ($iface->{vlans}) {
            $template_file = 'ifcfg-vlan.tt';
            foreach my $vlan (@{ $iface->{vlans} }) {
                my %vlan_infos;
                my $vlan_id = 'vlan' . $vlan->vlan_number;
                $vlan_infos{iface_name} = $iface->{name};

                my $file = $self->generateNodeFile(
                    cluster       => $args{cluster},
                    host          => $args{host},
                    file          => '/etc/sysconfig/network/ifcfg-' . $vlan_id,
                    template_dir  => 'components/suse',
                    template_file => $template_file,
                    data          => { interface => \%vlan_infos },
                    mount_point   => $args{mount_point}
                );
            }
        }
    }
}

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

1;
