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
            foreach my $slave (@{ $iface->{slaves} }) {
                $template_file = 'ifcfg-bonded-slave.tt';
                my $file = $self->generateNodeFile(
                    cluster       => $args{cluster},
                    host          => $args{host},
                    file          => '/etc/sysconfig/network/ifcfg-' . $slave->iface_name,
                    template_dir  => '/templates/components/suse',
                    template_file => $template_file,
                    data          => { interface => ''}
                );
                $args{econtext}->send(
                    src  => $file,
                    dest => $args{mount_point} . '/etc/sysconfig/network/ifcfg-' . $slave->iface_name
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
            template_dir  => '/templates/components/suse',
            template_file => $template_file,
            data          => { interface => $iface }
        );

        $args{econtext}->send(
            src  => $file,
            dest => $args{mount_point} . '/etc/sysconfig/network/ifcfg-' . $iface->{name}
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
                    template_dir  => '/templates/components/suse',
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
    my $systemimage = $args{host}->getNodeSystemimage;
    my $ifaces = $args{host}->getIfaces;
    my $hostname = $args{host}->host_hostname;

    my $file = $self->_generateUdevPersistentNetRules(host => $args{host}, cluster => $args{cluster});
    my $cmd = 'cp '.$file->{src}.' '.$initrddir.$file->{dest};
    $econtext->execute(command => $cmd);

    # TODO check targetname is the same for each container access
    my $portals = [];
    my $target = "";
    for my $container_access ($systemimage->container_accesses) {
        push @$portals, { ip   => $container_access->container_access_ip,
                          port => $container_access->container_access_port };
        $target = $container_access->container_access_export;
    }

    $log->info("customize initramfs $initrddir");

    my $rootdev = $self->_initrd_iscsi(
                      initrd_dir    => $initrddir,
                      initiatorname => $args{host}->host_initiatorname,
                      target        => $target,
                      portals       => $portals
                  );

    # TODO: Check host harddisks for a harddisk_device called 'autodetect'
    my $host_params = $args{cluster}->getManagerParameters(manager_type => 'host_manager');
    if ($host_params->{deploy_on_disk}) {
        my $harddisk;
        eval {
            $harddisk = $args{host}->findRelated(filters  => [ 'harddisks' ],
                                                 order_by => 'harddisk_device');
        };
        if ($@) {
            throw Kanopya::Exception::Internal::NotFound(
                      error => "No hard disk to deploy the system on was found"
                  );
        }

        my $size = $harddisk->harddisk_size;
        my $device = '/dev/disk/by-path/ip-' . $portals->[0]->{ip} . ':' .
                     $portals->[0]->{port} . '-iscsi-' . $target . '-lun-0';

        $self->_initrd_deployment(initrd_dir  => $initrddir,
                                  src_device  => $device,
                                  dest_device => $harddisk->harddisk_device,
                                  root_size   => $size * 0.6 / 1024 / 1024 / 1024,
                                  swap_size   => $size * 0.4 / 1024 / 1024 / 1024);
    }
    else {
        # else remove deployement script
        $cmd = 'rm ' . $args{initrd_dir} . '/boot/83-deploy.sh';
        $econtext->execute(command => $cmd);
    }

    my @ifaces = $args{host}->getIfaces();
    $self->_initrd_config(initrd_dir => $initrddir,
                          ifaces     => \@ifaces,
                          hostname   => $args{host}->host_hostname,
                          rootdev    => $rootdev);
}

# build the open-iscsi part of the initrd

=pod

=begin classdoc

generate config variables for iscsi script in the initrd.
enable multipath script if several portals are provided

@param initrd_dir initrd working directory  
@param target device to duplicate to dest_device
@param portals device receiving src_device content
@param initiatorname size in gigabyte to use during root resizing

@return device containing root filesystem

=end classdoc

=cut

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
    
    # if you have only one portal, remove multipath capability and use iscsi dev instead of device mapper device
    my $rootdev = '/dev/dm-1';
    if(scalar(@portals) == 1) {
        $log->debug("removing multipath capability");
        $cmd = 'rm '.$args{initrd_dir}.'/boot/04-multipathd.sh '.$args{initrd_dir}.'/boot/21-multipath.sh';
        $econtext->execute(command => $cmd);
        $rootdev = '/dev/disk/by-path/ip-'.$portals[0]->{ip}.':'.$portals[0]->{port}.'-iscsi-'.$target.'-lun-0-part1';
    }
    return $rootdev;
}

=pod

=begin classdoc

desc

@param initrd_dir initrd working directory  
@param src_device device to duplicate to dest_device
@param dest_device device receiving src_device content
@param root_size size in gigabyte to use during root resizing
@param swap_size size in gigabyte to use during swap device creation

=end classdoc

=cut

sub _initrd_deployment {
    my ($self, %args) = @_;
    General::checkParams(args     =>\%args,
                         required => [ 'initrd_dir', 'src_device', 'dest_device',
                                       'root_size', 'swap_size' ]);

    $self->generateFile(
        mount_point  => $args{initrd_dir} . '/config',
        input_file   => 'deploy.sh.tt',
        template_dir => '/opt/kanopya/templates/internal/initrd/sles',
        output       => '/deploy.sh',
        data         => { deploy_src_dev   => $args{src_device},
                          deploy_dest_dev  => $args{dest_device},
                          deploy_root_size => $args{root_size},
                          deploy_swap_size => $args{swap_size} }
    );

    # TODO change hard coded root device (depend on master image partitioning)
    return '/dev/sda1';
}

=pod

=begin classdoc

generate config variables for deployment script in the initrd

@param initrd_dir initrd working directory  
@param ifaces array reference of Entity::Iface instances to configure static ip
@param hostname host hostname
@param rootdev device containing the final root filesystem

=end classdoc

=cut

sub _initrd_config {
    my ($self, %args) = @_;
    General::checkParams(args     =>\%args,
                         required => ['initrd_dir', 'ifaces', 'hostname', 'rootdev']);
                         
    $self->generateFile(mount_point => $args{initrd_dir}.'/config',
                        input_file  => 'storage.sh.tt',
                        template_dir => '/opt/kanopya/templates/internal/initrd/sles',
                        output      => '/storage.sh',
                        data        => { rootdev => $args{rootdev} }
                        );
    
    my @macaddresses = ();
    my @ips = ();
    my $hostname = $args{hostname};
    
    IFACE:
    for my $iface (@{$args{ifaces}}) {
        my $name = $iface->getAttr(name => 'iface_name');
        my $mac  = $iface->getAttr(name => 'iface_mac_addr');
        my $ip   =  eval { $iface->getIPAddr; };
        if ($@) {
          next IFACE;
        }
        my $netmask = $iface->getPoolip->network->network_netmask;
        my $gateway = $iface->getPoolip->network->network_gateway;
        push @macaddresses, "$name:$mac";
        push @ips, $ip.'::'.$gateway.':'.$netmask.':'.$hostname.':'.$name.':none';
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
                        data        => { rootdev => $args{rootdev},
                                         rootfsck => '/sbin/fsck.ext3' }
                       );
}

1;

