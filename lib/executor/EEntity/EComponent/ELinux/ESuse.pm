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
                         required => ['initrd_dir','cluster', 'host']);
    
    my $econtext = $self->getExecutorEContext;
    my $initrddir = $args{initrd_dir};

    $log->info("customize initramfs $initrddir");

    # TODO recup target et portals
    my $target = 'iqn.blmablabla';
    my $portals = [ { ip => '1.1.1.1', port => 3260 },
                    { ip => '2.2.2.2', port => 3260 }, ];    
    
    $self->_initrd_iscsi(initrd_dir    => $initrddir,
                         initiatorname => $args{host}->host_initiatorname,
                         target        => $target,
                         portals       => $portals);

    my @ifaces = $args{host}->getIfaces();
    $self->_initrd_config(initrd_dir => $initrddir,
                          ifaces     => \@ifaces,
                          hostname   => $args{host}->host_hostname);
}

# build the open-iscsi part of the initrd

sub _initrd_iscsi {
    my ($self, %args) = @_;
    General::checkParams(args     =>\%args,
                         required => ['initrd_dir','target', 'portals', 'initiatorname']);
    my $econtext = $self->getExecutorEContext;
    my $cmd;
    
    # generate send_targets and nodes info

    my $target = $args{target};
    my @portals = @{$args{portals}};
    
    for my $portal (@portals) {
        my $st_dir = $args{initrd_dir}.'/etc/iscsi/send_targets/'.$portal->{ip}.",".$portal->{port};
        $cmd = 'mkdir -p '.$st_dir;
        $econtext->execute(command => $cmd);
        
        my $target_dir = $args{initrd_dir}."/etc/iscsi/nodes/$target/".$portal->{ip}.",".$portal->{port}.',1';
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
                            
        $cmd = "echo InitiatorName=$args{initiatorname} > $args{initrd_dir}/etc/iscsi/initiatorname.iscsi";
        $econtext->execute(command => $cmd);
    }
}

sub _initrd_config {
    my ($self, %args) = @_;
    General::checkParams(args     =>\%args,
                         required => ['initrd_dir', 'ifaces', 'hostname']);
                         
    $self->generateFile(mount_point => $args{initrd_dir}.'/config',
                        input_file  => 'storage.sh.tt',
                        template_dir => '/opt/kanopya/templates/internal/initrd/sles',
                        output      => '/storage.sh',
                        data        => { rootdev => '/dev/dm-0' }
                        );
    
    my @macaddresses = ();
    my @ips = ();
    my $hostname = $args{hostname};
    
    for my $iface (@{$args{ifaces}}) {
        my $name = $iface->getAttr(name => 'iface_name');
        my $mac  = $iface->getAttr(name => 'iface_mac_addr');
        my $ip   = $iface->getIPAddr;
        my $netmask = $iface->getPoolip->network->network_netmask;
        my $gateway = $iface->getPoolip->network->network_gateway;
        push @macaddresses, "$name:$mac";
        push @ips, "$ip::$gateway:$netmask:$hostname:$name:none";
    }
                        
    my $static_macaddress = join(' ', @macaddresses);
    my $static_ips = join(' ', @ips);
                        
    $self->generateFile(mount_point => $args{initrd_dir}.'/config',
                        input_file  => 'network.sh.tt',
                        template_dir => '/opt/kanopya/templates/internal/initrd/sles',
                        output      => '/network.sh',
                        data        => { static_macaddress => $static_macaddress,
                                         static_ips =>  $static_ips }
                       );
    
    $self->generateFile(mount_point => $args{initrd_dir}.'/config',
                        input_file  => 'mount.sh.tt',
                        template_dir => '/opt/kanopya/templates/internal/initrd/sles',
                        output      => '/mount.sh',
                        data        => { rootdev => '/dev/dm-0',
                                         rootfsck => '/sbin/fsck.ext3' }
                       );
}

1;

