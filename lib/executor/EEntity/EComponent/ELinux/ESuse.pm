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

sub buildInitramfs {
    my ($self, %args) = @_;
    General::checkParams(args     =>\%args,
                         required => ['cluster', 'host', 'mount_point']);
    
    my $econtext = $self->getExecutorEContext;
    
    my $cluster_kernel_id = $args{cluster}->kernel_id;
    my $kernel_id = $cluster_kernel_id ? $cluster_kernel_id : $args{host}->kernel_id;

    my $clustername = $args{cluster}->cluster_name;
    my $hostname = $args{host}->host_hostname;

    my $kernel_version = Entity::Kernel->get(id => $kernel_id)->kernel_version;

    my $tftpdir = $self->{config}->{tftp}->{directory};

    ## Here we create a dedicated initramfs for the node
    # we create a temporary working directory for the initrd

    $log->info('Build dedicated initramfs');
    my $initrddir = "/tmp/$clustername-$hostname";
    my $cmd = "mkdir -p $initrddir";
    $econtext->execute(command => $cmd);

    # check and retrieve compression type
    my $initrd = "$tftpdir/initrd_$kernel_version";
    $cmd = "file $initrd | grep -o -E '(gzip|bzip2)'";
    my $result = $econtext->execute(command => $cmd);
    my $decompress;
    chomp($result->{stdout});
    if($result->{stdout} eq 'gzip') {
        $decompress = 'zcat';
    } elsif($result->{stdout} eq 'bzip2') {
        $decompress = 'bzcat';
    } else {
        throw Kanopya::Exception::Internal(
            error => "Invalid compress type for $initrd ; must be gzip or bzip2"
        );
    }

    # we decompress and extract the original initrd to this directory
    $cmd = "(cd $initrddir && $decompress $initrd | cpio -i)";
    $econtext->execute(command => $cmd);

    # append files to the archive directory
    my $sourcefile = $args{mount_point}.'/etc/udev/rules.d/70-persistent-net.rules';
    $cmd = "(cd $initrddir && mkdir -p etc/udev/rules.d && cp $sourcefile etc/udev/rules.d)";
    $econtext->execute(command => $cmd);

    # create the final storing directory
    my $path = "$tftpdir/$clustername/$hostname";
    $cmd = "mkdir -p $path";
    $econtext->execute(command => $cmd);

    # rebuild and compress the new initrd
    my $newinitrd = $path."/initrd_$kernel_version";
    $cmd = "(cd $initrddir && find . | cpio -H newc -o | bzip2 > $newinitrd)";
    $econtext->execute(command => $cmd);

    # finaly we remove the temporary directory
    $cmd = "rm -r $initrddir";
    $econtext->execute(command => $cmd);
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

