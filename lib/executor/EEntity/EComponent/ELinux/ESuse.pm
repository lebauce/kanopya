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

package EEntity::EComponent::ELinux::ESuse;
use base 'EEntity::EComponent::ELinux';

use strict;
use warnings;
use Log::Log4perl 'get_logger';
use Data::Dumper;

my $log = get_logger("");
my $errmsg;

sub _writeNetConf {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'cluster', 'host', 'mount_point', 'ifaces', 'econtext' ]);

    for my $iface (@{ $args{ifaces} }) {
    
        my $template_file;
        if ($iface->{type} eq 'master') {
            $template_file = 'ifcfg-bonded-master.tt';
        }
        elsif ($iface->{type} eq 'slave') {
            $template_file = 'ifcfg-bonded-slave.tt';
        }
        else {
            $template_file = 'ifcfg.tt';
        }

        my $file = $self->generateNodeFile(
            cluster       => $args{cluster},
            host          => $args{host},
            file          => '/etc/sysconfig/network/ifcfg-' . $iface->{name},
            template_dir  => '/templates/components/suse',
            template_file => $template_file,
            data          => { interface => $iface }
        );

        $args{econtext}->send(
            src  => $file,
            dest => $args{mount_point} . '/etc/sysconfig/network/ifcfg-' . $iface->{name}
        );
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

sub customizeInitramfs {
    my ($self, %args) = @_;
    General::checkParams(args     =>\%args,
                         required => ['initrd_dir','cluster', 'host', 'mount_point']);
    
    my $econtext = $self->getExecutorEContext;



}

# build the open-iscsi part of the initrd

sub _initrd_iscsi {
    my ($self, %args) = @_;
    General::checkParams(args     =>\%args,
                         required => ['initrddir']);
    my $econtext = $self->getExecutorEContext;
    my $cmd;
    
    # generate send_targets and nodes info
    # TODO retrieve portals list
    # TODO retrieve targetname
    my $target = "iqn.blabalb";
    my @portals = ();
    
    for my $portal (@portals) {
        my $st_dir = $args{initrddir}.'/etc/iscsi/send_targets/'.$portal->{ip}.",".$portal->{port};
        $cmd = 'mkdir -p '.$st_dir;
        $econtext->execute(command => $cmd);
        
        my $target_dir = $args{initrddir}."/etc/iscsi/nodes/$target/".$portal->{ip}.",".$portal->{port}.',1';
        $cmd = 'mkdir -p '.$target_dir;
        $econtext->execute(command => $cmd);
        
        $self->generateFile(mount_point => $st_dir,
                            input_file  => 'st_config.tt',
                            template_dir => '/opt/kanopya/templates/internal/initrd/sles',
                            output      => '/st_config',
                            data        => { ip => $portal->{ip}, port => $portal->{port} }
                            );
        
        $self->generateFile(mount_point => $target_dir,
                            input_file  => 'default.tt',
                            template_dir => '/opt/kanopya/templates/internal/initrd/sles',
                            output      => '/default',
                            data        => { target => $target, ip => $portal->{ip}, port => $portal->{port} }
                            );
    }
}

sub _initrd_config {
    my ($self, %args) = @_;
    General::checkParams(args     =>\%args,
                         required => ['initrddir']);
                         
    $self->generateFile(mount_point => $args{initrddir}.'/config',
                        input_file  => 'storage.sh.tt',
                        template_dir => '/opt/kanopya/templates/internal/initrd/sles',
                        output      => '/storage.sh',
                        data        => { rootdev => '/dev/dm-0' }
                        );
                        
    # TODO retrieve static ips, static mac
    my $static_macaddress = "eth1:52:54:00:e9:62:58 eth0:52:54:00:77:fb:32";
    my $static_ips = "10.20.0.100:::255.255.255.0:10.10.0.100:eth1:none 10.10.0.100:::255.255.255.0:10.10.0.100:eth0:none";                    
                        
    $self->generateFile(mount_point => $args{initrddir}.'/config',
                    input_file  => 'network.sh.tt',
                    template_dir => '/opt/kanopya/templates/internal/initrd/sles',
                    output      => '/network.sh',
                    data        => { static_macaddress => $static_macaddress,
                                     static_ips =>  $static_ips }
                    );
    
    $self->generateFile(mount_point => $args{initrddir}.'/config',
                    input_file  => 'mount.sh.tt',
                    template_dir => '/opt/kanopya/templates/internal/initrd/sles',
                    output      => '/mount.sh',
                    data        => { rootdev => '/dev/dm-0',
                                     rootfsck => '/sbin/fsck.ext3' }
                    );

    
    
}

1;

